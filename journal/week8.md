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
- **Note:** meaning of the handler property is set to 'index.handler',
 which means that the entry point for the Lambda function is the handler function within the index.js file,
 located in the path/to/my/function/code directory.

- Add `.env` file
```yml
THUMBING_BUCKET_NAME="aa-cruddur-avatar-thumbs"
THUMBING_FUNCTION_PATH="/workspace/aws-bootcamp-cruddur-2023/aws/lambdas"
THUMBING_S3_FOLDER_INPUT="/avatar/original"
THUMBING_S3_FOLDER_OUTPUT= "/avatar/processed"
```
> Check commit details [here](https://github.com/AbdassalamAhmad/aws-bootcamp-cruddur-2023/commit/f416b6ebc797890978eecbc4081a836414a86ffb)

## Implement Serverless Pipeline (2nd video)
### summury
- We want to create a lambda function that will be triggered once we upload a picture (avatar) to our front-end (now to S3 bucket).
- The Lambda function will proccess the image and resize it and store in the same bucket in different folder.
- Once the new picture added an sns topic will be triggered.


### Add Lambda code in JS
- Used JS to write Lmabda code because we will use `sharp` library to process images because it is light-weight library unlike other languages libraries.
- Installed `sharp` and `@aws-sdk/client-s3` using `npm i` command after `npm init -y`
- The main magic is happening in `index.js` where we get the name of the picture with its path, then we conver the name with the path to the new location.
- We do the process using `sharp` library from the code written in `s3-image-processing.js` file.
- Finally we do the upload (put), we get the processed image from this function `processImage` then we upload it to s3 in the new location using this function `uploadProcessedImage`.
- `test.js` to test the process library without lambda (locally).
- `example.json` to test the lambda S3.put to check permessions and see the logs.

- Why used decoder and /+ in `const srcKey = decodeURIComponent(event.Records[0].s3.object.key.replace(/\+/g, ' '));`
The reason for using the decode function is that if space in the key it will be as `%20` without using decode
if i use decode it will be sent as a space.

> Check commit details [here](https://github.com/AbdassalamAhmad/aws-bootcamp-cruddur-2023/commit/a5eb24da3ea9200569e26ee1bc9e7c73019846f1)

### Add scripts for s3 assets bucket 
- made some scripts to make uploads and clear S3 bucket and building the dependencies required for lambda easier for us while developing.

> Check commit details [here](https://github.com/AbdassalamAhmad/aws-bootcamp-cruddur-2023/commit/2922918eba4f0778da83afabe90ce04cd70004ee)


### Ignore node_modules & Install sharp and cdk in gitpod & Update envs
- did all of that.
- export my DOMAIN_NAME & gp env DOMAIN_NAME.
- add 2 more env and edit the previous ones.
- remove `/` from the THUMBING_S3_FOLDER_INPUT & output.
- change the name of the bucket to be assets.domainname because CloudFormation require that in future.

> Check commit details [here](https://github.com/AbdassalamAhmad/aws-bootcamp-cruddur-2023/commit/ddcde5e91b81ea52be9e85c8412506584aef5601)

### Update Stack
- Do the import, reference the new env.
- Import our manual created S3 bucket.
- Add S3 Event Notification to lambda and SNS.
- Create SNS Topic and Subscription.
- Create policies for access and put objects in S3 from lambda.
- Attach those policies to lambda.
- Comment some code for SNS Policy.

> Check commit details [here](https://github.com/AbdassalamAhmad/aws-bootcamp-cruddur-2023/commit/6492c386d012400c9596a48b5aed4e58c5aa35d6)

## Serve Avatars Using CloudFront (3rd video)
### Why we're using CloudFront
- The reason for using CloudFront is, we don't want to download the avatar or assets images everytime someone visit the app.

### Creating CloudFront from AWS Console
- choose your s3 bucket, update its policy
- create control settings
- custom header is for static hosting.
- origin shield is another security layer (cost money don't need it)
- redirect to https
- Allow GET, HEAD HTTP methods.
- caching optimized, CORS-customOrigin, SimpleCORS. Policies.
- price class depends on the regions the more regions the higher the price.
- add custom domain name assets.newcruddur.dev
- add ssl certificate from ACM in us-east-1 region (we created one before but for our default region)
- logging off
- description: Serve Assets for Cruddur.
- create "A Record" inside route53 that point out assets.newcruddur.dev to cloudfront.
- added that policy from cloudfront into our s3 bucket so that cloudfront can access that.

### Re-Architect our S3 Buckets
- Used two S3 Buckets, one for uploading original images, then removing the images after a certain amount of days(1 day).<br>
The other one is for storing the processed ones.
- change the bucket names, therfore change the values and names inside the stack template.

> Check commit details [here](https://github.com/AbdassalamAhmad/aws-bootcamp-cruddur-2023/commit/52a7e7a5674cfbb689e86c906a03271181b75b89)

### Rename serverless Folder into avatars
- change the scripts to have the new s3 buckets names.
- fix the folder level (uploaded avatars doesn't have a folder).<br>
while the processed assets s3 bucket has folder for processed avatars.<br>
because this s3 bucket will have multiple sources like messaging, posts and avatars.
- finally rename the directory serverless -> avatars.

> Check commit details [here](https://github.com/AbdassalamAhmad/aws-bootcamp-cruddur-2023/commit/2503ddfa72611be71396957ad094a5231d383fd9)


## Implement User profile page (4th Video)
### Implement Back-End, SQL and Front-End Page
- removed old mocked data, and add these two lines that will execute SQL query to get the profile data and its activities
```py
      sql = db.template('users','show_profile_and_its_activities')
      results = db.query_object_json(sql, {'handle': user_handle})
```
- made this sql file `show_profile_and_its_activities.sql` that has a big query that gets back a strucuture like this.


- re-implemented `frontend-react-js/src/pages/UserFeedPage.js` because we re-structured the Json that gets back to the front-end to the response.
```js
      if (res.status === 200) {
        setProfile(resJson.profile)
        setActivities(resJson.activities)
      } 
```
- implemented the checkAuth function that we made earlier in a previous week.

> Check commit details [here](https://github.com/AbdassalamAhmad/aws-bootcamp-cruddur-2023/commit/2510350321a77e387c251a8c5fcd0381766cde83)