#!/bin/bash

# Automated Deployment Script for Serverless Task Manager
# Usage: ./deploy.sh [environment] [options]

set -e

# Configuration
PROJECT_NAME="serverless-task-manager"
S3_BUCKET="serverless-task-managerfrontend"
AWS_REGION="us-east-1"
FRONTEND_DIR="frontend/client"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

show_help() {
    echo "🚀 Serverless Task Manager - Automated Deployment"
    echo "================================================="
    echo ""
    echo "Usage: $0 [environment] [options]"
    echo ""
    echo "Environments:"
    echo "  production   Deploy to production (default)"
    echo "  staging      Deploy to staging environment"
    echo "  dev          Deploy to development environment"
    echo ""
    echo "Options:"
    echo "  --frontend-only    Deploy only frontend (React app)"
    echo "  --backend-only     Deploy only backend (Lambda functions)"
    echo "  --skip-tests       Skip running tests"
    echo "  --skip-build       Skip build step (use existing build)"
    echo "  --skip-cache       Skip CloudFront cache invalidation"
    echo "  --dry-run          Show what would be deployed without deploying"
    echo "  --help             Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                           # Deploy everything to production"
    echo "  $0 staging                   # Deploy to staging"
    echo "  $0 --frontend-only           # Deploy only React app"
    echo "  $0 production --skip-tests   # Deploy to production without tests"
    echo ""
}

check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if AWS CLI is installed and configured
    if ! command -v aws &> /dev/null; then
        log_error "AWS CLI is not installed"
        exit 1
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        log_error "AWS credentials not configured"
        exit 1
    fi
    
    # Check if Node.js is installed
    if ! command -v node &> /dev/null; then
        log_error "Node.js is not installed"
        exit 1
    fi
    
    # Check if npm is installed
    if ! command -v npm &> /dev/null; then
        log_error "npm is not installed"
        exit 1
    fi
    
    # Check if frontend directory exists
    if [ ! -d "$FRONTEND_DIR" ]; then
        log_error "Frontend directory not found: $FRONTEND_DIR"
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

install_dependencies() {
    if [ "$SKIP_BUILD" = "true" ]; then
        log_info "Skipping dependency installation"
        return
    fi
    
    log_info "Installing dependencies..."
    cd "$FRONTEND_DIR"
    
    if [ -f "package-lock.json" ]; then
        npm ci
    else
        npm install
    fi
    
    cd - > /dev/null
    log_success "Dependencies installed"
}

run_tests() {
    if [ "$SKIP_TESTS" = "true" ]; then
        log_info "Skipping tests"
        return
    fi
    
    log_info "Running tests..."
    cd "$FRONTEND_DIR"
    
    # Run tests with coverage
    npm test -- --coverage --watchAll=false
    
    cd - > /dev/null
    log_success "Tests passed"
}

build_frontend() {
    if [ "$SKIP_BUILD" = "true" ]; then
        log_info "Skipping build"
        return
    fi
    
    log_info "Building React app..."
    cd "$FRONTEND_DIR"
    
    # Build the app
    npm run build
    
    # Check if build directory exists
    if [ ! -d "build" ]; then
        log_error "Build failed - build directory not found"
        exit 1
    fi
    
    cd - > /dev/null
    log_success "React app built successfully"
}

deploy_to_s3() {
    if [ "$DRY_RUN" = "true" ]; then
        log_info "DRY RUN: Would sync build/ to s3://$S3_BUCKET"
        return
    fi
    
    log_info "Deploying to S3 bucket: $S3_BUCKET"
    cd "$FRONTEND_DIR"
    
    # Sync files to S3 with appropriate cache headers
    aws s3 sync build/ s3://$S3_BUCKET \
        --delete \
        --cache-control "max-age=31536000" \
        --exclude "*.html" \
        --exclude "service-worker.js" \
        --exclude "manifest.json"
    
    # Upload HTML files with no-cache
    aws s3 sync build/ s3://$S3_BUCKET \
        --cache-control "no-cache, no-store, must-revalidate" \
        --include "*.html" \
        --include "service-worker.js" \
        --include "manifest.json"
    
    cd - > /dev/null
    log_success "Deployed to S3"
}

invalidate_cloudfront() {
    if [ "$SKIP_CACHE" = "true" ]; then
        log_info "Skipping CloudFront cache invalidation"
        return
    fi
    
    if [ "$DRY_RUN" = "true" ]; then
        log_info "DRY RUN: Would invalidate CloudFront cache"
        return
    fi
    
    log_info "Checking for CloudFront distribution..."
    
    # Find CloudFront distribution for this S3 bucket
    DISTRIBUTION_ID=$(aws cloudfront list-distributions \
        --query "DistributionList.Items[?Origins.Items[?DomainName=='$S3_BUCKET.s3-website-us-east-1.amazonaws.com']].Id" \
        --output text)
    
    if [ -z "$DISTRIBUTION_ID" ] || [ "$DISTRIBUTION_ID" = "None" ]; then
        log_warning "No CloudFront distribution found"
        return
    fi
    
    log_info "Invalidating CloudFront cache for distribution: $DISTRIBUTION_ID"
    
    # Create invalidation
    INVALIDATION_ID=$(aws cloudfront create-invalidation \
        --distribution-id "$DISTRIBUTION_ID" \
        --paths "/*" \
        --query 'Invalidation.Id' \
        --output text)
    
    log_success "CloudFront invalidation created: $INVALIDATION_ID"
}

