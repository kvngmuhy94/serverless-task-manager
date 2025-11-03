#!/bin/bash

# Custom Domain Setup Script for Serverless Task Manager
# Usage: ./setup-custom-domain.sh yourdomain.com

set -e

DOMAIN_NAME="$1"
BUCKET_NAME="serverless-task-managerfrontend"
REGION="us-east-1"

if [ -z "$DOMAIN_NAME" ]; then
    echo "❌ Error: Please provide a domain name"
    echo "Usage: $0 yourdomain.com"
    exit 1
fi

echo "🌐 Setting up custom domain: $DOMAIN_NAME"
echo "================================================"

# Validate domain format
if [[ ! "$DOMAIN_NAME" =~ ^[a-zA-Z0-9][a-zA-Z0-9-]{1,61}[a-zA-Z0-9]\.[a-zA-Z]{2,}$ ]]; then
    echo "❌ Error: Invalid domain name format"
    exit 1
fi

echo "📋 Step 1: Checking AWS credentials..."
aws sts get-caller-identity || { echo "❌ AWS credentials not configured"; exit 1; }

echo ""
echo "📋 Step 2: Checking if domain has existing certificate..."
CERT_ARN=$(aws acm list-certificates --region us-east-1 --query "CertificateSummaryList[?DomainName=='$DOMAIN_NAME'].CertificateArn" --output text 2>/dev/null || echo "")

if [ -z "$CERT_ARN" ]; then
    echo "🔐 Step 3: Requesting SSL certificate for $DOMAIN_NAME..."
    
    CERT_REQUEST=$(aws acm request-certificate \
        --domain-name "$DOMAIN_NAME" \
        --subject-alternative-names "www.$DOMAIN_NAME" \
        --validation-method DNS \
        --region us-east-1 \
        --output json)
    
    CERT_ARN=$(echo "$CERT_REQUEST" | jq -r '.CertificateArn')
    
    echo "✅ Certificate requested: $CERT_ARN"
    echo ""
    echo "🔍 Step 4: Getting DNS validation records..."
    
    # Wait a moment for certificate details to be available
    sleep 5
    
    aws acm describe-certificate \
        --certificate-arn "$CERT_ARN" \
        --region us-east-1 \
        --query 'Certificate.DomainValidationOptions[].ResourceRecord' \
        --output table
    
    echo ""
    echo "⚠️  IMPORTANT: Add the above DNS records to your domain provider"
    echo "   This is required to validate domain ownership"
    echo ""
    echo "📋 Waiting for certificate validation..."
    echo "   This can take 5-30 minutes depending on your DNS provider"
    
    # Check validation status
    while true; do
        STATUS=$(aws acm describe-certificate \
            --certificate-arn "$CERT_ARN" \
            --region us-east-1 \
            --query 'Certificate.Status' \
            --output text)
        
        if [ "$STATUS" = "ISSUED" ]; then
            echo "✅ Certificate validated successfully!"
            break
        elif [ "$STATUS" = "FAILED" ]; then
            echo "❌ Certificate validation failed"
            exit 1
        else
            echo "⏳ Certificate status: $STATUS (checking again in 30 seconds...)"
            sleep 30
        fi
    done
else
    echo "✅ Found existing certificate: $CERT_ARN"
fi

echo ""
echo "🌐 Step 5: Creating CloudFront distribution with custom domain..."

# Create CloudFront distribution config
CALLER_REF="custom-domain-$(date +%s)"
CONFIG_FILE="/tmp/cloudfront-custom-domain-config.json"

