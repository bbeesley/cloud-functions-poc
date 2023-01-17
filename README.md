# cloud-functions-poc
[![Build, Test & Release 🧪🚀](https://github.com/bbeesley/cloud-functions-poc/actions/workflows/build-test-on-push.yml/badge.svg)](https://github.com/bbeesley/cloud-functions-poc/actions/workflows/build-test-on-push.yml) [![semantic-release: angular](https://img.shields.io/badge/semantic--release-angular-e10079?logo=semantic-release)](https://github.com/semantic-release/semantic-release) [![Commitizen friendly](https://img.shields.io/badge/commitizen-friendly-brightgreen.svg)](http://commitizen.github.io/cz-cli/)

## description

Example repository to demonstrate building, publishing and deploying a service in GCP from GitHub Actions using terraform for infrastructure as code.

## resources

The repo contains two services, one of them a basic rest api that runs from cloud functions, the other a fortune cookie api that returns, erm, fortunes, and runs as a docker container in cloud run.

### api

The api code is can be found in `packages/api`. It just contains code, which is built using `tsc` and then zipped up and pushed to google cloud storage in the common build/test/publish workflow. The terraform for this service can be seen [here](terraform/service/api.tf).

### fortune

The code for the fortune api can be found in `packages/fortune-nodejs`. It contains code and a Dockerfile. This time it gets built using docker and tsc and then gets published to google container registry from where it can be deployed to cloud run. The terraform for this service can be seen [here](terraform/service/api.tf).

## workflows

There are a number of workflows in this repo, but the most relevant are the `build-test-*.yml` and `*deployment.yml` workflows. The wildcards are there because each of these tasks is composed from more than one workflow. I'll drill into the detail a little here.

### Build, Test, & Release

These workflows do what you would expect probably. They build the services, run tests, publish artifacts, and trigger a deployment if the commit is going onto the main branch.

#### Build & Test Common

This is a shared workflow that does the bulk of the work. It builds, tests, publishes docker images and pushes cloud functions zips to cloud storage. Additionally it runs a terraform plan for each environment (only one env is actually configured to make life easier on me). That's all there is to it really. Note that versioning happens prior to publishing artifacts to ensure stuff like service versions are updated in the published assets.

#### Build & Test PR

This workflow is triggered on the `pull_request_target` event, which gets triggered when a PR is created or modified. The reason for using `pull_request_target` instead of `pull_request` is due to security concerns. You can read more detail [here](https://securitylab.github.com/research/github-actions-preventing-pwn-requests/) but essentially it always uses the ref for the main branch instead of the PR branch, meaning malicious assholes cant modify the workflows to leak secrets. We do still pull the source code from the head of the PR branch to run tests and publish assets though. The only extra little bit this workflow does is detect PRs from dependabot and auto merge them if the build and tests are all passing. Aint nobody got time to be approving every dependency bump. Builds from this workflow don't create releases or tags, but they do publish artifacts in case you wanna try deploying your stuff to a dev environment before merging it to `main`.

#### Build, Test & Release

This workflow is triggered on the `commit` event, but only runs when the commit is on the main branch. It does all everything in the common workflow, but this time it actually creates tags/releases. We're using semantic release, so the new version is defined based on the commits since the last release, so you need to follow the conventional commit format. You can read more about it [here](https://github.com/semantic-release/semantic-release). Worth noting that the versions are per service, so the api and the fortune thing each have their own version, and changes to one service dont result in version bumps on the other. After all that stuff is done the workflow automatically triggers a deployment to the dev environment (which is also the prod environment in this repo, but theres no need to get pedantic).

### Triggering Deployments

We're running deployments using github's deployment mechanism. This is nice because it means you can see which environments we've deployed to and which versions are deployed there right in the github UI. You can also do some cool stuff where you dont allow PRs to be merged until a branch has been successfully deployed somewhere. I'm not doing that here though since only one env. The only annoying thing about github deployments is that you can't manually trigger them, which is why deployment stuff is actually split into 2 workflows here. Read on if you're still awake and want more info.

#### Manual Deployment Trigger

Yep, you cant trigger a deployment from the ui, but you can trigger a manual workflow and pass it some params. So this workflow takes 2 args, a ref which can be a branch name or commit ref, and an environment name. The workflow just reads those inputs, does some basic validation on them, then triggers the deployment using the github api.

#### Deployment

This workflow runs on the deployment event, which gets triggered by api calls (as mentioned on the manual deployment description above). It receives the reference and environment name as inputs and then does some stuff. The first job, `set-config` is a bit of a hack. Github actions doesn't have a great way of parametrising config, so in order to define things like which secrets, projects, whatever else to use for each environment, we have the set config job. The job has outputs, and a step for each environment. Only the step for the environment we're deploying to will run, and it will set the outputs for the job with the config for that environment. Its not super pretty, but its the best I've got until environment config support improves in github action.

Next comes the actual deployment stuff. We check out the ref that was passed as an input and authenticate with gcp then we do:

* terraform plan service - this does a terraform plan for the service infrastructure. These are the resources which are regional, and which you may want to deploy multiple instances of for resilience in the event of an outage in one region. The plan is saved to an output file.
* terraform apply service - this step just applies the plan created in the previous step, creating or updating resources.
* terraform plan routing - this does the same thing as the service plan, but for the routing resources. Routing resources are bits of global infrastructure with you wouldn't have multiple instances of. Think dns records, CDNs, global cloud load balancers. Again, we save the plan to an output file.
* terraform apply routing - I think you can guess what this step does, it applies the plan we just created for the routing infrastructure.

Once this stuff has all happened, or in fact, even if it hasn't happened, we report the status of the deployment back to github as either succeeded, failed, or cancelled. This lets github track what has been deployed and where.

## terraform

The terraform files and config for this project live in the creatively named `terraform` directory. Within there its broken down by the type of resource, for reasons I hinted at above, and will give more detail on below. Each directory that we can deploy has a config folder containing variable config and remote back end config for each environment.

### routing

The routing directory contains all the global resources. These are things like DNS entries, global cloud load balancers, and CDNs. These are not coupled to a specific region or data centre and generally cant have a global outage (I hope I don't get proved wrong on that). We deploy this once and it covers all other resources.

### service

The service directory contains all the regional resources for the service. This means stuff like functions, cloud run services, databases, queues, streams, etc etc etc. You can deploy it on it's own to a single region and the routing will handle that. Alternatively you can use it as a module and deploy it multiple times for multiple regions, again the routing should handle that and load balance traffic across all active healthy regions.

### deployment

The deployment directory is basically a meta plan. When deploying your service to multiple regions, from within this directory you import the service directory as a module, then create an instance of it for each region you want to deploy to.
