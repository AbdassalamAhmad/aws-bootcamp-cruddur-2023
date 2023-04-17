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


#### Update RDS SG to allow access from the backend security group (backend container)
- Now, backend can send traffic from port 4567 to RDS on port 5432
```sh
aws ec2 authorize-security-group-ingress \
  --group-id $DB_SG_ID \
  --protocol tcp \
  --port 5432 \
  --source-group $CRUD_SERVICE_SG \
  --tag-specifications 'ResourceType=security-group,Tags=[{Key=Name,Value=BACKENDFLASK}]'
```

#### Added serviceConnectConfiguration to our Service

```json
// service-backend-flask.json
  "serviceConnectConfiguration": {
    "enabled": true,
    "namespace": "cruddur",
    "services": [
      {
        "portName": "backend-flask",
        "discoveryName": "backend-flask",
        "clientAliases": [{"port": 4567}]
      }
    ]
  },
```

## Creating Load Balancer using AWS Console
- Create a SG for load balacner that allow port 4567 and 3000.
- Attatch that SG to our old backend SG, maybe rds in the future.
- Create the target groups for backend and frontend.
- Configure listeners for ALB and TG to port 4567 and 3000
- Edit ECS service json to have load balncer enabled using the target group arn.
```json
  "loadBalancers": [
    {
        "targetGroupArn": "arn:aws:elasticloadbalancing:eu-south-1:972586073133:targetgroup/cruddur-backend-flask-tg/87ed2a3daf2d2b1d",
        "containerName": "backend-flask",
        "containerPort": 4567
    }
  ],
```
```sh
aws ecs create-service --cli-input-json file://aws/json/service-backend-flask.json
```
- Don't enable logging to S3 from load balancer, (it's expensive)
- Now you can try accessing the backend from load balancer DNS:4567 **(we will make it private so that API endpoints needs auth to be accessed)**

## Creating Front-End Service
### Create Docker image with nginx and push it to ECR
- docker build one stage image (node), it failed eventually, due to memory issue (1.6GB image size) (after push ~ 580 MB)
- docker build multi stage image (node-node) it failed eventually, due to memory issue (~722MB image size) (after push 180MB).
- docker build multi stage image (node-nginx) (45MB image size)  (after push 18MB)
error message of (node-nginx)
```sh
host not found in upstream "api" in /etc/nginx/conf.d/default.conf:20	frontend-react-js
/docker-entrypoint.sh: Configuration complete; ready for start up
```

-**WORKING** build prod docker image of andrew with 17 MB of size after pushing.
#### Create Repo
```sh
aws ecr create-repository \
  --repository-name frontend-react-js \
  --image-tag-mutability MUTABLE
```

#### Set URL

```sh
export ECR_FRONTEND_REACT_URL="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/frontend-react-js"
echo $ECR_FRONTEND_REACT_URL
```
#### Build Image
```sh
docker build \
--build-arg REACT_APP_BACKEND_URL="http://cruddur-alb-525091684.eu-south-1.elb.amazonaws.com:4567" \
--build-arg REACT_APP_AWS_PROJECT_REGION="$AWS_DEFAULT_REGION" \
--build-arg REACT_APP_AWS_COGNITO_REGION="$AWS_DEFAULT_REGION" \
--build-arg REACT_APP_AWS_USER_POOLS_ID="eu-south-1_VVTlAbxEV" \
--build-arg REACT_APP_CLIENT_ID="7mph1qpebk969vkggt14g8l59d" \
-t frontend-react-js \
-f Dockerfile.prod \
.
```
#### Tag Image
```sh
docker tag frontend-react-js:latest $ECR_FRONTEND_REACT_URL:latest
```
#### Push Image
```sh
docker push $ECR_FRONTEND_REACT_URL:latest
```
If you want to run and test it

```sh
docker run --rm -p 3000:3000 -it frontend-react-js 
```

### Loadbalancer & Target Group
- Check that Loadbalancer & Target Group are set correctly from last step when we did for backend-flask image
- **importnat** add port 3000 for cruddur-alb-sg when using `dockerfile.prod`

