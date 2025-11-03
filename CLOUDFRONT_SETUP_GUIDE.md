# CloudFront Setup Guide for Serverless Task Manager

## Current Status
❌ **Issue**: IAM user `serverless-task-manager-deploy` lacks CloudFront permissions
✅ **S3 Website**: Working at `http://serverless-task-managerfrontend.s3-website-us-east-1.amazonaws.com`

## Solution Options

### Option 1: AWS Console (Recommended - Easy)

1. **Open AWS CloudFront Console**
   - Go to: https://console.aws.amazon.com/cloudfront/v3/home
   - Click "Create Distribution"

2. **Origin Settings**
   - **Origin Domain**: `serverless-task-managerfrontend.s3-website-us-east-1.amazonaws.com`
   - **Protocol**: HTTP only
   - **Origin Path**: Leave empty

3. **Default Cache Behavior**
   - **Viewer Protocol Policy**: Redirect HTTP to HTTPS
   - **Allowed HTTP Methods**: GET, HEAD
   - **Cache Policy**: Managed-CachingOptimized
   - **Compress Objects**: Yes

4. **Distribution Settings**
   - **Default Root Object**: `index.html`
   - **Price Class**: Use All Edge Locations (or US/Europe for cost savings)

5. **Custom Error Pages**
   - Add custom error response:
     - **HTTP Error Code**: 404
     - **Response Page Path**: `/index.html`
     - **HTTP Response Code**: 200

6. **Create Distribution**
   - Click "Create Distribution"
   - Wait 15-20 minutes for deployment

### Option 2: Add IAM Permissions

Add this policy to your IAM user:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "cloudfront:CreateDistribution",
                "cloudfront:GetDistribution",
                "cloudfront:UpdateDistribution",
                "cloudfront:ListDistributions"
            ],
            "Resource": "*"
        }
    ]
}
```

Then run: `./setup-cloudfront.sh`

### Option 3: Terraform (Advanced)

Use the infrastructure script with CloudFront resources:
```bash
cd infrastructure/
# Add CloudFront to main.tf
terraform apply
```

## Expected Results

After CloudFront setup, you'll get:

- **HTTPS URL**: `https://d1234567890abc.cloudfront.net`
- **Global CDN**: Faster loading worldwide
- **SSL Certificate**: Free AWS certificate
- **Caching**: Improved performance
- **SPA Support**: Proper routing for React Router

## Current S3 Direct Access
- **HTTP URL**: http://serverless-task-managerfrontend.s3-website-us-east-1.amazonaws.com
- **Status**: ✅ Working
- **SSL**: ❌ Not available
- **Speed**: ⚠️ Single region only

## Next Steps
1. Choose one of the options above
2. Implement CloudFront distribution
3. Update DNS (optional) to point custom domain to CloudFront
4. Test HTTPS access and performance