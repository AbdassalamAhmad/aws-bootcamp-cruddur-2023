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
- Once the new picture added an sns topic will be triggered.(I think it will be used with webhook to put the processed image in the front-end)


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
![image](https://user-images.githubusercontent.com/83673888/235360974-fe9ebf72-cc22-4fcf-a998-79bfd77144ac.png)
- re-implemented `frontend-react-js/src/pages/UserFeedPage.js` because we re-structured the Json that gets back to the front-end to the response.
```js
      if (res.status === 200) {
        setProfile(resJson.profile)
        setActivities(resJson.activities)
      } 
```
- implemented the checkAuth function that we made earlier in a previous week.

> Check commit details [here](https://github.com/AbdassalamAhmad/aws-bootcamp-cruddur-2023/commit/2510350321a77e387c251a8c5fcd0381766cde83)

### Implemented an Edit Profile Button
- To understand this line
 ```js
// UserFeedPage.js
<ProfileHeading setPopped={setPoppedProfile} profile={profile} />
```
that is referenced in 
```js
// ProfileHeading.js
      <EditProfileButton setPopped={props.setPopped} />
```
that is referenced in 
```js
// EditProfileButton.js
    props.setPopped(true);
    return false;
  }

  return (
    <button onClick={pop_profile_form} className='profile-edit-button' href="#">Edit Profile</button>
```

In the parent component, `setPoppedProfile` is a state updater function passed as a prop to the child component `ProfileHeading`. This function is used to set the state of the `poppedProfile` boolean variable. When `setPoppedProfile` is called with true, it sets the `poppedProfile` state variable to true, which triggers a re-render of the parent component.

Explanation: when a user hit the edit profile button the pop_profile_form function will be triggered that will setPopped to true.
this will reflect on ProfileHeading.js line above, then will reflect on UserFeedPage.js so poppedProfile will be true and the profile will re-render again to edit the images.

- First, we implemented `components/EditProfileButton.js` that has a function to display a forum once we clicked a button, but we didn't implement the forum yet.
- Then, we implement the style of that button in `components/EditProfileButton.css`.
- Then, we implement `components/ProfileHeading.js` which has content about the user that get passed by props from the `UserFeedPage.js` and the banner image and avatar image (hard-coded) which will be changed later.
- Now, we do the style (some of the style was made in .js file) but for the rest we use `components/ProfileHeading.css`.<br> we placed the avatar inside the banner, so that we can get the shape of twitter.


## Implement Migrations Backend Endpoint Profile Form (5th Video)
#### Small edit for the whole project structure
- add this file `jsconfig.json` to make imorting the compnents in the pages easier. (not having to do ../)
> Check commit details [here](https://github.com/AbdassalamAhmad/aws-bootcamp-cruddur-2023/commit/0b0426b00792f14a18f719a9ba3971aa2c73ef36)

### Implement The Profile Form Front-End After Finsihing Edit Profile Button
- The edit button is used to set `props.setPopped(true);`<br>
which will take effect on `profileHeading.js` in `<EditProfileButton setPopped={props.setPopped} />`<br>
which will take effect on `UserFeedPage.js` in  `<ProfileHeading setPopped={setPoppedProfile} profile={profile} />`<br>
which will take effect on `<ProfileForm profile={profile} popped={poppedProfile} setPopped={setPoppedProfile}/>`<br>
**The End result is openning the form after clicking the Edit Button**

- Implemented the `ProfileForm.js` which has the bio and display name to be edited, this form should be imported in `UserFeedPage.js`.
- Implemented the `ProfileForm.css` to style the form.
- Implemented `Popup.css` to edit the Z-index (to show the form above the user profile page)
- Finally we removed part of `ReplyForm.css` because it's not needed anymore after implementing `Popus.css`.

> Check commit details [here](https://github.com/AbdassalamAhmad/aws-bootcamp-cruddur-2023/commit/f518c3b591b72f0ff053dbdbf5337c1949df8f16)


### Implement The Profile Form Back-End
- Implemented the service `update_profile.py` which will get the bio and display_name from front-end and cognito_user_id from the back-end then it commits bio and display_name to our DB using this query `update.sql` and return the handle to perform another query.
- The second query is old one called `short.sql`will get the uuid, display_name, handle and it will be send to the front-end (I think just to check if the query was successed) because of these lines
```js
 let data = await res.json();
      if (res.status === 200) {
        // clear the bio and displayname fields so that when we open it again they will be ready to be used.
        setBio(null)
        setDisplayName(null)
        // close the forum if we get 200 code which meanse if we success in updating the bio | display_name
        props.setPopped(false)
```
- `app.py` will get the bio and display_name from front-end and cognito_user_id from access tocken and send them to `update_profile.py` service.

> Check commit details [here](https://github.com/AbdassalamAhmad/aws-bootcamp-cruddur-2023/commit/033b382d8d920ea486c4dc882764f65d99efa512)

#### Note about Bio in Database
- I used this command in the db to create the bio column.
```sql
ALTER TABLE public.users ADD COLUMN bio text;
```
- I did that for testing purposes, and it worked.
- I think we did the migration for something in the future, because this seems unnecessary at this point.

> Check commit details for showing bio in the front-end [here](https://github.com/AbdassalamAhmad/aws-bootcamp-cruddur-2023/commit/d5831c252b26587c451b5134241477456ee4fa36)

### Implement Migrations 
- Migrations is a way to Alter our Database Schema in a programatic way, so we're not doing it manually, also we store the edit time and the file we used to make that edit. Also we used un-edit (rollback) in the same file to revert the change we made if that was causing a problem.

- Edit `schema.sql` to have a new Table called `schema_information` that will store `last_successful_run` which is a time value = the name of the generated file that was run.
- `bin/generate/migration` this script will generate a file with a timestamp that will be filled later with the actual edit we want to make
- `backend-flask/db/migrations/16830311789006848_add_bio_column.py` this is the generated file then we add the sql commands for migration and rollback.
- Finally `bin/db/migrate` this script will run the previous file to migrate (add bio column) and commit the time of creating that file to the db under last_successful_run.
- Finally-again `bin/db/rollback` will run the previous file to rollback the changes and also commit  the time of creating that file to the db under last_successful_run.


- Why did we insert last_successful_run into the database in schema,
 because when we ran migrate script it didn't update its value because it's not there yet to update it.
- Why we add on conflict line in `schema.sql`?
because when we run schema load the schema_information table will not be destroyed like others.
so when we insert the first row (id=1, last_suc_run ='0') make sure that we don't insert it TWICE.

- Why I've made this change to the code?
```py
if int(last_successful_run) <= file_time:
```
- because if there was multiple files in that for loop then last_successful_run will be str and it will error on this if condition. <br>
so I removed the int form the return of the sql query because it becamde redundant in this case.

> Check commit details for showing bio in the front-end [here](https://github.com/AbdassalamAhmad/aws-bootcamp-cruddur-2023/commit/95a38d014a07fe63a56cca9a0ecb6ca9ee467010)


## Implemnet uploading Avatar Picture from Front-end (Rest of the videos)
### Summary
- Front-End: Implement two functions, one is to call an API Gateway to get a presigned url, the other one is for uploading the avatar image using that URLto S3.
- AWS: Implement API Gateway that integrated with two lambdas.
  - Auth Lambda: will authenticate JWT token and extract cognito_user_uuid and send it to the other Lambda.
  - Presigned URL Lambda: will handle CORS, then after preflight check, it gets back a presigned URL that can be used to push files to S3 bucket.
- CORS Issues were the most painful.

### Creating Auth Lambda
- used js to create it from aws repo.<br>
`npm install aws-jwt-verify --save`<br>
- zip the files and push them to lambda named CruddurApiGatewayLambdaAuthorizer
- don't forget to enter env for USER_POOL_ID, and CLIENT_ID.

### Creating Presigned URL lambda
- used ruby language to create the lambda.
```sh
bundle init
bundle install 
bundle exec ruby function.rb # run the function
```
- Gemfile is like requirements.txt , we can add libraries here and it will be installed using `bundle install`
- Add permessions (put object on s3 on a sepcific bucket on any object)
(PresignerUrlAvatarPolicy) can be found in `aws\policies\s3-upload-avatar-presigned-url-policy.json`
- put the env in AWS LAMBDA. then change the name of the function to function.rb and change the entry of the lambda (Runtime Settings) to function.handler
- This lambda has two parts, one for handling CORS, because this function gets called twice one for CORS to check called preflight. The other one is for presigned url
- The second part of this lambda gets the extension from the body of the POST request from front-end and gets cognito_user_uuid from the other lambda context to name the avatar this name `uuid.extension`.<br>
Finally it send the presigned url to the front-end that has the name and required permissions to put files on S3.
- **S3 CORS**: `aws\s3\cors.json` this file should be put on S3 CORS to allow the browser to push files to S3.<br>
**Note** we used **`Thunder Client`** VS Code extension to try POSTING files using that presigned url and it worked without setting S3 CORS. refer to [this post on discord](https://discord.com/channels/1055552619441049660/1103771693337554954)

> Check commit details [here](https://github.com/AbdassalamAhmad/aws-bootcamp-cruddur-2023/commit/7d4d4ce3390ccedbed7f6f27b13452c49c4b3d48)

### JWT ruby Lambda Layer
- Used this script to create a Lambda layer then add it to the lambda using AWS Console.
- This will help in decoding the token to get cognito_user_uuid.
- I didn't use that method, instead I I passed the cognito_user_uuid from JWT sub from CruddurApiGatewayLambdaAuthorizer (Auth Lambda ) to CruddurAvatarUpload. for more info check this [reference](https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api-lambda-authorizer.html). 

### Creating the API Gateway from Console
- Create `api.<domain_name>` 
- Create two routes:
  - `POST /avatars/key_upload` with authorizer `CruddurJWTAuthorizer` which invoke Lambda `CruddurApiGatewayLambdaAuthorizer`, and with integration `CruddurAvatarUpload`
  - `OPTIONS /{proxy+}` without authorizer, but with integration `CruddurAvatarUpload`
- We didn't configure CORS at API Gateway.

### Implement the Fornt-End Functions
- Implemented s3uploadkey that will trigger API Gateway to get the presigned url.
- Implemented s3upload that will trigger the previous one and gets the presigned url then it will gets the file from the client to upload it to S3 bucket.

> Check commit details [here](https://github.com/AbdassalamAhmad/aws-bootcamp-cruddur-2023/commit/41ca11ae7e4b1ef6aaa4235e2c2af99daabdb83b)

### Render Avatar Images
- Pass cognito_user_uuid from `checkAuth.js` lib to `profileInfo.js` then `profileHeading.js` through `show_profile_and_its_activities.sql`

- we used that cognito_user_uuid because it is the name of our avatar image.
- Finally, implemented `ProfileAvatar.js` which has the url of the bucket and some styling.

> Check commit details [here](https://github.com/omenking/aws-bootcamp-cruddur-2023/commit/ecd2f12ee5043b3ac731fb45ec5d268d8ffe192f)

## [Additional Work] Render Banner Image
- I basically did the same as in avatar.
- created a button connected to a new s3uploadbanner function that upload the image.
- this function send a value called banner to lambda function.
- the `CruddurAvatarUpload` lambda function has this code to name the image
```ruby
    if banner_or_avatar == "banner" || banner_or_avatar == "avatar"
      if banner_or_avatar == "banner"
        object_key = "#{banner_or_avatar}-#{cognito_user_uuid}.#{extension}"
      else
        object_key = "#{cognito_user_uuid}.#{extension}"
      end
    else
      puts "Invalid value for banner_or_avatar: #{banner_or_avatar}"
    end
```
- the proccess image lambda will use this code to put the image in its corresponding folder in assets bucket
```js
  let folderOutput, dstKey;

  if (filename.startsWith("banner")) {
    folderOutput = "banners"
    dstKey = `${folderOutput}/${filename}.jpg`;
    console.log(`Destination key is: ${dstKey}`);
  } else {
    folderOutput = "avatars"
    dstKey = `${folderOutput}/${filename}.jpg`;
    console.log(`Destination key is: ${dstKey}`);
  }
```

- Finally this commit was done in seperate branch because I didn't make it look as beatiful as main.

> Check commit details [here](https://github.com/AbdassalamAhmad/aws-bootcamp-cruddur-2023/commit/c3a2b4c7418184daa6d989f5ca4b92c2606ef892)


## Additional Script
- **Problem**: I was getting tired of doing `docker-compose up` and then setting up our local db and dynamodb tables.

**Solution:**
> Check commit details [here](https://github.com/AbdassalamAhmad/aws-bootcamp-cruddur-2023/commit/1e61acd6d6137a9a1c65c81b98d11d987751f4bb)

- **Explanation:** `gp sync-done` in any task will send a signal to the other task that have `gp sync-await` to make it begin working.

- So, we want to start docker-compose up after finishing the front-end task, then after finishing docker-compose task we want to setup our db and ddb.

- Notice that `init` is used for db and ddb because we want this task to run only one time when a new gitpod workspace lunch, because when we stop and reopen the workspace the local database and dynamodb tables will still be there and we don't want to lose that data. <br>
We only want to do `docker-compose up`.

- Small Note: you can condense the last two tasks into one but I prefer to have them separate.


