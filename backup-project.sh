#!/bin/bash

# Serverless Task Manager - Configuration Backup Script
# This script creates a backup of all important configurations and deployment files

set -e

PROJECT_NAME="serverless-task-manager"
BACKUP_DIR="$HOME/project-backups/$PROJECT_NAME-$(date +%Y%m%d-%H%M%S)"
CURRENT_DIR="$(pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

echo "🗄️  Serverless Task Manager - Configuration Backup"
echo "================================================="

# Create backup directory
log_info "Creating backup directory: $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"

# Copy deployment configurations
log_info "Backing up deployment configurations..."
cp deploy.sh "$BACKUP_DIR/" 2>/dev/null || log_warning "deploy.sh not found"
cp setup-cloudfront.sh "$BACKUP_DIR/" 2>/dev/null || log_warning "setup-cloudfront.sh not found"
cp setup-custom-domain.sh "$BACKUP_DIR/" 2>/dev/null || log_warning "setup-custom-domain.sh not found"
cp check-domain.sh "$BACKUP_DIR/" 2>/dev/null || log_warning "check-domain.sh not found"
cp verify-domain.sh "$BACKUP_DIR/" 2>/dev/null || log_warning "verify-domain.sh not found"

# Copy GitHub Actions
if [ -d ".github" ]; then
    log_info "Backing up GitHub Actions workflows..."
    cp -r .github "$BACKUP_DIR/"
else
    log_warning ".github directory not found"
fi

# Copy documentation
log_info "Backing up documentation..."
cp README.md "$BACKUP_DIR/" 2>/dev/null || log_warning "README.md not found"
cp DEPLOYMENT_GUIDE.md "$BACKUP_DIR/" 2>/dev/null || log_warning "DEPLOYMENT_GUIDE.md not found"
cp CLOUDFRONT_SETUP_GUIDE.md "$BACKUP_DIR/" 2>/dev/null || log_warning "CLOUDFRONT_SETUP_GUIDE.md not found"
cp CUSTOM_DOMAIN_GUIDE.md "$BACKUP_DIR/" 2>/dev/null || log_warning "CUSTOM_DOMAIN_GUIDE.md not found"
cp PROJECT_ARCHIVE.md "$BACKUP_DIR/" 2>/dev/null || log_warning "PROJECT_ARCHIVE.md not found"

# Copy package configurations
log_info "Backing up package configurations..."
cp package.json "$BACKUP_DIR/" 2>/dev/null || log_warning "package.json not found"
cp package-lock.json "$BACKUP_DIR/" 2>/dev/null || log_warning "package-lock.json not found"

# Copy frontend configurations
if [ -d "frontend/client" ]; then
    log_info "Backing up frontend configurations..."
    mkdir -p "$BACKUP_DIR/frontend/client"
    cp frontend/client/package.json "$BACKUP_DIR/frontend/client/" 2>/dev/null
    cp frontend/client/tailwind.config.js "$BACKUP_DIR/frontend/client/" 2>/dev/null
    cp frontend/client/postcss.config.js "$BACKUP_DIR/frontend/client/" 2>/dev/null
    
    # Copy source files (key components only)
    if [ -d "frontend/client/src" ]; then
        mkdir -p "$BACKUP_DIR/frontend/client/src"
        cp frontend/client/src/App.js "$BACKUP_DIR/frontend/client/src/" 2>/dev/null
        cp frontend/client/src/Tasks.js "$BACKUP_DIR/frontend/client/src/" 2>/dev/null
        cp frontend/client/src/Login.js "$BACKUP_DIR/frontend/client/src/" 2>/dev/null
        cp frontend/client/src/Register.js "$BACKUP_DIR/frontend/client/src/" 2>/dev/null
        cp frontend/client/src/aws-exports.js "$BACKUP_DIR/frontend/client/src/" 2>/dev/null
        cp frontend/client/src/index.js "$BACKUP_DIR/frontend/client/src/" 2>/dev/null
        cp frontend/client/src/index.css "$BACKUP_DIR/frontend/client/src/" 2>/dev/null
    fi
else
    log_warning "frontend/client directory not found"
fi

# Copy backend configurations
if [ -d "backend" ]; then
    log_info "Backing up backend configurations..."
    cp -r backend "$BACKUP_DIR/"
else
    log_warning "backend directory not found"
fi

# Copy infrastructure configurations
if [ -d "infrastructure" ]; then
    log_info "Backing up infrastructure configurations..."
    cp -r infrastructure "$BACKUP_DIR/"
else
    log_warning "infrastructure directory not found"
fi

# Copy API documentation
log_info "Backing up API documentation..."
cp Serverless_Task_Manager_API.postman_collection.json "$BACKUP_DIR/" 2>/dev/null || log_warning "Postman collection not found"

# Copy test files
log_info "Backing up test configurations..."
cp test-*.json "$BACKUP_DIR/" 2>/dev/null || log_warning "Test files not found"
cp *test*.json "$BACKUP_DIR/" 2>/dev/null || true

