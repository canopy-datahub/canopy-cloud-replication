#!/bin/bash

unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY
unset AWS_SESSION_TOKEN

export AWS_PROFILE=canopy-<<CANOPY_ENV>>-<<USERNAME>>
export AWS_REGION=us-east-1
export AWS_PAGER=""


unset CANOPY_ENV
unset CANOPY_HOME
unset CANOPY_PROJECT_NAME

export CANOPY_ENV=<<CANOPY_ENV>>
export CANOPY_HOME=<<CANOPY_HOME>>
export CANOPY_CLOUD_REPLICATION=${CANOPY_HOME}/canopy-cloud-replication
export CANOPY_AWS_PARAMETER_FILE=${CANOPY_HOME}/aws-parameters-${CANOPY_ENV}-${USERNAME}.json
export CANOPY_PROJECT_NAME=$(cat ${CANOPY_AWS_PARAMETER_FILE} | grep -o '"ProjectName": "[^"]*"' | cut -d'"' -f4)
export CANOPY_DEPLOYMENT_ID=$(cat ${CANOPY_AWS_PARAMETER_FILE} | grep -o '"DeploymentId": "[^"]*"' | cut -d'"' -f4)

alias gocanopy='cd $CANOPY_HOME'
alias canopycli='source $CANOPY_HOME/canopy-cli/cli.sh'

# Uncomment this for local development
# source ${CANOPY_HOME}/canopy-profile-native-develop.sh

echo ""
echo "Environment          : $CANOPY_ENV"
echo "Project Home         : $CANOPY_HOME"
echo "Project Name         : $CANOPY_PROJECT_NAME"
echo "Canopy Deployment Id : $CANOPY_DEPLOYMENT_ID"
echo "AWS Profile          : $AWS_PROFILE"
echo "AWS Region           : $AWS_REGION"
echo ""
