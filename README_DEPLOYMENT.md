# DataHub AWS Deployment Guide

Complete step-by-step guide for deploying the DataHub application to AWS.

**📘 Note**: This guide focuses on the **manual steps** required between CloudFormation stack deployments. For CloudFormation stack deployment instructions, please follow the **`InstallGuide.ipynb`** Jupyter notebook.

---

## Prerequisites

Before starting, ensure you have:

- [ ] AWS Account with appropriate permissions
- [ ] Git installed on your machine
- [ ] AWS CLI installed and configured
- [ ] Docker installed (for building container images)
- [ ] Java 17 JDK (for building Spring Boot services)
- [ ] Node.js 18+ (for building Next.js frontend)
- [ ] Maven (for Java builds)
- [ ] PostgreSQL client (psql) installed
- [ ] Python 3.11+ (for Lambda functions)

---

## Overview

This deployment process consists of two main parts:

1. **CloudFormation Stack Deployments** - Follow `InstallGuide.ipynb` to deploy all stacks in order
2. **Manual Configuration Steps** - This guide covers the manual steps required between stack deployments

**Stack Deployment Order** (from `InstallGuide.ipynb`):
1. Networking → 2. S3 → 3. SecretsManager → 4. LoadBalancer → 5. RDS → 6. OpenSearch → 7. Route53 (optional) → 8. CloudWatch → 9. SQS → 10. ECR → 11. ECS → 12. Lambda → 13. EventBridge

---

## 🚀 Initial Setup: Clone Repositories

Before starting the deployment, clone all necessary repositories from the BMIR DataHub GitHub organization.

### Step 0: Clone All Repositories

```bash
# Create a workspace directory
mkdir -p ~/dataHub
cd ~/dataHub

# Clone the CloudFormation infrastructure repository
git clone https://github.com/bmir-datahub/datahub-cloud-replication.git

# Clone the development repository (contains database scripts and Lambda functions)
git clone https://github.com/bmir-datahub/datahub-development.git

# Clone all microservice repositories
git clone https://github.com/bmir-datahub/datahub-service-entity.git
git clone https://github.com/bmir-datahub/datahub-service-search.git
git clone https://github.com/bmir-datahub/datahub-service-user.git
git clone https://github.com/bmir-datahub/datahub-service-submission.git
git clone https://github.com/bmir-datahub/datahub-service-report.git
git clone https://github.com/bmir-datahub/datahub-service-download.git
git clone https://github.com/bmir-datahub/datahub-lib-keycloak-auth
git clone https://github.com/bmir-datahub/datahub-service-email.git

# Clone the frontend repository
git clone https://github.com/bmir-datahub/datahub-ui-main.git

# Verify all repositories are cloned
ls -la
```

**Expected directory structure:**
```
~/dataHub/
├── datahub-cloud-replication/     # CloudFormation templates
├── datahub-development/            # Database scripts & Lambda functions
├── datahub-service-entity/         # Entity microservice
├── datahub-service-search/         # Search microservice
├── datahub-service-user/           # User microservice
├── datahub-service-submission/     # Submission microservice
├── datahub-service-report/         # Report microservice
├── datahub-service-download/       # Download microservice
├── datahub-service-email/          # Email microservice
├── datahub-lib-keycloak-auth/      # Keycloak auth library
└── datahub-ui-main/                # Frontend application
```

## 🔧 Set Environment Variables

Before running any commands in this guide, set the following environment variables:

```bash
# Set environment (dev, test, or prod)
export ENV=dev

# Set AWS profile and region
export AWS_PROFILE=datahub-rep  # or your AWS profile name
export AWS_DEFAULT_REGION=us-east-1

# Get DataHubUniqueId from parameters file
cd ~/dataHub/datahub-cloud-replication
export DataHubUniqueId=$(cat parameters-${ENV}.json | grep -o '"DataHubUniqueId": "[^"]*"' | cut -d'"' -f4)

# Verify settings
echo "Environment: $ENV"
echo "AWS Profile: $AWS_PROFILE"
echo "AWS Region: $AWS_DEFAULT_REGION"
echo "DataHubUniqueId: $DataHubUniqueId"
```

**Note**: These variables are used throughout this guide. Make sure to set them before proceeding.

---

## 🚀 Step 1: Deploy CloudFormation Stacks

```bash
# Navigate to CloudFormation repository
cd ~/dataHub/datahub-cloud-replication
```

