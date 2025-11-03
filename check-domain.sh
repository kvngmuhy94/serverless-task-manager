#!/bin/bash

# Domain Checker for Serverless Task Manager
# Usage: ./check-domain.sh yourdomain.com

DOMAIN_NAME="$1"

if [ -z "$DOMAIN_NAME" ]; then
    echo "🔍 Domain Checker for Serverless Task Manager"
    echo "============================================="
    echo ""
    echo "Usage: $0 yourdomain.com"
    echo ""
    echo "Examples:"
    echo "  $0 mytaskmanager.com"
    echo "  $0 taskmanager.app"
    echo "  $0 myproject.dev"
    echo ""
    echo "💡 Popular domain extensions:"
    echo "   .com - Most popular, best for business"
    echo "   .app - Perfect for applications"
    echo "   .dev - Great for developer projects"
    echo "   .io - Popular with tech startups"
    echo "   .tech - Technology-focused"
    echo ""
    exit 1
fi

echo "🔍 Checking domain: $DOMAIN_NAME"
echo "================================="

# Check if domain is available via Route53
echo "📋 Checking availability..."
if aws route53domains check-domain-availability --domain-name "$DOMAIN_NAME" &>/dev/null; then
    
    AVAILABILITY=$(aws route53domains check-domain-availability \
        --domain-name "$DOMAIN_NAME" \
        --query 'Availability' --output text)
    
    if [ "$AVAILABILITY" = "AVAILABLE" ]; then
        echo "✅ Domain is AVAILABLE for registration!"
        
        echo ""
        echo "💰 Pricing information:"
        aws route53domains get-domain-detail --domain-name "$DOMAIN_NAME" \
            --query 'RegistryDomainId' --output text &>/dev/null || \
        aws route53domains list-prices \
            --tld "${DOMAIN_NAME##*.}" \
            --query 'Prices[0]' --output table 2>/dev/null || \
            echo "   Pricing not available via API"
        
    elif [ "$AVAILABILITY" = "UNAVAILABLE" ]; then
        echo "❌ Domain is NOT available (already registered)"
        
        echo ""
        echo "🔍 Checking WHOIS information..."
        whois "$DOMAIN_NAME" | head -20 2>/dev/null || echo "WHOIS data not available"
        
        echo ""
        echo "💡 Try these alternatives:"
        BASE_NAME="${DOMAIN_NAME%.*}"
        EXTENSION="${DOMAIN_NAME##*.}"
        
        echo "   ${BASE_NAME}app.$EXTENSION"
        echo "   ${BASE_NAME}hub.$EXTENSION"
        echo "   ${BASE_NAME}io.${EXTENSION}"
        echo "   my${BASE_NAME}.$EXTENSION"
        echo "   ${BASE_NAME}.app"
        echo "   ${BASE_NAME}.dev"
        
    else
        echo "⚠️  Domain availability: $AVAILABILITY"
    fi
    
else
    echo "⚠️  Unable to check domain via Route53 (possibly not a supported TLD)"
    echo ""
    echo "🔍 Alternative check methods:"
    echo "1. Manual check: https://domains.google/registrar/search/domain/$DOMAIN_NAME"
    echo "2. Namecheap: https://www.namecheap.com/domains/domain-name-search/"
    echo "3. GoDaddy: https://www.godaddy.com/domains/domain-name-search"
fi

echo ""
echo "📋 Next steps if available:"
echo "1. Register domain (Route53 or external provider)"
echo "2. Run: ./setup-custom-domain.sh $DOMAIN_NAME"
echo "3. Add DNS records provided by the script"
echo "4. Wait for propagation (5 minutes - 24 hours)"

echo ""
echo "🌐 Current S3 URL (works now):"
echo "   http://serverless-task-managerfrontend.s3-website-us-east-1.amazonaws.com"