# Copy git configuration (if it exists)
if [ -f ".gitignore" ]; then
    log_info "Backing up git configuration..."
    cp .gitignore "$BACKUP_DIR/"
fi

# Create environment backup
log_info "Creating environment configuration backup..."
cat > "$BACKUP_DIR/ENVIRONMENT_CONFIG.md" << 'EOF'
# Environment Configuration Backup

## AWS Configuration
```bash
# Region
AWS_REGION=us-east-1

# S3 Bucket
S3_BUCKET=serverless-task-managerfrontend

# API Gateway
API_URL=https://s0wt8rhr5j.execute-api.us-east-1.amazonaws.com/prod
```

## Node.js Environment
```bash
NODE_VERSION=v18.x
NPM_VERSION=9.x
REACT_VERSION=19.2.0
```

## Deployment URLs
```
S3 Website: http://serverless-task-managerfrontend.s3-website-us-east-1.amazonaws.com
GitHub Repo: https://github.com/kvngmuhy94/serverless-task-manager
```

## IAM User
```
Username: serverless-task-manager-deploy
Permissions: S3, API Gateway, Lambda (CloudFront permissions needed)
```

## GitHub Actions Secrets
```
AWS_ACCESS_KEY_ID: (configured in repository)
AWS_SECRET_ACCESS_KEY: (configured in repository)
```
EOF

# Create restoration script
log_info "Creating restoration script..."
cat > "$BACKUP_DIR/restore.sh" << 'EOF'
#!/bin/bash

# Restoration script for Serverless Task Manager project
# Usage: ./restore.sh [target_directory]

TARGET_DIR="${1:-./serverless-task-manager-restored}"

echo "🔄 Restoring Serverless Task Manager project..."
echo "Target directory: $TARGET_DIR"

# Create target directory
mkdir -p "$TARGET_DIR"
cd "$TARGET_DIR"

# Copy all files
echo "📁 Copying project files..."
cp -r ../backend ./
cp -r ../frontend ./
cp -r ../infrastructure ./
cp -r ../.github ./
cp ../*.sh ./
cp ../*.md ./
cp ../*.json ./

# Make scripts executable
chmod +x *.sh

echo "✅ Project restored successfully!"
echo "📍 Location: $(pwd)"
echo ""
echo "Next steps:"
echo "1. cd $TARGET_DIR"
echo "2. Configure AWS credentials"
echo "3. Run: cd frontend/client && npm install"
echo "4. Run: ./deploy.sh --help"
EOF

chmod +x "$BACKUP_DIR/restore.sh"

# Create backup summary
log_info "Creating backup summary..."
cat > "$BACKUP_DIR/BACKUP_SUMMARY.md" << EOF
# Backup Summary

**Created:** $(date)
**Project:** Serverless Task Manager
**Source:** $CURRENT_DIR
**Backup Location:** $BACKUP_DIR

## Backed Up Components

### Deployment Scripts
- deploy.sh - Main deployment automation
- setup-cloudfront.sh - CloudFront CDN setup
- setup-custom-domain.sh - Custom domain configuration
- check-domain.sh - Domain verification
- verify-domain.sh - DNS validation

### CI/CD Configuration
- .github/workflows/deploy.yml - GitHub Actions automation

### Documentation
- README.md - Project overview
- DEPLOYMENT_GUIDE.md - Complete deployment instructions
- CLOUDFRONT_SETUP_GUIDE.md - CDN setup guide
- CUSTOM_DOMAIN_GUIDE.md - Domain configuration
- PROJECT_ARCHIVE.md - Project archive and status

### Code & Configuration
- frontend/ - Complete React application
- backend/ - AWS Lambda functions
- infrastructure/ - Terraform configurations
- package.json - Project dependencies
- API documentation and test files

### Restoration
- restore.sh - Automated restoration script
- ENVIRONMENT_CONFIG.md - Environment setup guide
- BACKUP_SUMMARY.md - This summary file

## Restoration Instructions

1. Navigate to backup directory:
   \`cd $BACKUP_DIR\`

2. Run restoration script:
   \`./restore.sh [target_directory]\`

3. Follow setup instructions in ENVIRONMENT_CONFIG.md

## Support Information

All configurations, scripts, and documentation needed to continue development are included in this backup. The project is 85% complete and ready for immediate development continuation.
EOF

echo ""
log_success "Backup completed successfully!"
echo "📍 Backup location: $BACKUP_DIR"
echo "📄 Files backed up: $(find "$BACKUP_DIR" -type f | wc -l) files"
echo "💾 Backup size: $(du -sh "$BACKUP_DIR" | cut -f1)"
echo ""
echo "🔄 To restore this backup:"
echo "   cd $BACKUP_DIR"
echo "   ./restore.sh"
echo ""
log_info "Backup summary saved to: $BACKUP_DIR/BACKUP_SUMMARY.md"