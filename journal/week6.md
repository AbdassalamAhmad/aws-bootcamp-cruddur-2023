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
1
- The Role should have a policy (Policy add permissions to the role to be able to perform the required task)
2
- Name the Policy. CruddurServiceExecutionPolicy
3
- Name the Role CruddurServiceExecutionRole 
4

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

> Check commit details [here]()



