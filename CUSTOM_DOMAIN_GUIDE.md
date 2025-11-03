# Custom Domain Setup for Serverless Task Manager

## Overview
Connect your own domain (e.g., `taskmanager.yourdomain.com`) to your React app with HTTPS.

## Prerequisites
- ✅ Domain name registered (GoDaddy, Namecheap, Route53, etc.)
- ✅ Access to DNS settings
- ✅ S3 website already deployed

## Step-by-Step Setup

### Option 1: Using AWS Route53 (Recommended)

#### 1. Register or Transfer Domain to Route53
```bash
# Check if domain is available
aws route53domains check-domain-availability --domain-name yourdomain.com

# Get pricing
aws route53domains get-domain-detail --domain-name yourdomain.com
```

#### 2. Create Hosted Zone
```bash
# Create hosted zone for your domain
aws route53 create-hosted-zone \
  --name yourdomain.com \
  --caller-reference "$(date +%s)" \
  --hosted-zone-config Comment="Serverless Task Manager domain"
```

#### 3. Request SSL Certificate
```bash
# Request certificate for your domain and www subdomain
aws acm request-certificate \
  --domain-name yourdomain.com \
  --subject-alternative-names www.yourdomain.com \
  --validation-method DNS \
  --region us-east-1
```

#### 4. Create CloudFront Distribution with Custom Domain
```bash
# Run our automated script
./setup-custom-domain.sh yourdomain.com
```

### Option 2: Using External DNS Provider

#### 1. Request SSL Certificate
```bash
# Request certificate (must be in us-east-1 for CloudFront)
aws acm request-certificate \
  --domain-name yourdomain.com \
  --subject-alternative-names www.yourdomain.com \
  --validation-method DNS \
  --region us-east-1
```

#### 2. Validate Certificate
- AWS will provide DNS records to add to your domain
- Add CNAME records to your DNS provider
- Wait for validation (5-30 minutes)

#### 3. Create CloudFront Distribution
```bash
# After certificate is validated
./setup-custom-domain.sh yourdomain.com
```

#### 4. Update DNS Settings
Point your domain to CloudFront:
```
Type: CNAME
Name: www (or @)
Value: d1234567890abc.cloudfront.net
TTL: 300
```

### Option 3: Quick Setup with Existing Domain

If you already have a domain and DNS provider:

1. **Get SSL Certificate ARN** (after validation)
2. **Create CloudFront Distribution** with custom domain
3. **Update DNS** to point to CloudFront
4. **Test HTTPS access**

## Expected Timeline
- **Certificate Request**: 2 minutes
- **DNS Validation**: 5-30 minutes
- **CloudFront Deployment**: 15-20 minutes
- **DNS Propagation**: 5 minutes - 24 hours
- **Total**: 30 minutes - 24 hours

## Final URLs
After setup, your app will be available at:
- `https://yourdomain.com`
- `https://www.yourdomain.com`
- Original S3: `http://serverless-task-managerfrontend.s3-website-us-east-1.amazonaws.com`

## Costs (AWS Route53)
- Domain registration: $12-15/year
- Hosted Zone: $0.50/month
- SSL Certificate: Free
- CloudFront: $0.085/GB + requests
- Route53 queries: $0.40/million queries

## Benefits
- ✅ Professional custom domain
- ✅ HTTPS security
- ✅ Global CDN performance
- ✅ SEO optimization
- ✅ Brand credibility