#!/bin/bash
# Build and push Keycloak Docker image to ECR
# Usage: ./build-and-push.sh <environment> [image-tag]
# Example: ./build-and-push.sh dev latest

set -e

ENVIRONMENT=${1:-dev}
IMAGE_TAG=${2:-latest}
AWS_PROFILE="datahub-dev"
AWS_REGION="us-east-1"
PROJECT_NAME="canopy"  # Update this to match your project name

if [ -z "$ENVIRONMENT" ]; then
    echo "❌ Error: Environment is required"
    echo "Usage: $0 <environment> [image-tag]"
    echo "Example: $0 dev latest"
    exit 1
fi

echo "🔨 Building and pushing Keycloak image..."
echo "   Environment: $ENVIRONMENT"
echo "   Image Tag: $IMAGE_TAG"
echo "   Project: $PROJECT_NAME"
echo ""

# Get AWS account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --profile $AWS_PROFILE --query Account --output text)
ECR_REPO="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${PROJECT_NAME}-keycloak/${ENVIRONMENT}"

echo "📦 ECR Repository: $ECR_REPO"
echo ""

# Authenticate with ECR
echo "🔐 Authenticating with ECR..."
aws ecr get-login-password --region $AWS_REGION --profile $AWS_PROFILE | \
  docker login --username AWS --password-stdin $ECR_REPO

# Build the image
echo "🔨 Building Docker image..."
docker build -t keycloak:$IMAGE_TAG .

# Tag the image
echo "🏷️  Tagging image..."
docker tag keycloak:$IMAGE_TAG $ECR_REPO:$IMAGE_TAG

# Push the image
echo "📤 Pushing image to ECR..."
docker push $ECR_REPO:$IMAGE_TAG

echo ""
echo "✅ Successfully pushed Keycloak image to ECR!"
echo "   Image: $ECR_REPO:$IMAGE_TAG"
echo ""
echo "📋 Next steps:"
echo "   1. Deploy/update the ECS stack to use this image"
echo "   2. Check ECS service status after deployment"
echo "   3. Verify Keycloak is accessible via Load Balancer"
