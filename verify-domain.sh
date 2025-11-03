#!/bin/bash

# DNS Verification Script for Custom Domain Setup
# Usage: ./verify-domain.sh yourdomain.com

DOMAIN_NAME="$1"

if [ -z "$DOMAIN_NAME" ]; then
    echo "🔍 DNS Verification Tool"
    echo "======================="
    echo ""
    echo "Usage: $0 yourdomain.com"
    echo ""
    echo "This tool helps verify:"
    echo "- Domain DNS configuration"
    echo "- SSL certificate status"
    echo "- CloudFront distribution status"
    exit 1
fi

echo "🔍 Verifying domain setup: $DOMAIN_NAME"
echo "========================================"

echo ""
echo "📋 1. Checking DNS resolution..."
echo "Root domain ($DOMAIN_NAME):"
dig +short "$DOMAIN_NAME" || echo "❌ No DNS records found"

echo ""
echo "WWW subdomain (www.$DOMAIN_NAME):"
dig +short "www.$DOMAIN_NAME" || echo "❌ No DNS records found"

echo ""
echo "📋 2. Checking SSL certificate status..."
CERT_ARN=$(aws acm list-certificates --region us-east-1 \
    --query "CertificateSummaryList[?DomainName=='$DOMAIN_NAME'].CertificateArn" \
    --output text 2>/dev/null)

if [ -n "$CERT_ARN" ]; then
    echo "✅ Certificate found: $CERT_ARN"
    
    STATUS=$(aws acm describe-certificate \
        --certificate-arn "$CERT_ARN" \
        --region us-east-1 \
        --query 'Certificate.Status' \
        --output text)
    
    echo "   Status: $STATUS"
    
    if [ "$STATUS" = "ISSUED" ]; then
        echo "✅ Certificate is valid and issued"
    elif [ "$STATUS" = "PENDING_VALIDATION" ]; then
        echo "⏳ Certificate is pending validation"
        echo ""
        echo "📋 Required DNS records for validation:"
        aws acm describe-certificate \
            --certificate-arn "$CERT_ARN" \
            --region us-east-1 \
            --query 'Certificate.DomainValidationOptions[].ResourceRecord' \
            --output table
    else
        echo "⚠️  Certificate status: $STATUS"
    fi
else
    echo "❌ No SSL certificate found for this domain"
fi

echo ""
echo "📋 3. Checking CloudFront distributions..."
DISTRIBUTIONS=$(aws cloudfront list-distributions \
    --query "DistributionList.Items[?Aliases.Items && contains(Aliases.Items, '$DOMAIN_NAME')].{Id:Id,Domain:DomainName,Status:Status}" \
    --output table 2>/dev/null)

if [ -n "$DISTRIBUTIONS" ]; then
    echo "✅ CloudFront distributions found:"
    echo "$DISTRIBUTIONS"
else
    echo "❌ No CloudFront distributions found for this domain"
fi

echo ""
echo "📋 4. Testing HTTPS connectivity..."
echo "Testing https://$DOMAIN_NAME..."
if curl -I -s "https://$DOMAIN_NAME" --connect-timeout 10 >/dev/null 2>&1; then
    echo "✅ HTTPS connection successful"
    
    echo ""
    echo "📊 Response details:"
    curl -I -s "https://$DOMAIN_NAME" --connect-timeout 10 | head -5
else
    echo "❌ HTTPS connection failed"
    
    echo ""
    echo "🔍 Troubleshooting steps:"
    echo "1. Verify DNS records are correct"
    echo "2. Wait for DNS propagation (can take up to 24 hours)"
    echo "3. Check CloudFront distribution status"
    echo "4. Verify SSL certificate is issued"
fi

echo ""
echo "📋 Current status summary:"
echo "========================="
echo "Domain: $DOMAIN_NAME"
echo "DNS: $(dig +short "$DOMAIN_NAME" | head -1 | grep -q . && echo "✅ Configured" || echo "❌ Not configured")"
echo "SSL: $([ -n "$CERT_ARN" ] && echo "✅ Certificate exists" || echo "❌ No certificate")"
echo "CloudFront: $([ -n "$DISTRIBUTIONS" ] && echo "✅ Distribution exists" || echo "❌ No distribution")"
echo "HTTPS: $(curl -I -s "https://$DOMAIN_NAME" --connect-timeout 5 >/dev/null 2>&1 && echo "✅ Working" || echo "❌ Not working")"