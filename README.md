# EE Assignment Statement-1

This code is applicable for the EE assignment (statement-1) only

## Getting Started

Included files:
```
main.tf             - Contains the terraform code for creating and configuring the given AWS infra
variables.tf        - Contains declared list of input variables for main.tf
outputs.tf          - Provides infra details once it is deployed
install_docker.yaml - Single ansible playbook used to install docker-ce
```

### Prerequisites

Following is the list of pre-requisites
1. Terraform
2. SSH key-pair (RSA format) `ssh-keygen -t rsa`
3. AWS Access key and Secret, Ubuntu 18.04 AMI 

### Installing

1. Make sure you have all the pre-requisites mentioned
2. Clone this repo
3. Navigate to the repo and execute following commands

```
terraform init

terraform plan

#Provide all the required parameters mentioned in below command
terraform apply -var="aws_access_key=<AWS-ACCESS-KEY>" -var="aws_secret_key=<AWS-SECRET>" -var="aws_region=<AWS-REGION>" -var="ubuntu_ami=<AMI-ID>" -var="public_key_path=<PUBLIC KEY PATH>" -var="private_key_path=<PRIVATE KEY PATH>" -var="docker_playbook_path=<DOCKER PLAYBOOK PATH>"
```