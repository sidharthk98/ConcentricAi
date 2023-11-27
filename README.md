# Terraform Project Structure

The Terraform project is split into two parts:

1. **./:** This folder holds the code for cloud offerings like VPC, service account, and the GKE cluster.

## Prerequisites

Install the following tools to execute the commands:

- Terraform
- AWS CLI (`aws`)
- Kubernetes CLI (`kubectl`)

Export the aws project id

- `export TF_VAR_project_id="<project_id>"` This is used for all the Terraform actions
- `export AWS_PROJECT="<project_id>"` This again is used by Terraform for any api imports

## Set Up and Deployment

1. To apply the project, set up the Aws credentials using `aws configure` and change the 
`~/.aws/credentials` file 

2. Run `terraform init` from `infra/` to install the provider packages.

    ```bash
    cd infra/
    terraform init
    ```

3. Run `terraform plan` to visualize the changes that are supposed to happen and validate them across the Terraform modules.

    ```bash
    terraform plan
    ```

4. Finally, run `terraform apply` to apply the changes, which should create the infrastructure on your GCP console.

    ```bash
    terraform apply
    ```