**Follow `InstallGuide.ipynb`** to deploy all CloudFormation stacks in the correct order. The notebook contains detailed instructions for:

- AWS CLI installation and configuration
- AWS credentials setup
- Deploying each stack (Networking, S3, SecretsManager, LoadBalancer, RDS, OpenSearch, Route53, CloudWatch, SQS, ECR, ECS, Lambda, EventBridge)

**Important**: Wait for each stack to complete before proceeding to the next one. Check the AWS Console CloudFormation page to monitor progress.

---

## 🔧 Step 2: RDS Database Schema Setup

After the **RDS Stack** is deployed (Step 9 in `InstallGuide.ipynb`), manual steps are needed to create the database schema and populate basic data in the RDS instance:

**📘 For detailed RDS deployment instructions, see [`README_RDS_DEPLOYMENT.md`](../datahub-development/db/postgres/db-create-scripts/README_RDS_DEPLOYMENT.md)**

## 🔧 Step 3: Lambda Function Code Setup
Lambda function code needs to be uploaded to S3 to be ingested into lambda.

### Opensearch reindex
**📘 For detailed Lambda deployment instructions, see [`README_OPENSEARCH_REINDEX_AWS.md`](../datahub-development/opensearch/opensearch_reindex/README_OPENSEARCH_REINDEX_AWS.md)**

### Email service

```bash
cd ~/dataHub/datahub-service-email

# Build the Spring Boot application for AWS Lambda
mvn clean package -DskipTests

# Upload to S3
aws s3 cp target/datahub-service-email-0.0.1-SNAPSHOT-aws.jar \
  s3://datahub-lambda-artifacts-${DataHubUniqueId}-${ENV}/email-service/ \
  --region ${AWS_DEFAULT_REGION} \
  --profile ${AWS_PROFILE}
```

**S3 Path**: `s3://datahub-lambda-artifacts-{DataHubUniqueId}-{ENV}/email-service/datahub-service-email-0.0.1-SNAPSHOT-aws.jar` 



## 🔧 Step 4: Secret Manager Environment Variable Updates

After the **OpenSearch Stack** is deployed (Step 14 in `InstallGuide.ipynb`), update Secrets Manager with OpenSearch credentials:

```bash
# Get OpenSearch endpoint
OPENSEARCH_ENDPOINT=$(aws opensearch describe-domain \
  --domain-name datahub-opensearch-${ENV} \
  --region ${AWS_DEFAULT_REGION} \
  --profile ${AWS_PROFILE} \
  --query 'DomainStatus.Endpoint' \
  --output text)

echo "OpenSearch Endpoint: $OPENSEARCH_ENDPOINT"

# Get OpenSearch password from OpenSearch.yaml or set a new one
# Update secret with OpenSearch credentials
aws secretsmanager get-secret-value \
  --secret-id application_${ENV} \
  --region ${AWS_DEFAULT_REGION} \
  --profile ${AWS_PROFILE} \
  --query SecretString \
  --output text > secret.json

# Edit secret.json - update:
# "opensearch.hostname": "search-datahub-opensearch-dev-xxxxx.us-east-1.es.amazonaws.com"
# "opensearch.password": "actual_password"

aws secretsmanager update-secret \
  --secret-id application_${ENV} \
  --region ${AWS_DEFAULT_REGION} \
  --profile ${AWS_PROFILE} \
  --secret-string file://secret.json

rm secret.json
```

---

## 🔧 Step 5: Build and Push Docker Images

You need to build Docker images for all backend microservices and the frontend, then push them to ECR.

### Prerequisites: Install Docker and Docker Buildx (First-Time Setup)

If you haven't installed Docker yet, follow these steps:

#### macOS
```bash
# Install Docker Desktop (includes Docker and Docker Buildx)
brew install --cask docker

# Start Docker Desktop application
open -a Docker

# Verify installation
docker --version
docker buildx version
```

#### Linux
```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Install Docker Buildx plugin
mkdir -p ~/.docker/cli-plugins
curl -SL https://github.com/docker/buildx/releases/download/v0.12.0/buildx-v0.12.0.linux-amd64 -o ~/.docker/cli-plugins/docker-buildx
chmod +x ~/.docker/cli-plugins/docker-buildx

# Verify installation
docker --version
docker buildx version
```

#### Windows
```powershell
# Install Docker Desktop from: https://www.docker.com/products/docker-desktop
# Docker Buildx is included by default

# Verify installation in PowerShell
docker --version
docker buildx version
```

### Process for Each Service

For each service, follow these three steps:

#### 1. Navigate to the service directory

```bash
cd datahub-service-user    # Change to appropriate service directory
```

#### 2. Build the Docker image

Before running Docker, build the application so the Dockerfile can pick them up:

**Spring Boot services (backend)**  
```bash
mvn clean package -DskipTests
```

**React + Next.js (UI)**  
```bash
npm install
npm run build
```

After the package/build completes, build the Docker image:

```bash
docker buildx build --platform linux/amd64 -t {IMAGE_NAME}:latest --load .
```

**What this does**: 
- `--platform linux/amd64`: Builds for AWS ECS (x86_64 architecture)
- `-t {IMAGE_NAME}:latest`: Tags the image with name and version
- `--load`: Loads the built image into your local Docker daemon for immediate use

**Note**: Change the image name to match the service:
- `datahub-user-service`
- `datahub-submission-service`
- `datahub-report-service`
- `datahub-download-service`
- `datahub-entity-service`
- `datahub-search`
- `datahub-ui`

#### 3. Push to ECR and deploy

```bash
cd ..  # Return to project root
./push-and-deploy.sh user-service dev
```

**Parameters**:
- First parameter: Service name (see list below)
- Second parameter: Environment (`dev`, `test`, or `prod`)

**Available service names**:
- `user-service`
- `submission-service`
- `report-service`
- `download-service`
- `entity-service`
- `search-service`
- `ui`

### Complete Example: User Service

```bash
# 1. Navigate to service directory
cd datahub-service-user

# 2. Build the application
mvn clean package -DskipTests

# 3. Build Docker image
docker buildx build --platform linux/amd64 -t datahub-user-service:latest --load .

# 4. Return to project root and deploy
cd ..
./push-and-deploy.sh user-service dev
```

### Complete Example: Frontend (UI)

```bash
# 1. Navigate to UI directory
cd datahub-ui-main

# 2. Build the application
npm install
npm run build

# 3. Build Docker image
docker buildx build --platform linux/amd64 -t datahub-ui:latest --load .

# 4. Return to project root and deploy
cd ..
./push-and-deploy.sh ui dev
```

### Repeat for All Services

Repeat the above process for all required services:

1. **datahub-service-user** → `./push-and-deploy.sh user-service dev`
2. **datahub-service-submission** → `./push-and-deploy.sh submission-service dev`
3. **datahub-service-report** → `./push-and-deploy.sh report-service dev`
4. **datahub-service-download** → `./push-and-deploy.sh download-service dev`
5. **datahub-service-entity** → `./push-and-deploy.sh entity-service dev`
6. **datahub-service-search** → `./push-and-deploy.sh search-service dev`
7. **datahub-ui-main** → `./push-and-deploy.sh ui dev`

### ⚠️ Common Issues and Troubleshooting

#### Network Connection Error During Push

If you encounter an error like this when pushing to ECR:

```
failed to copy: failed to do request: Put "https://772554522152.dkr.ecr.us-east-1.amazonaws.com/v2/datahub-search/dev/blobs/uploads/...": 
write tcp 192.168.65.3:63188->192.168.65.1:3128: use of closed network connection
```

**Solution**: This is a transient network error. Simply **retry the command**:

```bash
./push-and-deploy.sh <service-name> <environment>
```

The push will resume from where it left off. This error typically occurs due to:
- Docker Desktop network proxy issues
- Temporary network instability
- Large image uploads timing out

**If retrying doesn't work**:
1. Restart Docker Desktop
2. Check your network connection

---

### 🔧 Step 7: Manual Steps After SES Stack Deployment

After the **SES Stack** is deployed (Step 17 in `InstallGuide.ipynb`), verify email identities:

#### A. Verify Individual Emails (Quick for Testing)

For non-production environments, verify individual email addresses:

```bash
# Set SES region (us-east-1 or us-west-2)
export SES_REGION=us-east-1  # Change if you deployed SES in us-west-2

# Check verification status
aws ses get-identity-verification-attributes \
  --identities datahub@stanford.edu \
  --region ${SES_REGION} \
  --profile ${AWS_PROFILE}

# Verify via AWS Console:
# 1. Go to AWS Console → SES → Verified identities (in ${SES_REGION})
# 2. Click on each email identity
# 3. Click "Verify" button
# 4. Check the email inbox for verification link
# 5. Click the verification link in the email
```

**Important**: In sandbox mode (dev/test), both sender AND recipient emails must be verified.

#### B. Verify Domain Identity (e.g. stanford.edu)

