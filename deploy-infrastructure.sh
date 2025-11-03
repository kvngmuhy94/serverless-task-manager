#!/bin/bash

# Script to deploy the serverless task manager infrastructure
echo "🚀 Deploying Serverless Task Manager Infrastructure..."

# Check if AWS CLI is configured
if ! aws sts get-caller-identity &>/dev/null; then
    echo "❌ AWS CLI not configured. Please run 'aws configure' first."
    exit 1
fi

# Create infrastructure directory if it doesn't exist
mkdir -p infrastructure
cd infrastructure

# Initialize Terraform if needed
if [ ! -f ".terraform/terraform.tfstate" ]; then
    echo "📦 Initializing Terraform..."
    terraform init
fi

# Plan the deployment
echo "📋 Planning infrastructure deployment..."
terraform plan

# Ask user for confirmation
read -p "🤔 Do you want to apply these changes? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🔨 Applying infrastructure changes..."
    terraform apply -auto-approve
    
    # Extract outputs
    echo "📄 Extracting deployment outputs..."
    COGNITO_USER_POOL_ID=$(terraform output -raw cognito_user_pool_id)
    COGNITO_CLIENT_ID=$(terraform output -raw cognito_client_id)
    API_GATEWAY_URL=$(terraform output -raw api_gateway_invoke_url)
    
    echo "✅ Deployment complete!"
    echo "📋 Update your frontend configuration with these values:"
    echo "   Cognito User Pool ID: $COGNITO_USER_POOL_ID"
    echo "   Cognito Client ID: $COGNITO_CLIENT_ID"
    echo "   API Gateway URL: $API_GATEWAY_URL"
else
    echo "❌ Deployment cancelled."
fi