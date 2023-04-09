# Week 6 — Deploying Containers

## Implementing Health Checks
### RDS
- We want to make sure RDS is accsible from the docker container without using `psql` command, because it won't be installed there.
- So we make python script to check connection here `backend-flask/bin/db/test`

### Flask Container
- Created Health Check endpoint in `app.py`.
- Made a script using python and `request` library. (hard but safer)
- **IMPORTANT**: Don't use `curl` and `wget` because if your container got hacked, it will be easy for hackers to install bad things.
- Edit Dockerfile to have `python:3.10-slim-buster` image and `FLASK_DEBUG=1` because the old ENV is deprecated.

> Check commit details [here](https://github.com/AbdassalamAhmad/aws-bootcamp-cruddur-2023/commit/368b252fb03f337c570b71120b3d3969d90bcc93)

## Create CloudWatch Log Group
```bash
aws logs create-log-group --log-group-name "cruddur"
aws logs put-retention-policy --log-group-name "cruddur" --retention-in-days 7
```

## Create ECS Fargat Cluster
- When creating a cluster, a namespace automatically will be created. So we set the name of it.
- Namespace is related to AWS Cloud Map.
```bash
aws ecs create-cluster \
--cluster-name cruddur \
--service-connect-defaults namespace=cruddur
```

## Gaining Access to ECS Fargate Container
### Create ECR Repo and Push Image
- The reason for using ECR (I think) is because we don't want to rely on Docker Registry for pulling our images.
### Login to ECR
```bash
aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com"
```

### Create a Repo for Base-Python
```bash
aws ecr create-repository \
  --repository-name cruddur-python \
  --image-tag-mutability MUTABLE
```

```sh
# Set URL
export ECR_PYTHON_URL="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/cruddur-python"
echo $ECR_PYTHON_URL
```
```sh
# Pull Image
docker pull python:3.10-slim-buster
# Tag Image
docker tag python:3.10-slim-buster $ECR_PYTHON_URL:3.10-slim-buster
# Push Image
docker push $ECR_PYTHON_URL:3.10-slim-buster
```

### Create a Repo for Backend-Flask
```bash
aws ecr create-repository \
  --repository-name backend-flask \
  --image-tag-mutability MUTABLE
```

```sh
# Set URL
export ECR_BACKEND_FLASK_URL="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/backend-flask"
echo $ECR_BACKEND_FLASK_URL
```

```sh
# Build Image
docker build -t backend-flask .
# Tag Image
docker tag backend-flask:latest $ECR_BACKEND_FLASK_URL:latest
# Push Image
docker push $ECR_BACKEND_FLASK_URL:latest
```
## Create a Service in ECS
- In order to create a Service we have to Register a Task Definition first.
## Register Task Defintions
- **Note**: The difference between service and tasks in ECS Cluster is: service continuously running, task once it finished it kills itself.
- When defining Task definition, don't create two containers in the same task, because we want to scale out. In that way the contaienrs are not coupled together.
- Before creating The Task Definition, we have to create secrets (parameters) , `executionRoleArn`, and `taskRoleArn`.

### Create Execution Role (for ECS) using UI because we will use CloudFormation in the Future Instead.
- We created a role that allow ECS to do some tasks.
![1](https://user-images.githubusercontent.com/83673888/230764996-7c877aa6-be46-4db9-b3d2-37261025b797.png)

- The Role should have a policy (Policy add permissions to the role to be able to perform the required task)
![2](https://user-images.githubusercontent.com/83673888/230765015-c369a156-fb3f-4169-91f0-d96e1c1ae81b.png)

- Name the Policy. CruddurServiceExecutionPolicy
![3](https://user-images.githubusercontent.com/83673888/230765019-cf035ccf-3fa3-412d-87e6-8c47e48f4938.png)

- Name the Role CruddurServiceExecutionRole 
![4](https://user-images.githubusercontent.com/83673888/230765023-4603fe2d-b180-4475-ae99-06cee5d7cd85.png)

### Create Task Role using CLI (task role is for containers)
- Create the role and add ECS to do the task (there is no permessions yet) 
```sh
aws iam create-role \
    --role-name CruddurTaskRole \
    --assume-role-policy-document "{
  \"Version\":\"2012-10-17\",
  \"Statement\":[{
    \"Action\":[\"sts:AssumeRole\"],
    \"Effect\":\"Allow\",
    \"Principal\":{
      \"Service\":[\"ecs-tasks.amazonaws.com\"]
    }
  }]
}"
```
- Add first policy (permessions) to the Role (ECS) to be able to access `SSM(session managers)`
- **(I think this one is for EC2 not Fargate)**
```sh
aws iam put-role-policy \
  --policy-name SSMAccessPolicy \
  --role-name CruddurTaskRole \
  --policy-document "{
  \"Version\":\"2012-10-17\",
  \"Statement\":[{
    \"Action\":[
      \"ssmmessages:CreateControlChannel\",
      \"ssmmessages:CreateDataChannel\",
      \"ssmmessages:OpenControlChannel\",
      \"ssmmessages:OpenDataChannel\"
    ],
    \"Effect\":\"Allow\",
    \"Resource\":\"*\"
  }]
}
"
```
- Add second and third policy (permessions) to the Role (ECS) to be able to access `CloudWatch` and `XRay`
```sh
aws iam attach-role-policy --policy-arn arn:aws:iam::aws:policy/CloudWatchFullAccess --role-name CruddurTaskRole
aws iam attach-role-policy --policy-arn arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess --role-name CruddurTaskRole
```

### Register Backend Task Defintion 
- Created `aws\task-definitions\backend-flask.json`
```sh
aws ecs register-task-definition --cli-input-json file://aws/task-definitions/backend-flask.json
```

> Check commit details [here](https://github.com/AbdassalamAhmad/aws-bootcamp-cruddur-2023/commit/b58491415582924e1a5417ec4b693a493f69b926)



### Create a Service from UI at first.
- We created a Security Group to allow inbound traffic on port 80.
- Get the VPC ID
```sh
export DEFAULT_VPC_ID=$(aws ec2 describe-vpcs \
--filters "Name=isDefault, Values=true" \
--query "Vpcs[0].VpcId" \
--output text)
echo $DEFAULT_VPC_ID
```
- Create the security group
```sh
export CRUD_SERVICE_SG=$(aws ec2 create-security-group \
  --group-name "crud-srv-sg" \
  --description "Security group for Cruddur services on ECS" \
  --vpc-id $DEFAULT_VPC_ID \
  --query "GroupId" --output text)
echo $CRUD_SERVICE_SG
```
- Attach port 80
```sh
aws ec2 authorize-security-group-ingress \
  --group-id $CRUD_SERVICE_SG \
  --protocol tcp \
  --port 80 \
  --cidr 0.0.0.0/0
```

#### we need to add additional policies because we face multiple errors
- I haven't added my Secrets into `AWS Systems Manager`, that's why I ran into additional error.
```sh
aws ssm put-parameter --type "SecureString" --name "/cruddur/backend-flask/AWS_ACCESS_KEY_ID" --value $AWS_ACCESS_KEY_ID
aws ssm put-parameter --type "SecureString" --name "/cruddur/backend-flask/AWS_SECRET_ACCESS_KEY" --value $AWS_SECRET_ACCESS_KEY
aws ssm put-parameter --type "SecureString" --name "/cruddur/backend-flask/CONNECTION_URL" --value $PROD_CONNECTION_URL
aws ssm put-parameter --type "SecureString" --name "/cruddur/backend-flask/ROLLBAR_ACCESS_TOKEN" --value $ROLLBAR_ACCESS_TOKEN
aws ssm put-parameter --type "SecureString" --name "/cruddur/backend-flask/OTEL_EXPORTER_OTLP_HEADERS" --value "x-honeycomb-team=$HONEYCOMB_API_KEY"
```

- We added theses permessions to our `CruddurServiceExecutionPolicy` so that ecs can access ecr
```json
"Action": [
    "ecr:GetAuthorizationToken",
    "ecr:BatchCheckLayerAvailability",
    "ecr:GetDownloadUrlForLayer",
    "ecr:BatchGetImage",
    "logs:CreateLogStream",
    "logs:PutLogEvents"
],
```

- we added `CloudWatchFullAccess` permession to the same policy.

### Create The same Service from CLI
- we get the SG and Subnetes from the cli or AWS Console
```sh
# Security Group
export CRUD_SERVICE_SG=$(aws ec2 describe-security-groups \
  --filters Name=group-name,Values=crud-srv-sg \
  --query 'SecurityGroups[*].GroupId' \
  --output text)

# Subents
export DEFAULT_SUBNET_IDS=$(aws ec2 describe-subnets  \
 --filters Name=vpc-id,Values=$DEFAULT_VPC_ID \
 --query 'Subnets[*].SubnetId' \
 --output json | jq -r 'join(",")')
echo $DEFAULT_SUBNET_IDS
```
- used this json file `service-backend-flask.json` to create the service.
```json
{
    "cluster": "cruddur",
    "launchType": "FARGATE",
    "desiredCount": 1,
    "enableECSManagedTags": true,
    "enableExecuteCommand": true,
    "networkConfiguration": {
      "awsvpcConfiguration": {
        "assignPublicIp": "ENABLED",
        "securityGroups": [
          "sg-0b965256b756116f8"
        ],
        "subnets": [
          "subnet-0e9de1c77295e17b6",
          "subnet-0fdff04b63119822d",
          "subnet-0cad0091edf0149cc"
        ]
      }
    },
    "propagateTags": "SERVICE",
    "serviceName": "backend-flask",
    "taskDefinition": "backend-flask"
  }
```
- This command to create the service
```sh
aws ecs create-service --cli-input-json file://aws/json/service-backend-flask.json
```
✅ Now the Service is running and the health check are passing.
✅ If you want to see the health-check from public-url you need to allow SG port 4567 inbound traffic.

#### IF you want to shell into the Fargate instance that we're running
- Install Sessions Manager
```sh
curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb" -o "session-manager-plugin.deb"
sudo dpkg -i session-manager-plugin.deb
```
- Verify it's working
```sh
session-manager-plugin
```
- Execute this command to access the shell of the container.
- Don't forget to replace task id with yours.
```sh
aws ecs execute-command  \
--region $AWS_DEFAULT_REGION \
--cluster cruddur \
--task d1da8dbecd0e44dea34a08e0f7428e5a \
--container backend-flask \
--command "/bin/bash" \
--interactive
```

- added this script `backend-flask/bin/ecs/connect-to-service` to connect to contaienr easily
- added this task in`.gitpod.yml` to install AWS Session Manager always.
```yml
- name: fargate (install AWS Session Manager to access containers in fargate)
  before: |
    curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb" -o "session-manager-plugin.deb"
    sudo dpkg -i session-manager-plugin.deb
    session-manager-plugin
    cd backend-flask
```

> Check commit details [here](https://github.com/AbdassalamAhmad/aws-bootcamp-cruddur-2023/commit/72727fb26d86c8928a73dc8329ac541a9039cacb)






