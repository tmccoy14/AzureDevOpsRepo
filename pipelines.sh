#!/bin/bash

# This script will configure an Azure Devops Pipeline
pipeline_name=$1
yaml_path=azure-pipelines.yml
git_url=$(git config --get remote.origin.url)

if [[ $git_url == *"dev.azure.com"* ]]; then
  organization="https://$(echo $git_url | cut -d'/' -f 3)"
  project=$(echo $git_url | cut -d'/' -f 5)
  repository=$git_url
  branch=$(git branch | grep \* | cut -d ' ' -f2)
fi

# DOCKER_HOST_URL=afsdigitalstudio-docker.jfrog.io
# DOCKER_USERNAME=comet-bot
# DOCKER_PASSWORD=AKCp5e2qZyVdrD8VgFrMMGsntCLREzRYGbzMYMjr4NT4WvRvDk7C8PM2dnHAXqfJSDUGwWTLE

# install azure-devops extension
az extension add --name azure-devops

# show azure-devops extension
az extension show --name azure-devops

# configure Azure Devops defaults for organization and project
az devops configure --defaults organization=$organization project=$project

# create pipeline
az pipelines create --name $pipeline_name --repository $repository --branch $branch \
 --yaml-path $yaml_path

# # create pipeline variables
# az pipelines variable create --name "DOCKER_HOST_URL" --value $DOCKER_HOST_URL \
# --pipeline-name $pipeline_name --secret "true" 

# az pipelines variable create --name "DOCKER_USERNAME" --value $DOCKER_USERNAME \
# --pipeline-name $pipeline_name --secret "true" 

# az pipelines variable create --name "DOCKER_PASSWORD" \
# --value $DOCKER_PASSWORD --pipeline-name $pipeline_name --secret "true" 