For domain verification, add DNS records:

```bash
# Get domain verification records
aws ses get-identity-verification-attributes \
  --identities stanford.edu \
  --region ${SES_REGION} \
  --profile ${AWS_PROFILE} \
  --query 'VerificationAttributes.stanford.edu.VerificationToken' \
  --output text

# Get DKIM tokens (if DKIM is enabled)
aws ses get-identity-dkim-attributes \
  --identities stanford.edu \
  --region ${SES_REGION} \
  --profile ${AWS_PROFILE}
```

**DNS Records to Add**:
1. **Verification TXT Record**: Add the verification token as a TXT record in your DNS
2. **DKIM CNAME Records**: Add 3 DKIM CNAME records (if DKIM is enabled)
3. **SPF/DMARC Records**: Optional but recommended for email deliverability

**DNS Propagation**: Allow 24-48 hours for DNS changes to propagate globally.

#### C. Request Production Access (Production Only)

For production, request to move out of sandbox mode:

```bash
# Request production access via AWS Console:
# 1. Go to AWS Console → SES → Account dashboard
# 2. Click "Request production access"
# 3. Fill out the form with your use case
# 4. Wait for AWS approval (usually 24-48 hours)
```

**Verify SES is ready**:

```bash
# Check SES sending quota
aws ses get-send-quota \
  --region ${SES_REGION} \
  --profile ${AWS_PROFILE}

# Check verification status of all identities
aws ses list-identities \
  --region ${SES_REGION} \
  --profile ${AWS_PROFILE}
```

---

## Summary of Manual Steps

Here's a quick reference of all manual steps in order:

1. **After RDS Stack** (Step 9 in `InstallGuide.ipynb`):
   - Update RDS master password
   - Clone `datahub-development` repository
   - Add your IP to RDS security group
   - Deploy database schema
   - Update Secrets Manager with RDS credentials

2. **After OpenSearch Stack** (Step 14 in `InstallGuide.ipynb`):
   - Update Secrets Manager with OpenSearch credentials

3. **After ECR Stack** (Step 13 in `InstallGuide.ipynb`):
   - Build and push all Docker images (7 services + frontend)

4. **Before Lambda Stack** (Step 17 in `InstallGuide.ipynb`):
   - Build and upload Lambda functions to S3
   - Create psycopg2 Lambda layer

5. **After Lambda Stack** (Step 17 in `InstallGuide.ipynb`):
   - Initialize OpenSearch indices

6. **After SES Stack** (Step 17 in `InstallGuide.ipynb`):
   - Verify individual email addresses (datahub@stanford.edu, datahub.dev@stanford.edu)
   - Verify domain identity (stanford.edu) - add DNS records
   - Request production access (production only)

---

## ✅ Post-Deployment Verification

After all stacks are deployed, verify the installation:

### Check Stack Status

```bash
echo "🔍 Checking stack status..."

aws cloudformation list-stacks \
  --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE \
  --query 'StackSummaries[?contains(StackName, `DataHub`)].{Name:StackName,Status:StackStatus}' \
  --output table \
  --region ${AWS_DEFAULT_REGION} \
  --profile ${AWS_PROFILE}

echo "✅ Stack status check complete"
```

### Test Application

```bash
# Get ALB DNS name
ALB_DNS=$(aws elbv2 describe-load-balancers \
  --region ${AWS_DEFAULT_REGION} \
  --profile ${AWS_PROFILE} \
  --query 'LoadBalancers[?contains(LoadBalancerName, `datahub`)].DNSName' \
  --output text)

echo "Application URL: http://$ALB_DNS"

# Test frontend
curl -I http://$ALB_DNS

# Test API endpoints
curl http://$ALB_DNS/api/entity/v1/health
curl http://$ALB_DNS/api/search/v1/health
curl http://$ALB_DNS/api/user/v1/health
```

### Check ECS Service Health

```bash
# Check all services
aws ecs describe-services \
  --cluster datahub-cluster-${ENV} \
  --services datahub-EntityService datahub-SearchService datahub-UserService \
  --region ${AWS_DEFAULT_REGION} \
  --profile ${AWS_PROFILE} \
  --query 'services[*].{Name:serviceName,Running:runningCount,Desired:desiredCount,Status:status}'
```

### Monitor Logs