### Create task definition & Front-end Service
> - used these files in [this commit](https://github.com/AbdassalamAhmad/aws-bootcamp-cruddur-2023/commit/e6c5beed6db2b7fe0b06b61b4bb707dee6dee96f)
> - update task definition of front-end to have healthcheck, add script to connect to front-end & back-end service. Check it in [this commit](https://github.com/AbdassalamAhmad/aws-bootcamp-cruddur-2023/commits/main)

- Finally, we did these command to update front end task definition and service.
```sh
aws ecs create-service --cli-input-json file://aws/json/service-frontend-react-js.json
aws ecs register-task-definition --cli-input-json file://aws/task-definitions/frontend-react-js.json
```
> proof of work
![image](https://user-images.githubusercontent.com/83673888/231022236-eafc8082-422e-43df-8f37-6572400d167d.png)

## Creating Domain name
- Used porkbun website to register my domain.
- Created a Hosted Zone inside Route53 which cost 0.5$ per month.
- Edit nameservers from porkbun, so that they have the hostedzone ones (to be managed by AWS).
- Create SSL Certificate using ACM (AWS Certificate Manager).
- ACM requires DNS validation
```sh
# ChatGPT
ACM will provide you with a unique value that you need to add as a TXT record to the DNS configuration of your domain. The value will be checked by ACM to confirm that you are the owner of the domain.
```
> proof of issued certificate

- Delete old listeners, add new ones to access port 80 and 443
- redirect http to https always.


- Created an `A` `record` that forward traffic to our loadbalancer.
- Rebuild our Front-End `Dockerfile.prod` file with `REACT_APP_BACKEND_URL="https://api.newcruddur.dev"`
- Change Origin from * to specific value (what is the benefit of this)
```json
// backend-flask.json
        "environment": [
          {"name": "FRONTEND_URL", "value": "https://newcruddur.dev"},
          {"name": "BACKEND_URL", "value": "https://api.newcruddur.dev"},
        ]
```
- Re-run task definitoin and update service for changes to take effect.

proof of work
![image](https://user-images.githubusercontent.com/83673888/231199864-08dd35fd-faa0-449c-afb9-fa372f2cb747.png)

![image](https://user-images.githubusercontent.com/83673888/231199893-fc9fd4cc-fa1a-4383-9545-53f92fd0ca98.png)


## Securing Flask Part 1
- Intorduced an error and see that it's unsafe to keep debugger on on production.
- Enter the PIN, then we access a terminal, then we can do all of stuff.
![image](https://user-images.githubusercontent.com/83673888/231284208-56fb08bb-5f40-4263-ad32-fd786196980f.png)
- To Remove that we made a `Dockerfile.prod` that doesn't allow debugger and reload (no-reload will not allow code to take affect)
- Also we made some docker scripts to make build & run commands easier for us to run.

> Check commit details [here](https://github.com/AbdassalamAhmad/aws-bootcamp-cruddur-2023/commit/7e3642d6cd3be970df4cf814db094b89b8eeb23f)


## Securing Flask Part 2

- Created Scripts to handle [Login to ECR, Build Backend & Frontend Prod Images, Run Backend local image]
- Created a script to force deployemnet of Frontend & Backend Services.
- Change bin to be in root directory, and change its dependamt paths.

> Check commit details [here](https://github.com/AbdassalamAhmad/aws-bootcamp-cruddur-2023/commit/9c099fa381727f2db8b118155f5d6d5165216136)

- Add a script to destroy all services to lower cost and to easily terminate them when we don't need them.
> Check commit details [here](https://github.com/AbdassalamAhmad/aws-bootcamp-cruddur-2023/commit/5750f0cb8ae2bff0134de9d6b3342687d44f269f)

## Fix messaging in Production
- In this file we fixed an issue where if we typed a message to non existing user, an error occured.
- Reason for error is there was no `return` before `{}` when `JSON` in `None`.
```py
# backend-flask/lib/db.py
# When we want to return an array of json objects
def query_object_json(self,sql,params={}):
  self.print_sql('json',sql,params)
  self.print_params(params)

  wrapped_sql = self.query_wrap_object(sql)
  with self.pool.connection() as conn:
    with conn.cursor() as cur:
      cur.execute(wrapped_sql,params)
      json = cur.fetchone()
      
      if json == None:
        return "{}"
      else:
        return json[0]
```

- Fixed a typo in these 3 files `frontend-react-js/src/components/MessageItem.js` `frontend-react-js/src/components/MessageGroupNewItem.js` `frontend-react-js/src/components/MessageGroupItem.js`
> Check commit details [here](https://github.com/AbdassalamAhmad/aws-bootcamp-cruddur-2023/commit/01ceb3cf9dd97af50a15d26c511b72644b252231)

- Add kill all script for prod and local
> Check commit details [here](https://github.com/AbdassalamAhmad/aws-bootcamp-cruddur-2023/commit/d0c1cb6255fc09035a8f585b426a226f00bc7b44)

- Fix health-check issue that causing backend service to be UnHealthy.
- The issue occured after changing the bin dir to be at root level.
- Solution: put back the health-check at the right location, and rereference it in `backend-flask.json`
> Check commit details [here](https://github.com/AbdassalamAhmad/aws-bootcamp-cruddur-2023/commit/b62dc61f6a08bfc63e021f9b3cfd119e75d1bacc)


## Added Google Analytics 
- Used Google Analytics to see where and when are users visiting my website `newcruddur.dev`
- Accomplished that by adding this script to `frontend-react-js/public/index.html` file
- Also you have to create an account on google analytics and follow these steps to create yours.
  - After creating a user, Add a property (Data Streams) and choose web.
  - Here you should Add your domain.
  - Now copy The code they provided for you NOT MINE (because each one gets a unique ID)
  - Put the code in your `frontend-react-js/public/index.html` file and check the realtime tab to see users hitting your domain.

```js
<!-- Google tag (gtag.js) -->
<script async src="https://www.googletagmanager.com/gtag/js?id=G-6D020LSSMM"></script>
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('js', new Date());

  gtag('config', 'G-6D020LSSMM');
</script>
```

## Implement Refresh Token Cognito
- We Fix the function that is responsible for refreshing the token which is `Auth.currentSession()` inside `checkAuth.js` file. 
- Then we referenced that Update in all of the pages that uses that token from `checkAuth.js` file

> Check commit details [here](https://github.com/AbdassalamAhmad/aws-bootcamp-cruddur-2023/commit/0e74feec8de619e9b3b374f8661362501e68e40f)



## Contaniers Insights
### Deploy X-Ray into Front-end & Backend and Implement a Health Check
- Define x-ray in the backend task definition.
- Add 2 scripts to register the task instead of running a cli command
- we don't want the front-end x-ray (not necessary)

> check [this commit](https://github.com/AbdassalamAhmad/aws-bootcamp-cruddur-2023/commit/96606771a46de3615e095dfa2198714970f393ed)

### Genereate ENV File to enhance the look of our docker-compose and docker build and run commands.
- Created these two files `erb/frontend-react-js.env.erb` & `erb/backend-flask.env.erb`
Those files have env variables in a erb format which can be used in ruby language to render the content inside `${}` variables.
- Created these two ruby scripts `bin/backend/generate-env` & `bin/frontend/generate-env` to convert the above files into plain text env vars.
- Finally [Very Important], Add this `*.env` to our `.gitignore` file so that the generated env files doesn't get commited to our public repo, therefore exposing our credentials.

> check [this commit](https://github.com/AbdassalamAhmad/aws-bootcamp-cruddur-2023/commit/896fdf72fe50507092b41a60a99dad6524d94fe4)

- Automatically, generate the env files everytime we open gitpod workspace.
- Change name of the docker-compose network cruddur-net to cruddur-network in multiple files.
- Reference the generated env file in the docker-compose file instead of referencing all the envs in the docker-compose file (more concise).

> check [this commit](https://github.com/AbdassalamAhmad/aws-bootcamp-cruddur-2023/commit/9216d4365ffb8f4df41e5ba5243977d24b655f73)

### Debugging Actions and Tools
- Install ping in dockerfile of python production to debug connections. (then we removed it).
- Configured busybox to debug connections.

> check [this commit](https://github.com/AbdassalamAhmad/aws-bootcamp-cruddur-2023/commit/60d38e66e0c32a9ddd9e98ab32c9ac3f77f71538)


## Spend Concerned
### **Important** Create a Script to Stop ECS Services to Save Costs.
- created a lambda function to Stop ECS Services everyday at midnight [check this discord thread](https://discord.com/channels/1055552619441049660/1094632478217601085) that I created explaining how to do it.

> check [this commit](https://github.com/AbdassalamAhmad/aws-bootcamp-cruddur-2023/commit/116b221e294ba95f3fbca9dd5752285c377fd047) for lambda code 
### Private ECR above 500MB (Maybe try Public)
- If you store more than 500 MB, it will cost 0.1$ per GB/month
- Data Transfer OUT	$0.09 per GB/month

### Hosted Zone inside Route53 cost 0.5$ per month.
