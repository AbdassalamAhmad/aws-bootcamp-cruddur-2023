# Week 0 — Billing and Architecture "Required Homework"
## Getting the AWS CLI Working
### Install AWS CLI
I've updated my `.gitpod.yml` file with the following code:
```yml
tasks:
  - name: aws-cli
    env:
      AWS_CLI_AUTO_PROMPT: on-partial
    init: |
      cd /workspace
      curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
      unzip awscliv2.zip
      sudo ./aws/install
      cd $THEIA_WORKSPACE_ROOT
```
**IMPORTANT:** when updating `.gitpod.yml` file commit and push then close the tab and re-open gitpod workspace from your github repo.

### Create a new User and Generate AWS Credentials
I have already a user with admin access and I've setup the access keys already.

### Setting Env Vars

I've set these credentials.
```sh
$ export AWS_ACCESS_KEY_ID=""
$ export AWS_SECRET_ACCESS_KEY=""
$ export AWS_DEFAULT_REGION=eu-south-1
```

This step will create new variables in my gitpod account@variables tab.
```sh
$ gp env AWS_ACCESS_KEY_ID=""
$ gp env AWS_SECRET_ACCESS_KEY=""
$ gp env AWS_DEFAULT_REGION=eu-south-1
```

### I've Checked that the AWS CLI is working and I am the expected user

```sh
$ aws sts get-caller-identity
```
**NOTE**: You can use this command to retreive your account id or other stuff also.
```sh
$ aws sts get-caller-identity --query Account --output text
```
The Output was 
```json
{
    "UserId": "AIDA6E4VFXQ**********",
    "Account": $AWS_ACCOUNT_ID,
    "Arn": "arn:aws:iam::$AWS_ACCOUNT_ID:user/Abdassalam"
}
```
![proof of working AWS CLI](https://user-images.githubusercontent.com/83673888/219456691-1cc6dea5-2ab8-4856-a4b6-83015bf990d6.png)
## Creating a Billing Alarm

### Enable Billing 

I've turned on Billing Alerts to recieve alerts using these steps:

- In your Root Account go to the [Billing Page](https://console.aws.amazon.com/billing/)
- Under `Billing Preferences` Choose `Receive Billing Alerts`
- Save Preferences



### Create SNS Topic

- We need an SNS topic before we create an alarm.
- The SNS topic is what will delivery us an alert when we get overbilled
- [aws sns create-topic](https://docs.aws.amazon.com/cli/latest/reference/sns/create-topic.html)

I've created sns topic using this command
```sh
$ aws sns create-topic --name billing-alarm
```

This was the output
`arn:aws:sns:eu-south-1:$AWS_ACCOUNT_ID:billing-alarm`


I've created a subscription and supply the TopicARN and my Email.
```sh
$ aws sns subscribe \
    --topic-arn arn:aws:sns:eu-south-1:$AWS_ACCOUNT_ID:billing-alarm \
    --protocol email \
    --notification-endpoint abdassalam******@gmail.com
```

I've checked my email and confirm the subscription.


## Create an AWS Budget
I've created 2 budgets one using aws console, then deleted it, and one using cli with the help of this next document.
[aws budgets create-budget](https://docs.aws.amazon.com/cli/latest/reference/budgets/create-budget.html)

**IMPORTANT NOTE:** you should have 2 budgets in free tier only after that you'll be charged 3 dollar per month.
steps to create budget using CLI:
- I've Grapped my account ID.
```sh
$ aws sts get-caller-identity --query Account --output text
```
- Supplied my AWS Account ID
- Updated the json files.

```sh
$ aws budgets create-budget \
    --account-id AccountID \
    --budget file://aws/json/budget.json \
    --notifications-with-subscribers file://aws/json/budget-notifications-with-subscribers.json
```
![proof of AWS budget](https://user-images.githubusercontent.com/83673888/219457582-f3af44c3-3485-4e39-b697-f06f883f65e3.png)
**NOTE:** I have modified this file [aws/json/budget-notifications-with-subscribers.json](https://github.com/AbdassalamAhmad/aws-bootcamp-cruddur-2023/blob/main/aws/json/budget-notifications-with-subscribers.json) so that it can have multiple thresholds rather than only one.

## Create CloudWatch Alarm

- [aws cloudwatch put-metric-alarm](https://docs.aws.amazon.com/cli/latest/reference/cloudwatch/put-metric-alarm.html)
- [Create an Alarm via AWS CLI](https://aws.amazon.com/premiumsupport/knowledge-center/cloudwatch-estimatedcharges-alarm/)

- I have updated the `alarm-config.json` script with the TopicARN I generated earlier.
- using the next command I'll have a cloudwatch alarm that will alert me if i exceeded one dollar.
```sh
aws cloudwatch put-metric-alarm --cli-input-json file://aws/json/alarm_config.json
```
**NOTE**: I deleted this cloudwatch because it's not doable by aws console in eu-south-1 which is the closest region to me. And I think that aws budget is enough and can get the job done.

## Recreate Architectual Diagram in Lucid Charts:
- Recreated Logical Architectual Diagram of Cruddur App using Lucid Charts.
![Cruddur App Lucid Chart](https://github.com/AbdassalamAhmad/aws-bootcamp-cruddur-2023/blob/main/journal/assets/Cruddur_App.jpeg)
- To view the chart in lucid charts login to your lucid account and click [this link](https://lucid.app/lucidchart/0afb0704-5f5b-4a7d-b0e7-0dffb694db62/edit?viewport_loc=-750%2C-379%2C2560%2C1232%2C0_0&invitationId=inv_46b06e1d-ee2c-4b27-a1fd-7481f70ec961)
 
## Homework challenges:
  1. Created CI/CD lucid Diagram.
  2. I've see that there is a limit of 5 Elastic IP to link to your EC2s which could be extended with a support ticket.
  3. I've delt with support on December 2022 because I didn't know that NAT gateways aren't part of free-tier and I was charged almost 1.5$ so they gave me 3$ credit and my issue was resolve.
  
