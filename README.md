AZURE PIPELINE CUSTOM TEMPLATES - REACT :rocket:
=
---

<img src="https://colorlib.com/wp/wp-content/uploads/sites/2/react-dev-tools-logo.jpg" width="300">

# Introduction:
This repository contains an Azure Pipeline for a React application. We are going to walk through the steps of setting up any React application by:
- [Installing Node](#installing-node)
- [Configuring SonarQube](#configuring-sonarqube)
- [Publishing Application Package](#publishing-application-package)
- [Building Docker Image](#building-docker-image)
- [Deploying With helm](#deploying-with-helm)

Before we get started, be sure to have your ```azure-pipelines.yml``` file in the root of your project as shown in [Templates](https://dev.azure.com/AFS-CTO/Modern%20Custom%20Dev/_git/Templates?path=%2FREADME.md&version=GBmaster).
The way that we are going to set up our ```azure-pipelines.yml``` file is with jobs, steps, and templates. Each job has a unqiue name to represent
what it does and a pool which sets the type of machine that you want your pipeline to run on. Each job also has steps, where we list out the tasks
for the job to complete. In our case, we have templated out the tasks so that they could be reused over and over again. If you navigate to the
Templates repository mentioned above, you can take a look at what they look like. Each template contains a list of default parameters and a task. 
We will be referencing these templates in our own pipeline and passing in parameters to override some of the default values. Lets get started with
building out our pipeline!

### *Note: All of these steps are not required, you can pick and choose the ones you see fit for your project and pipeline.*

##(Job: BuildTestScan)
## Installing Node
This is the first job of three in this pipeline. In this job, we are going to install Node, install npm, run tests/build, and configure
SonarQube. As mentioned above, each job requires a job name, pool, and steps. Within the steps section we are going to be referencing our 
first template, `node-with-params.yml@Templates`. This template contains a task that installs Node and a bash script that runs `npm install`, 
`npm test`, and `npm run build`.
```
jobs:
  - job: BuildTestScan
    pool:
      vmImage: $(vmImage)
    steps:
      # Node Install
    - template: node-with-params.yml@Templates
```

## Configuring SonarQube
After we run our integration tests, we want to configure SonarQube so that we can publish our test results. In order to do this, we call
`sonarqubePrepare-with-params.yml@Templates` and pass the required `configFile` parameter. Once SonarQube is successfully prepared, we 
then call `sonarqubeAnalyze-with-params.yml@Templates` that analyzes the quality measures and issues of the code and publishes the test 
results to the specified SonarQube project.
```
      # SonarQube Prepare
    - template: sonarqubePrepare-with-params.yml@Templates
      parameters:
        configFile: 'sonar-project.properties'

      # SonarQube Analyze
    - template: sonarqubeAnalyze-with-params.yml@Templates
```

##(Job: PublishArtifacts)
## Publishing Application Package
This is the second job of three in this pipeline. In this job, we are publishing the project package to Azure DevOps Artifacts and 
building a Docker Image. We see a new command with `dependsOn`, which just tells this job to wait until the prior job completes. We call
the `npm-with-params.yml@Templates` and pass in required parameters `workingDir` which is the path to the folder that `package.json` exists in,
`publishRegistry` which describes that you want to use Azure Artifacts feed or an external registry, and `publishFeed` which the name of
the feed that you want to publish to.
```
  - job: PublishArtifacts
    pool:
      vmImage: $(vmImage)
    dependsOn:
        - BuildTestScan
    steps:
      # NPM Publish
    - template: npm-with-params.yml@Templates
      parameters:
        workingDir: './'
        publishRegistry: 'useFeed'
        publishFeed: 'SpringAPI'
```

## Building Docker Image
Now that the application has been built, tested, and scanned, we can now build a Docker image for it. All we need to do to build the image is
call `docker-with-params.yml@Templates` and make sure your Dockerfile is at the root level. This will build your Docker image and push it to
the specified Docker registry. (*Note: You need to make sure you have DOCKER_HOST_URL, DOCKER_USERNAME, and DOCKER_PASSWORD set in your 
pipeline variables*).
```
      # Install Docker And Build Docker Image
    - template: docker-with-params.yml@Templates
```

##(Job: Deploy)
## Deploying With Helm
This is the third and final job in this pipeline. In this job, we are setting the Docker Image tag variable and then deploying our 
application with helm. When we call `helm-with-params.yml@Templates`, it requires three parameters, `chartPath`, `releaseName`, and `valueFile`. 
The template will create a Kubernetes cluster, set up the environment specified in the `charts/react` folder, and create the load balancer 
specified in the `config/dev/react.yml` file. Once this job completes, you should be able to go check your Kubernetes provider, see a running 
cluster, and navigate to your domain to find your running application.
```
  - job: Deploy
    pool:
      vmImage: $(vmImage)
    dependsOn:
        - PublishArtifacts
    steps:
      # Set Docker Image Tag Variable
    - bash: |
          export GIT_COMMIT=$(git rev-parse HEAD)
          echo "##vso[task.setvariable variable=git_commit]$GIT_COMMIT"

      # Helm Upgrade
    - template: helm-with-params.yml@Templates
      parameters:
        chartPath: 'charts/react'
        releaseName: 'react1'
        valueFile: 'config/dev/react.yaml'
```

### You can reference the full example of the React azure-pipelines.yml file [here](https://dev.azure.com/AFS-CTO/Modern%20Custom%20Dev/_git/React?path=%2Fazure-pipelines.yml&version=GBmaster).


# Pipeline Setup
Now that you have completed your `azure-pipelines.yml` file, you can create the pipeline. 
1. Select **Pipelines**
2. Select **New** > **New build pipeline**
3. Select **Azure Repos Git**
4. Select **Repository Name**
5. Select **Existing Azure Pipelines Yaml File** 
6. Select **Branch** > **Path** 
7. Select **Variables** > Create DOCKER_HOST_URL, DOCKER_USERNAME, DOCKER_PASSWORD
8. **Run**


# Conclusion
After going through the `azure-pipelines.yml` file together, you should have a better understanding of how to work with custom templates to
build a pipeline specifically for your project. There are some great resources that you can reference for more information about building out
pipeline templates and tasks:
- [Azure Pipeline Templates](https://docs.microsoft.com/en-us/azure/devops/pipelines/process/templates?view=azure-devops)
- [Azure Pipeline Tasks](https://docs.microsoft.com/en-us/azure/devops/pipelines/process/tasks?view=azure-devops&tabs=yaml)

---