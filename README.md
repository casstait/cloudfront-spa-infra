# Cloudfront-SPA-Infra

Infrastructure in this repository is deployed via the IaC tool [Terraform](https://developer.hashicorp.com/terraform).

This repository provides examples of provisioning a static single page application (SPA) on AWS via S3 only (in working directory `s3-spa`) or a more productionized solution via Cloudfront and S3 (in directory `cdn-s3-spa`).

## Pre-requisites

Terraform must be installed on the machine running to provision infrastructure for the workspace.

To install Terraform on your machine follow the [recommended guidance](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli). 

An AWS account must also be available to deploy this repositories resources into. The role used to deploy resources should have permissions to deploy required resources into the account.

Account credentials are not supplied to this repository. For production environments, OIDC roles should be made available for JIT credentials to deploy resources with terraform from repositories.

## Steps to Provision

1. Before provisioning any infrastructure, be sure to read the `README.md` in each directory to fully understand what infrastructure will be deployed.
2. In a terminal of choice, export the following AWS credentials into your console:

```bash
export AWS_ACCESS_KEY_ID=<access_key_id_from_account>
export AWS_SECRET_ACCESS_KEY=<access_secret_access_key_from_account>
export AWS_SESSION_TOKEN=<access_session_token_from_account>
export AWS_REGION=ap-southeast-1
```

3. In a terminal of choice, navigate to either the `s3-spa` directory or the `cdn-s3-spa` directory.
4. Run the following terraform commands in your terminal:

```terraform
$ terraform init      # Initializes the terraform workspace (currently uses a local backend)  
$ terraform plan      # Presents a plan of the resources that will be deployed
$ terraform apply     # Deploys the workspace infrastructure
```