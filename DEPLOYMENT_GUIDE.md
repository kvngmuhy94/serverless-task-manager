# 🚀 Serverless Task Manager Deployment

This document provides comprehensive instructions for deploying the Serverless Task Manager to AWS using multiple deployment methods.

## 📋 Table of Contents

- [Quick Start](#-quick-start)
- [Deployment Methods](#-deployment-methods)
- [Prerequisites](#-prerequisites)
- [Local Script Deployment](#-local-script-deployment)
- [GitHub Actions CI/CD](#-github-actions-cicd)
- [Manual Deployment](#-manual-deployment)
- [Environment Configuration](#-environment-configuration)
- [Troubleshooting](#-troubleshooting)

## 🏃‍♂️ Quick Start

### Option 1: Automated Script (Recommended)
```bash
# Make sure you're in the project root
./deploy.sh

# Or with options
./deploy.sh production --skip-tests
./deploy.sh staging --frontend-only
```

### Option 2: GitHub Actions
1. Push your code to GitHub
2. Configure secrets (see [GitHub Actions section](#-github-actions-cicd))
3. Push to `main` branch to trigger deployment

### Option 3: Manual Steps
```bash
cd frontend/client
npm ci
npm run build
aws s3 sync build/ s3://serverless-task-managerfrontend --delete
```

## 🛠 Deployment Methods

### 1. Local Automated Script
- **Best for**: Development and testing
- **Pros**: Full control, immediate feedback, local debugging
- **Cons**: Requires local AWS configuration

### 2. GitHub Actions CI/CD
- **Best for**: Production deployments
- **Pros**: Automated, consistent, version controlled
- **Cons**: Requires GitHub repository setup

### 3. Manual Deployment
- **Best for**: One-off deployments, troubleshooting
- **Pros**: Step-by-step control
- **Cons**: Error-prone, not repeatable

## ✅ Prerequisites

### Required Software
- [Node.js](https://nodejs.org/) (v16 or higher)
- [AWS CLI](https://aws.amazon.com/cli/) (configured with credentials)
- [Git](https://git-scm.com/) (for GitHub Actions)

### AWS Setup
1. **IAM User**: Create with the following permissions:
   - S3: `s3:GetObject`, `s3:PutObject`, `s3:DeleteObject`, `s3:ListBucket`
   - CloudFront: `cloudfront:CreateInvalidation`, `cloudfront:ListDistributions`

2. **S3 Bucket**: `serverless-task-managerfrontend` (configured for static website hosting)

3. **AWS CLI Configuration**:
   ```bash
   aws configure
   # Enter your Access Key ID, Secret Access Key, and region (us-east-1)
   ```

### Verification
```bash
# Test AWS access
aws sts get-caller-identity

# Test S3 access
aws s3 ls s3://serverless-task-managerfrontend
```

## 🔧 Local Script Deployment

### Basic Usage
```bash
# Deploy everything to production
./deploy.sh

# Deploy to staging environment
./deploy.sh staging

# Frontend only deployment
./deploy.sh --frontend-only

# Skip tests for faster deployment
./deploy.sh --skip-tests
```

### Available Options
| Option | Description | Example |
|--------|-------------|---------|
| `production\|staging\|dev` | Environment | `./deploy.sh staging` |
| `--frontend-only` | Deploy only React app | `./deploy.sh --frontend-only` |
| `--backend-only` | Deploy only Lambda functions | `./deploy.sh --backend-only` |
| `--skip-tests` | Skip running tests | `./deploy.sh --skip-tests` |
| `--skip-build` | Use existing build | `./deploy.sh --skip-build` |
| `--skip-cache` | Skip CloudFront invalidation | `./deploy.sh --skip-cache` |
| `--dry-run` | Show what would be deployed | `./deploy.sh --dry-run` |
| `--help` | Show help message | `./deploy.sh --help` |

### Script Features
- ✅ Dependency installation
- ✅ Test execution with coverage
- ✅ React app building
- ✅ S3 deployment with cache headers
- ✅ CloudFront cache invalidation
- ✅ Health checks
- ✅ Deployment summary

## 🤖 GitHub Actions CI/CD

### Setup Instructions

1. **Repository Secrets** (Settings → Secrets and variables → Actions):
   ```
   AWS_ACCESS_KEY_ID: Your IAM user access key
   AWS_SECRET_ACCESS_KEY: Your IAM user secret key
   ```

2. **Workflow Configuration** (already created in `.github/workflows/deploy.yml`):
   - Triggers on push to `main` branch
   - Runs tests and builds React app
   - Deploys to S3 and invalidates CloudFront

### Workflow Steps
1. **Checkout Code**: Get latest code from repository
2. **Setup Node.js**: Install Node.js v18
3. **Install Dependencies**: `npm ci` for consistent installs
4. **Run Tests**: Execute test suite with coverage
5. **Build Application**: Create production React build
6. **Deploy to S3**: Sync files with appropriate cache headers
7. **Invalidate CloudFront**: Clear CDN cache for immediate updates
8. **Health Check**: Verify deployment success

### Monitoring
- View workflow runs: GitHub → Actions tab
- Check logs for each step
- Monitor deployment status

## 📖 Manual Deployment

### Step-by-Step Process

1. **Navigate to Frontend**:
   ```bash
   cd frontend/client
   ```

2. **Install Dependencies**:
   ```bash
   npm ci
   ```

3. **Run Tests** (optional):
   ```bash
   npm test -- --coverage --watchAll=false
   ```

4. **Build Application**:
   ```bash
   npm run build
   ```

5. **Deploy to S3**:
   ```bash
   # Sync static assets with long cache
   aws s3 sync build/ s3://serverless-task-managerfrontend \
     --delete \
     --cache-control "max-age=31536000" \
     --exclude "*.html" \
     --exclude "service-worker.js" \
     --exclude "manifest.json"
   
   # Upload HTML files with no cache
   aws s3 sync build/ s3://serverless-task-managerfrontend \
     --cache-control "no-cache, no-store, must-revalidate" \
     --include "*.html" \
     --include "service-worker.js" \
     --include "manifest.json"
   ```

6. **Invalidate CloudFront** (if configured):
   ```bash
   aws cloudfront create-invalidation \
     --distribution-id YOUR_DISTRIBUTION_ID \
     --paths "/*"
   ```

## ⚙️ Environment Configuration

### Production Environment
- **S3 Bucket**: `serverless-task-managerfrontend`
- **URL**: https://your-cloudfront-domain.cloudfront.net
- **Features**: CloudFront CDN, custom domain support

### Staging Environment
- **S3 Bucket**: `serverless-task-managerfrontend-staging`
- **URL**: http://serverless-task-managerfrontend-staging.s3-website-us-east-1.amazonaws.com
- **Features**: Testing environment, separate from production

### Development Environment
- **S3 Bucket**: `serverless-task-managerfrontend-dev`
- **URL**: http://serverless-task-managerfrontend-dev.s3-website-us-east-1.amazonaws.com
- **Features**: Development testing, rapid iterations

### Environment Variables
```bash
# Set environment-specific variables
export AWS_REGION=us-east-1
export S3_BUCKET=serverless-task-managerfrontend
export NODE_ENV=production
```

## 🔍 Troubleshooting

### Common Issues and Solutions

#### 1. AWS Credentials Not Configured
**Error**: `Unable to locate credentials`
**Solution**:
```bash
aws configure
# Or set environment variables
export AWS_ACCESS_KEY_ID=your-key
export AWS_SECRET_ACCESS_KEY=your-secret
```

#### 2. S3 Bucket Not Found
**Error**: `NoSuchBucket: The specified bucket does not exist`
**Solutions**:
- Create bucket: `aws s3 mb s3://serverless-task-managerfrontend`
- Check bucket name spelling
- Verify AWS region

#### 3. Permission Denied
**Error**: `AccessDenied: Access Denied`
**Solutions**:
- Check IAM user permissions
- Verify bucket policy
- Ensure correct AWS region

#### 4. Build Fails
**Error**: `npm run build` fails
**Solutions**:
```bash
# Clear cache and reinstall
rm -rf node_modules package-lock.json
npm install

# Check Node.js version
node --version  # Should be v16+
```

#### 5. CloudFront Invalidation Fails
**Error**: `AccessDenied` on CloudFront operations
**Solutions**:
- Add CloudFront permissions to IAM user
- Use manual console invalidation
- Skip with `--skip-cache` flag

#### 6. Health Check Fails
**Error**: Website not accessible after deployment
**Solutions**:
- Wait 1-2 minutes for S3 propagation
- Check S3 website configuration
- Verify index.html exists in bucket

### Debug Commands
```bash
# Check AWS configuration
aws sts get-caller-identity

# List S3 bucket contents
aws s3 ls s3://serverless-task-managerfrontend --recursive

# Check CloudFront distributions
aws cloudfront list-distributions

# Test website accessibility
curl -I http://serverless-task-managerfrontend.s3-website-us-east-1.amazonaws.com
```

### Getting Help
1. **Check Logs**: Review deployment script output
2. **AWS Console**: Check S3 and CloudFront consoles
3. **GitHub Issues**: Check repository issues
4. **AWS Support**: For AWS-specific problems

## 📊 Deployment Monitoring

### Health Checks
The deployment script includes automatic health checks:
- S3 website accessibility
- CloudFront distribution status
- Basic HTTP response validation

### Monitoring URLs
- **S3 Direct**: http://serverless-task-managerfrontend.s3-website-us-east-1.amazonaws.com
- **CloudFront**: https://your-distribution.cloudfront.net
- **Custom Domain**: https://yourdomain.com (if configured)

### Performance Metrics
- **Build Time**: ~30-60 seconds
- **Deployment Time**: ~2-5 minutes
- **CloudFront Propagation**: ~10-15 minutes

---

## 🎯 Next Steps

After successful deployment:

1. **Set up CloudFront** (if not done):
   ```bash
   ./setup-cloudfront.sh
   ```

2. **Configure Custom Domain**:
   ```bash
   ./setup-custom-domain.sh yourdomain.com
   ```

3. **Monitor and Maintain**:
   - Regular dependency updates
   - Security patches
   - Performance optimization

4. **Backend Integration**:
   - Deploy Lambda functions
   - Connect API endpoints
   - Restore authentication

For questions or issues, refer to the troubleshooting section above or check the project documentation.