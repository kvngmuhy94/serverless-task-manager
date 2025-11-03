#!/bin/bash

echo "🚀 Setting up CloudFront Distribution for Serverless Task Manager"
echo "=================================================="

# Variables
BUCKET_NAME="serverless-task-managerfrontend"
DISTRIBUTION_CONFIG_FILE="/tmp/cloudfront-distribution-config.json"
CALLER_REF="serverless-task-manager-$(date +%s)"

echo "📋 Checking AWS permissions..."
aws sts get-caller-identity

echo "📦 Checking if bucket exists and is accessible..."
aws s3 ls s3://$BUCKET_NAME --summarize

echo "🌐 Creating CloudFront distribution configuration..."
cat > $DISTRIBUTION_CONFIG_FILE << EOF
{
  "CallerReference": "$CALLER_REF",
  "Comment": "CloudFront distribution for Serverless Task Manager React App",
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
  "PriceClass": "PriceClass_100"
}
EOF

echo "🔐 Attempting to create CloudFront distribution..."
if aws cloudfront create-distribution --distribution-config file://$DISTRIBUTION_CONFIG_FILE > /tmp/cloudfront-result.json 2>/tmp/cloudfront-error.log; then
    echo "✅ CloudFront distribution created successfully!"
    
    # Extract distribution ID and domain name
    DISTRIBUTION_ID=$(jq -r '.Distribution.Id' /tmp/cloudfront-result.json)
    DOMAIN_NAME=$(jq -r '.Distribution.DomainName' /tmp/cloudfront-result.json)
    
    echo "📋 Distribution Details:"
    echo "   ID: $DISTRIBUTION_ID"
    echo "   Domain: $DOMAIN_NAME"
    echo "   Status: $(jq -r '.Distribution.Status' /tmp/cloudfront-result.json)"
    
    echo ""
    echo "🌐 Your HTTPS URLs:"
    echo "   Primary: https://$DOMAIN_NAME"
    echo "   S3 Direct: http://$BUCKET_NAME.s3-website-us-east-1.amazonaws.com"
    
    echo ""
    echo "⏳ Note: CloudFront deployment takes 15-20 minutes to complete globally."
    echo "   You can check status with: aws cloudfront get-distribution --id $DISTRIBUTION_ID"
    
else
    echo "❌ Failed to create CloudFront distribution"
    echo "Error details:"
    cat /tmp/cloudfront-error.log
    
    echo ""
    echo "🔧 Possible solutions:"
    echo "1. Check IAM permissions for CloudFront"
    echo "2. Verify AWS CLI configuration"
    echo "3. Try creating via AWS Console manually"
    
    exit 1
fi