```bash
# Frontend logs
aws logs tail /ecs/datahub-frontend --region ${AWS_DEFAULT_REGION} --profile ${AWS_PROFILE} --follow

# Entity Service logs
aws logs tail /ecs/datahub-entity-service --region ${AWS_DEFAULT_REGION} --profile ${AWS_PROFILE} --follow

# Lambda logs
aws logs tail /aws/lambda/DataHub-OpenSearchRefresh-${ENV} --region ${AWS_DEFAULT_REGION} --profile ${AWS_PROFILE} --follow
```

---

## 🔧 Troubleshooting

### Common Issues:

#### Stack Creation Failed
```bash
# Check stack events for errors
aws cloudformation describe-stack-events \
  --stack-name DataHub-${ENV}-[STACK-NAME] \
  --region ${AWS_DEFAULT_REGION} \
  --profile ${AWS_PROFILE}
```

#### Resource Already Exists
- S3 bucket names must be globally unique
- Modify bucket names in the S3.yaml template
- ECR repository names must be unique per account

#### Permission Denied
- Ensure your IAM user has all required permissions
- Check AWS credentials are correctly configured
- Verify the AWS profile is set correctly

#### Import Value Not Found
- Ensure previous stacks completed successfully
- Verify stack names match exactly
- Check that exports are available in the Networking stack

#### ECS Service Fails to Start
- Verify Docker images are pushed to ECR
- Check ECS task logs in CloudWatch
- Verify security groups allow traffic
- Check that Secrets Manager secret exists and is accessible

#### Lambda Function Fails
- Verify Lambda code is uploaded to S3
- Check S3 bucket name matches Lambda.yaml
- Verify Lambda has VPC access (if required)
- Check CloudWatch logs for errors
- Verify Secrets Manager permissions

#### Database Connection Issues
- Verify RDS endpoint is correct in Secrets Manager
- Check security group allows connections from ECS/Lambda
- Verify database credentials in Secrets Manager
- Check RDS instance is available (not rebooting)

#### OpenSearch Connection Issues
- Verify OpenSearch endpoint is correct in Secrets Manager
- Check security group allows connections
- Verify OpenSearch credentials in Secrets Manager
- Check OpenSearch domain is active

---

## 🧹 Cleanup

**⚠️ WARNING**: This will delete ALL resources and data. Make sure you have backups of any important data.

### Check Current Stacks Before Cleanup

```bash
echo "📋 Current DataHub stacks:"

aws cloudformation list-stacks \
  --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE \
  --query 'StackSummaries[?contains(StackName, `DataHub`)].{Name:StackName,Status:StackStatus,Created:CreationTime}' \
  --output table \
  --region ${AWS_DEFAULT_REGION} \
  --profile ${AWS_PROFILE}
```

### Manual S3 Bucket Cleanup (Required First)

*S3 buckets with content cannot be deleted by CloudFormation*

```bash
echo "🗁️ Emptying S3 buckets before stack deletion..."

# List all DataHub S3 buckets
aws s3 ls | grep datahub

# Empty each bucket
aws s3 ls | grep datahub | awk '{print $3}' | while read bucket; do
  echo "Emptying bucket: $bucket"
  aws s3 rm s3://$bucket --recursive
  aws s3api delete-bucket-versioning --bucket $bucket --versioning-configuration Status=Suspended
done

echo "✅ S3 buckets emptied"
```

### Delete CloudFormation Stacks

*Stacks must be deleted in reverse order due to dependencies*

```bash
echo "🗂️ Deleting stacks in reverse dependency order..."

# Delete stacks in reverse order
stacks=(
  "DataHub-EventBridge-${ENV}"
  "DataHub-Lambda-${ENV}"
  "DataHub-ECS-${ENV}"
  "DataHub-ECR-${ENV}"
  "DataHub-SQS-${ENV}"
  "DataHub-CloudWatch-${ENV}"
  "DataHub-Route53-${ENV}"
  "DataHub-OpenSearch-${ENV}"
  "DataHub-RDS-${ENV}"
  "DataHub-LoadBalancer-${ENV}"
  "DataHub-SecretsManager-${ENV}"
  "DataHub-S3-${ENV}"
  "DataHub-Networking-${ENV}"
)

for stack in "${stacks[@]}"; do
  echo "🗁️ Deleting stack: $stack"
  aws cloudformation delete-stack \
    --stack-name $stack \
    --region ${AWS_DEFAULT_REGION} \
    --profile ${AWS_PROFILE}

  echo "⏳ Waiting for $stack deletion to complete..."
  aws cloudformation wait stack-delete-complete \
    --stack-name $stack \
    --region ${AWS_DEFAULT_REGION} \
    --profile ${AWS_PROFILE}

  echo "✅ $stack deleted successfully"
  echo ""
done

echo "🎉 Cleanup complete!"
```