deploy_backend() {
    if [ "$FRONTEND_ONLY" = "true" ]; then
        log_info "Skipping backend deployment (frontend-only mode)"
        return
    fi
    
    log_info "Checking for backend changes..."
    
    # Check if backend directory exists
    if [ ! -d "backend" ]; then
        log_warning "No backend directory found"
        return
    fi
    
    # For now, just log that backend deployment would happen
    # You can add actual deployment logic here (SAM, Terraform, etc.)
    log_info "Backend deployment not implemented yet"
    log_info "To deploy backend, run your infrastructure deployment script"
}

run_health_checks() {
    if [ "$DRY_RUN" = "true" ]; then
        log_info "DRY RUN: Would run health checks"
        return
    fi
    
    log_info "Running health checks..."
    
    # Test S3 website
    S3_URL="http://$S3_BUCKET.s3-website-us-east-1.amazonaws.com"
    if curl -f -s "$S3_URL" > /dev/null; then
        log_success "S3 website health check passed"
    else
        log_error "S3 website health check failed"
        return 1
    fi
    
    # Test CloudFront if it exists
    DISTRIBUTION_DOMAIN=$(aws cloudfront list-distributions \
        --query "DistributionList.Items[?Origins.Items[?DomainName=='$S3_BUCKET.s3-website-us-east-1.amazonaws.com']].DomainName" \
        --output text)
    
    if [ ! -z "$DISTRIBUTION_DOMAIN" ] && [ "$DISTRIBUTION_DOMAIN" != "None" ]; then
        if curl -f -s "https://$DISTRIBUTION_DOMAIN" > /dev/null; then
            log_success "CloudFront health check passed"
        else
            log_warning "CloudFront health check failed (may need time to propagate)"
        fi
    fi
}

show_deployment_info() {
    echo ""
    echo "🎉 Deployment Summary"
    echo "===================="
    echo "Environment: $ENVIRONMENT"
    echo "S3 Bucket: $S3_BUCKET"
    echo "S3 URL: http://$S3_BUCKET.s3-website-us-east-1.amazonaws.com"
    
    # Show CloudFront URL if exists
    DISTRIBUTION_DOMAIN=$(aws cloudfront list-distributions \
        --query "DistributionList.Items[?Origins.Items[?DomainName=='$S3_BUCKET.s3-website-us-east-1.amazonaws.com']].DomainName" \
        --output text)
    
    if [ ! -z "$DISTRIBUTION_DOMAIN" ] && [ "$DISTRIBUTION_DOMAIN" != "None" ]; then
        echo "CloudFront URL: https://$DISTRIBUTION_DOMAIN"
    fi
    
    echo ""
    echo "📊 Deployment completed successfully!"
    echo "🕐 Timestamp: $(date)"
}

# Main deployment function
main() {
    # Parse arguments
    ENVIRONMENT="production"
    FRONTEND_ONLY="false"
    BACKEND_ONLY="false"
    SKIP_TESTS="false"
    SKIP_BUILD="false"
    SKIP_CACHE="false"
    DRY_RUN="false"
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            production|staging|dev)
                ENVIRONMENT="$1"
                shift
                ;;
            --frontend-only)
                FRONTEND_ONLY="true"
                shift
                ;;
            --backend-only)
                BACKEND_ONLY="true"
                shift
                ;;
            --skip-tests)
                SKIP_TESTS="true"
                shift
                ;;
            --skip-build)
                SKIP_BUILD="true"
                shift
                ;;
            --skip-cache)
                SKIP_CACHE="true"
                shift
                ;;
            --dry-run)
                DRY_RUN="true"
                shift
                ;;
            --help)
                show_help
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Adjust S3 bucket name based on environment
    if [ "$ENVIRONMENT" != "production" ]; then
        S3_BUCKET="${S3_BUCKET}-${ENVIRONMENT}"
    fi
    
    echo "🚀 Starting deployment to $ENVIRONMENT environment"
    echo "================================================="
    
    # Run deployment steps
    check_prerequisites
    
    if [ "$BACKEND_ONLY" != "true" ]; then
        install_dependencies
        run_tests
        build_frontend
        deploy_to_s3
        invalidate_cloudfront
    fi
    
    if [ "$FRONTEND_ONLY" != "true" ]; then
        deploy_backend
    fi
    
    run_health_checks
    show_deployment_info
}

# Run main function with all arguments
main "$@"