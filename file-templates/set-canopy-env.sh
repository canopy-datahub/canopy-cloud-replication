#!/bin/bash

unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY
unset AWS_SESSION_TOKEN

export AWS_PROFILE=canopy-dev
export AWS_REGION=us-east-1


unset CANOPY_ENV
unset CANOPY_HOME
unset CANOPY_PROJECT_NAME

export CANOPY_ENV=dev
export CANOPY_HOME=~/CANOPY
export CANOPY_CLOUD_REPLICATION=${CANOPY_HOME}/canopy-cloud-replication
export CANOPY_AWS_PARAMETER_FILE=${CANOPY_HOME}/aws-parameters-${CANOPY_ENV}-user.json
export CANOPY_PROJECT_NAME=$(cat ${CANOPY_AWS_PARAMETER_FILE} | grep -o '"ProjectName": "[^"]*"' | cut -d'"' -f4)
export CANOPY_UNIQUE_ID=$(cat ${CANOPY_AWS_PARAMETER_FILE} | grep -o '"DataHubUniqueId": "[^"]*"' | cut -d'"' -f4)

alias gocanopy='cd $CANOPY_HOME'
alias canopycli='source $CANOPY_HOME/canopy-cli/cli.sh'

# Uncomment this for local development
# source ${CANOPY_HOME}/canopy-profile-native-develop.sh

echo ""
echo "Environment     : $CANOPY_ENV"
echo "Project Home    : $CANOPY_HOME"
echo "Project Name    : $CANOPY_PROJECT_NAME"
echo "Canopy Unique Id: $CANOPY_UNIQUE_ID"
echo "AWS Profile     : $AWS_PROFILE"
echo "AWS Region      : $AWS_REGION"
echo ""