### Verify Cleanup

```bash
echo "🔍 Checking for remaining DataHub resources..."

echo "CloudFormation Stacks:"
aws cloudformation list-stacks \
  --query 'StackSummaries[?contains(StackName, `DataHub`) && StackStatus != `DELETE_COMPLETE`].{Name:StackName,Status:StackStatus}' \
  --output table \
  --region ${AWS_DEFAULT_REGION} \
  --profile ${AWS_PROFILE}

echo ""
echo "S3 Buckets:"
aws s3 ls | grep datahub || echo "No DataHub S3 buckets found"

echo ""
echo "Load Balancers:"
aws elbv2 describe-load-balancers \
  --query 'LoadBalancers[?contains(LoadBalancerName, `DataHub`)].LoadBalancerName' \
  --output text \
  --region ${AWS_DEFAULT_REGION} \
  --profile ${AWS_PROFILE} || echo "No DataHub load balancers found"
```

---

## 📚 Additional Information

### Architecture Overview
- **VPC**: Isolated network environment
- **Public Subnets**: ALB and NAT Gateway
- **Private Subnets**: ECS services and RDS
- **Security Groups**: Network access control
- **ECS Fargate**: Serverless container hosting
- **RDS**: Managed database service
- **OpenSearch**: Managed search service
- **S3**: Object storage for files and artifacts
- **Lambda**: Serverless compute for automation
- **Secrets Manager**: Secure credential storage

### Cost Optimization Tips
- Use `t3.micro` or `t3.small` for development
- Enable S3 lifecycle policies
- Set up CloudWatch billing alerts
- Delete unused resources regularly
- Use Reserved Instances for production RDS
- Enable ECS Fargate Spot for non-critical workloads

### Security Considerations
- Rotate AWS credentials regularly
- Use least privilege IAM policies
- Enable VPC Flow Logs
- Monitor CloudTrail logs
- Encrypt RDS at rest and in transit
- Use Secrets Manager for all credentials
- Enable AWS WAF on ALB
- Regular security group audits

### Support
For issues or questions:
1. Check CloudFormation events in AWS Console
2. Review CloudWatch logs
3. Consult AWS documentation
4. Contact your AWS support team

---

## 📋 Deployment Checklist

Use this checklist to track your deployment progress:

### Phase 1: Foundation Infrastructure
- [ ] Networking Stack
- [ ] S3 Stack
- [ ] Secrets Manager Stack
- [ ] Load Balancer Stack

### Phase 2: Data Layer
- [ ] RDS Stack
- [ ] Update RDS master password
- [ ] Clone datahub-development repository
- [ ] Add IP to RDS security group
- [ ] Deploy database schema
- [ ] Update Secrets Manager (RDS credentials)
- [ ] OpenSearch Stack
- [ ] Update Secrets Manager (OpenSearch credentials)

### Phase 3: Monitoring & DNS
- [ ] CloudWatch Stack
- [ ] Route53 Stack (optional)
- [ ] SQS Stack

### Phase 4: Container Registry
- [ ] ECR Stack
- [ ] Build & push Entity Service image
- [ ] Build & push Search Service image
- [ ] Build & push User Service image
- [ ] Build & push Submission Service image
- [ ] Build & push Report Service image
- [ ] Build & push Download Service image
- [ ] Build & push Frontend image

### Phase 5: Application Layer
- [ ] ECS Stack
- [ ] Verify ECS services are running

### Phase 6: Serverless Layer
- [ ] SES Stack
- [ ] Verify individual email addresses (datahub@stanford.edu, datahub.dev@stanford.edu)
- [ ] Verify domain identity (stanford.edu) - add DNS records
- [ ] Request production access (production only)
- [ ] Build & upload OpenSearch Lambda
- [ ] Build & upload Email Service Lambda
- [ ] Build & upload Publication Script Lambda (if applicable)
- [ ] Create psycopg2 Lambda layer
- [ ] Lambda Stack
- [ ] Initialize OpenSearch indices
- [ ] EventBridge Stack

### Phase 7: Verification
- [ ] Test application endpoints
- [ ] Check ECS service health
- [ ] Monitor logs
- [ ] Verify all stacks are CREATE_COMPLETE

---

**🎉 Congratulations! Your DataHub application is now deployed on AWS!**
