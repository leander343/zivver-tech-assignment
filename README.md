# zivver-tech-assignment
## Tech assignment for DevOps role 

This assignment involves 

* Create infrastructure to host content
* Pipeline to deploy content 

## Requirements 

1. AWS IAM user account with sufficient permissions to create the following resources: 
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

2. Github token: A Github fine-grained access token with repository permission to set variables.

3. S3 bucket and Dynamo DB need to be created before the infrastructure workflow is run. 


## Steps to run remote state 

1. Install AWS CLI, and run AWS configure to add access and secret key. 
2. Install Terraform CLI 
3. Run terraform plan to view changes 
4. Run terraform apply to create S3 bucket and Dynamo DB 

## Local
### Steps to deploy Infrastructure from local
1. Install AWS CLI, and run AWS configure to add access and secret key. 
2. Add the value of GITHUB_TOKEN to the shell environment 
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
4. Run terraform plan to view changes 
5. Run terraform apply to create the infrastructure
6. Run terraform destroy to clean up when done 


### Steps to deploy content from local
1. Install Docker and AWS CLI
2. Run `AWS configure` to set the secret key and access key
2. Get the ECR repository URL, can be found under ECR service in management console 
```
https://<Account ID>.dkr.ecr.<region>.amazonaws.com/<repo-name>:<tag>
```
3. Login to ECR 
```
aws ecr get-login-password --region <region> | docker login --username AWS --password-stdin <repository-url>
```
3. Navigate to the ziv-app folder and run the following command to build the docker image 
```
docker build -t <repository-url>:latest .
```
4. Push the image to ECR registry  
```
docker push <repository-url>:latest
```

5. Update task revision with a new image and register it 

```
TASK_DEFINITION=$(aws ecs describe-task-definition --task-definition <family> --region <region>)

NEW_TASK_DEFINTIION=$(echo $TASK_DEFINITION | jq --arg IMAGE "<Image-name>" '.taskDefinition | .containerDefinitions[0].image = $IMAGE | del(.taskDefinitionArn) | del(.revision) | del(.status) | del(.requiresAttributes) | del(.compatibilities)|del(.registeredAt)|del(.registeredBy)')

aws ecs register-task-definition --region <region> --cli-input-json "$NEW_TASK_DEFINTIION"
```
6. Force a new deployment with a new task revision
```
aws ecs update-service --cluster $CLUSTER_NAME --service $SERVICE_NAME --task-definition zivvy-app --force-new-deployment
```

## Github workflow

### Setup Variables 

1. In the repo page, go to Settings > Secrets and Variables > Actions 
2. Under Repo secrets  fill in the following : 
   - AWS_SECRET_ACCESS_KEY with Secret key associated with IAM user account 
   - AWS_ACCESS_KEY_ID with Access key associated with IAM user account
   - GT_TOKEN with Fine-grained GitHub token 
3. Under the Repo variables tab, fill in the following: 
   - BUCKET_NAME with S3 bucket name 
   - DYNAMODB_NAME with Dynamo DB name 
  Once these values are set, this should be enough to run the 'Deploy ECS infrastructure'   workflow 

### Deploy infrastructure required to host ECS 

Under the Actions tabs, select 'Deploy ECS infrastructure workflow' > 'Run Workflow'. 


### Deploy content to ECS

Under Actions tabs, select 'Deploy to Amazon ECS' > 'Run Workflow' 

###  Detroy and clean up Infrastructure 

Under Actions tabs, select 'Destroy ECS infrastructure' > 'Run Workflow' 


When the ECS infrastructure workflow is run, it subsequently triggers an ECS deployment workflow to deploy the app image replacing the dummy nginx image deployed using Terraform. 

Opening the ECS infrastructure deploy job, which if successful should display the load balancer URL at the end of the terraform apply step, or it can be found in the AWS account under the load balancers tab. 

