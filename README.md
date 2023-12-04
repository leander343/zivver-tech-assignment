# Zivver DevOps assignment
## Tech assignment for DevOps role 

This assignment involves 

* Creating infrastructure to host content
* Pipeline to deploy content 

Terraform is used to provision the infrastructure and Github actions for CI/CD

##  Requirements to run project

1. **AWS IAM user account** with sufficient permissions to create the following resources: 
   For infrastructure: 
   * Virtual private network
   * Elastic load balancer
   * Elastic container service
   * Elastic container registry
   * Security groups 
   * EC2 
   For remote state: 
   * S3
   * Dynamo DB

For testing purposes, it's best to just use an account with administrator access. The access key and the secret key from this user account are required. 

2. **Github token**: A Github fine-grained access token with repository permission to set variables. Documentation on how to create one can be found [here](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens)

3. **S3 bucket** and **Dynamo DB** need to be created before the infrastructure workflow is run. 


## Steps to run remote state 

1. Install AWS CLI, and run AWS configure to add access and secret key. 
2. Install Terraform CLI 
3. Run `terraform plan` to view changes 
4. Run `terraform apply` to create S3 bucket and Dynamo DB 

## Local
### Steps to deploy Infrastructure from local
1. Install AWS CLI, and run AWS configure to add access and secret key. 
2. Add the value of **GITHUB_TOKEN** to the shell environment 
   ```
   export GITHUB_TOKEN = <token-value>
   ```
3. Create a file called backend.tf in the terraform folder with the following config, 
   ```
   terraform {
    backend "s3" {
     bucket         =  <bucket-name>
     key            =  <key-to-store-state-in>
     region         =  <region>
     dynamodb_table =  <lock-table>
     }
    }
   ```
4. Run `terraform plan` to view changes 
5. Run `terraform apply` to create the infrastructure
6. Run `terraform destroy` to clean up when done 


### Steps to deploy content from local
1. Install Docker, jq and AWS CLI
2. Run `AWS configure` to set the secret key and access key
3. Get the **ECR repository URL**, can be found under ECR service in management console 
```
https://<Account ID>.dkr.ecr.<region>.amazonaws.com/<repo-name>:<tag>
```
4. Login to ECR 
```
aws ecr get-login-password --region <region> | docker login --username AWS --password-stdin <repository-url>
```
5. Navigate to the ziv-app folder and run the following command to build the docker image 
```
docker build -t <repository-url>:latest .
```
6. Push the image to ECR registry  
```
docker push <repository-url>:latest
```

7. Update task revision with a new image and register it 

```
TASK_DEFINITION=$(aws ecs describe-task-definition --task-definition <task-family> --region <region>)

NEW_TASK_DEFINTIION=$(echo $TASK_DEFINITION | jq --arg IMAGE "<Image-name>" '.taskDefinition | .containerDefinitions[0].image = $IMAGE | del(.taskDefinitionArn) | del(.revision) | del(.status) | del(.requiresAttributes) | del(.compatibilities)|del(.registeredAt)|del(.registeredBy)')

aws ecs register-task-definition --region <region> --cli-input-json "$NEW_TASK_DEFINTIION"
```
8. Force a new deployment with a new task revision
```
aws ecs update-service --cluster <cluster-name> --service <service-name> --task-definition <task-family> --force-new-deployment
```

## Github actions workflow

### Setup Variables 

1. In the repo page, go to Settings > Secrets and Variables > Actions 
2. Under Repo secrets  fill in the following : 
   - **AWS_SECRET_ACCESS_KEY** with Secret key associated with IAM user account 
   - **AWS_ACCESS_KEY_ID** with Access key associated with IAM user account
   - **GT_TOKEN** with Fine-grained GitHub token 
3. Under the Repo variables tab, fill in the following: 
   - **BUCKET_NAME** with S3 bucket name 
   - **DYNAMODB_NAME** with Dynamo DB name 
  Once these values are set, this should be enough to run the 'Deploy ECS infrastructure'   workflow 
4. Running the infrastructure workflow should create the required variables for the ECS deploy workflow. 

### Deploy infrastructure required to host ECS 

Under the Actions tabs, select **Deploy ECS infrastructure workflow** > **Run Workflow** 

Select the check box for **Terraform initial run** if the workflow is provisioning the infrastructure fresh from scratch. This is required to run the ECS deploy pipeline to replace the image in the task definition.

### Deploy content to ECS

Under Actions tabs, select **Deploy to Amazon ECS** > **Run Workflow** 

###  Detroy and clean up Infrastructure 

Under Actions tabs, select **Destroy ECS infrastructure** > **Run Workflow** 


### How it works 

When the ECS infrastructure workflow is run with 'Terraform initial run' checked, it subsequently triggers the ECS deployment workflow to deploy the app image replacing the dummy nginx image Terraform deployed with. This is not required for consequetive runs of the workflow once infrastructure is deployed.

Any changes made to the terraform or app folder will only then trigger the respective workflows.  

Opening the ECS infrastructure workflow and then the terraform job, which if successful should display the load balancer URL at the end of the terraform apply step, or it can be found in the AWS account under the load balancers tab. 


# Notes on assignment evaluation parameters and improvements

## Terraform 

-  In the case of Terraform, the code can be split up into modules and replace hardcoded values adhering to DRY principles.


## CI/CD

- The first run of the infrastructure workflow has to be done manually due to having to set a variable required to trigger another workflow.

- Right now a task definition with a dummy image is deployed on the initial setup and it takes a while before the CI replaces the image on the initial setup. 
 
- Tap more into using reusable workflow and deploying to different environments.

- More tests in place for the various workflows.

- Splitting up current workflows into broader jobs so it's easier to manage failed jobs. 

-  An alternative solution to prevent having to run the initial setup manually is to separate the creation of the ECR repository from the rest of the infrastructure might. This could give way to a  workflow or a pipeline that can be triggered to create a task definition every time there's a new image push. This can used as a data source by Terraform and also be used to redeploy the ECS service. 

## Security 

- While we use IAM user account/role administrator access for testing, it's best to audit policies and add just enough permissions required. 

- Adding in a step to test the vulnerability of the container image.

- Docker image can be setup to run as a non-root user.

- While secrets aren't used for containers yet, they have to be securely passed into the container. 

- Encrypting the S3 bucket that the state is stored in and having a restrictive bucket policies.

## Availability & Scalability

- Auto-scaling policies are in place to horizontally scale the containers in case they reach a specific metric percentage in usage, this can further be tweaked based on further monitoring traffic and usage. 

- Fargate makes it less complicated to deploy to and is generally better in terms of availability in comparison to an EC2 scaling group. It also takes care of automatically spreading out the tasks to multiple subnets. 

- Setup rollbacks so that any failing changes can be rolled back to prevent any downtime.

- In case there is a necessity to recreate the cluster and redeploy the task definition, it can affect the service availability.



## Monitoring 

- Containers are currently setup with cloud watch logs, this can help with debugging in case there are any errors. 

- Health checks and cloud watch alarms can be setup to notify in case there are any incidents. 

- Monitor the CPU and Memory utilization metrics of services and containers, this can help with identifying if the containers need to be vertically scaled. Enabling container insights might be useful as well.

