# Week 8 — Serverless Image Processing

**NOTE**: The whole week is about getting image from s3 bucket (avatar image) and proccess it using an image library,
the process is done using lambda function written in JS to sharpen or enhance the image and,
store the processed image again in the s3 bucket in different folder.

## Install CDK Globally

- This is so we can use the AWS CDK CLI from anywhere.
`npm install aws-cdk -g`
- Add that command in `.gitpod.yml`
- Initialize a new project -> this command will output a folder that has lots of files to give us a good starting point.
`cdk init app --language typescript`

### Important Commands

- Bootstrapping
> Deploying stacks with the AWS CDK requires dedicated Amazon S3 buckets and other containers to be available to AWS CloudFormation during deployment. 
```sh
cdk bootstrap "aws://$AWS_ACCOUNT_ID/$AWS_DEFAULT_REGION"
```

- Build
> We can use build to catch errors prematurely.
(This command will generate JS code and then output errors in the terminal)
```sh
npm run build
```

- Synth
> the synth command is used to synthesize the AWS CloudFormation stack(s) that represent your infrastructure as code.
(like giving yaml cloudformataion template of what your cdk code will make.)
```sh
cdk synth
```

- Deploy
> will deploy those resources
```sh
cdk deploy
```

- List Stacks
```sh
cdk ls
```

## Add S3 Bucket && Lambda Function

- Installed `dotenv` lib and import it in this file `thumbing-serverless-cdk-stack.ts`. using this command
`npm i dotenv`
```typescript
    // reference env files
    const bucketName: string = process.env.THUMBING_BUCKET_NAME as string;
    const functionPath: string = process.env.THUMBING_FUNCTION_PATH as string;
    const folderInput: string = process.env.THUMBING_S3_FOLDER_INPUT as string;
    const folderOutput: string = process.env.THUMBING_S3_FOLDER_OUTPUT as string;
    // The code that defines your stack goes here
    const bucket = this.createBucket(bucketName);
    const lambda = this.createLambda(functionPath, bucketName, folderInput, folderOutput);

  }

  createBucket(bucketName: string): s3.IBucket{
    const bucket = new s3.Bucket(this, 'ThumbingBucket', {
      bucketName: bucketName,
      removalPolicy: cdk.RemovalPolicy.DESTROY,
    });
    return bucket;
  }

  createLambda(functionPath: string, bucketName: string, folderInput: string, folderOutput: string): lambda.IFunction {
    const lambdaFunction = new lambda.Function(this, 'ThumbLambda', {
      runtime: lambda.Runtime.NODEJS_18_X,
      handler: 'index.handler',
      code: lambda.Code.fromAsset(functionPath),
      environment: {
        DEST_BUCKET_NAME: bucketName,
        FOLDER_INPUT: folderInput,
        FOLDER_OUTPUT: folderOutput,
        PROCESS_WIDTH: '512',
        PROCESS_HEIGHT: '512'
      }
    });
    return lambdaFunction;
  } 
```

- Add `.env` file
```yml
THUMBING_BUCKET_NAME="aa-cruddur-avatar-thumbs"
THUMBING_FUNCTION_PATH="/workspace/aws-bootcamp-cruddur-2023/aws/lambdas"
THUMBING_S3_FOLDER_INPUT="/avatar/original"
THUMBING_S3_FOLDER_OUTPUT= "/avatar/processed"
```