cat > "$CONFIG_FILE" << EOF
{
  "CallerReference": "$CALLER_REF",
  "Aliases": {
    "Quantity": 2,
    "Items": ["$DOMAIN_NAME", "www.$DOMAIN_NAME"]
  },
  "Comment": "Serverless Task Manager - Custom Domain: $DOMAIN_NAME",
  "DefaultRootObject": "index.html",
  "Enabled": true,
  "Origins": {
    "Quantity": 1,
    "Items": [
      {
        "Id": "S3-Origin",
        "DomainName": "$BUCKET_NAME.s3-website-us-east-1.amazonaws.com",
        "CustomOriginConfig": {
          "HTTPPort": 80,
          "HTTPSPort": 443,
          "OriginProtocolPolicy": "http-only",
          "OriginSslProtocols": {
            "Quantity": 1,
            "Items": ["TLSv1.2"]
          }
        }
      }
    ]
  },
  "DefaultCacheBehavior": {
    "TargetOriginId": "S3-Origin",
    "ViewerProtocolPolicy": "redirect-to-https",
    "AllowedMethods": {
      "Quantity": 2,
      "Items": ["GET", "HEAD"],
      "CachedMethods": {
        "Quantity": 2,
        "Items": ["GET", "HEAD"]
      }
    },
    "ForwardedValues": {
      "QueryString": false,
      "Cookies": {
        "Forward": "none"
      }
    },
    "TrustedSigners": {
      "Enabled": false,
      "Quantity": 0
    },
    "MinTTL": 0,
    "DefaultTTL": 86400,
    "MaxTTL": 31536000,
    "Compress": true
  },
  "CustomErrorResponses": {
    "Quantity": 2,
    "Items": [
      {
        "ErrorCode": 404,
        "ResponsePagePath": "/index.html",
        "ResponseCode": "200",
        "ErrorCachingMinTTL": 300
      },
      {
        "ErrorCode": 403,
        "ResponsePagePath": "/index.html",
        "ResponseCode": "200",
        "ErrorCachingMinTTL": 300
      }
    ]
  },
  "ViewerCertificate": {
    "ACMCertificateArn": "$CERT_ARN",
    "SSLSupportMethod": "sni-only",
    "MinimumProtocolVersion": "TLSv1.2_2021"
  },
  "PriceClass": "PriceClass_100"
}
EOF

# Create the distribution
if DISTRIBUTION_RESULT=$(aws cloudfront create-distribution --distribution-config file://"$CONFIG_FILE" 2>/tmp/cloudfront-error.log); then
    
    DISTRIBUTION_ID=$(echo "$DISTRIBUTION_RESULT" | jq -r '.Distribution.Id')
    CLOUDFRONT_DOMAIN=$(echo "$DISTRIBUTION_RESULT" | jq -r '.Distribution.DomainName')
    
    echo "✅ CloudFront distribution created successfully!"
    echo ""
    echo "📋 Distribution Details:"
    echo "   ID: $DISTRIBUTION_ID"
    echo "   CloudFront Domain: $CLOUDFRONT_DOMAIN"
    echo "   Custom Domains: $DOMAIN_NAME, www.$DOMAIN_NAME"
    echo ""
    echo "🔧 Final Step: Update your DNS settings"
    echo "   Add these records to your DNS provider:"
    echo ""
    echo "   Type: CNAME"
    echo "   Name: www"
    echo "   Value: $CLOUDFRONT_DOMAIN"
    echo "   TTL: 300"
    echo ""
    echo "   Type: CNAME (or A record with alias)"
    echo "   Name: @ (root domain)"
    echo "   Value: $CLOUDFRONT_DOMAIN"
    echo "   TTL: 300"
    echo ""
    echo "⏳ Deployment Status:"
    echo "   CloudFront: 15-20 minutes to deploy globally"
    echo "   DNS Propagation: 5 minutes to 24 hours"
    echo ""
    echo "🌐 Your URLs after DNS propagation:"
    echo "   Primary: https://$DOMAIN_NAME"
    echo "   WWW: https://www.$DOMAIN_NAME"
    echo "   CloudFront Direct: https://$CLOUDFRONT_DOMAIN"
    
else
    echo "❌ Failed to create CloudFront distribution"
    echo "Error details:"
    cat /tmp/cloudfront-error.log
    exit 1
fi

# Cleanup
rm -f "$CONFIG_FILE" /tmp/cloudfront-error.log

echo ""
echo "🎉 Custom domain setup initiated successfully!"
echo "   Check status: aws cloudfront get-distribution --id $DISTRIBUTION_ID"