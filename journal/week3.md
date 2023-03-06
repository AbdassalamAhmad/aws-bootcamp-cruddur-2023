# Week 3 — Decentralized Authentication
## Required Homework

## Provision Amazon Cognito User Pool using AWS UI (Console)
- I've put a directory named [week-3-cognito-AWS-UI](https://github.com/AbdassalamAhmad/aws-bootcamp-cruddur-2023/tree/main/journal/assets/week-3-cognito-AWS-UI) inside `journal/assets` folder that has steps of creating the Cognito User Pool.

## Install and Configure Amplify Client-Side Library for Amazon Congito.
### Installation
- This command will add `aws-amplify` to our `package.json` file to be **installed** everytime we lunch docker-compose.
```sh
npm i aws-amplify --save
```
### Configuration
- Passed my env vars to `docker-compose` file to the `front-end` service
```yml
    REACT_APP_AWS_PROJECT_REGION: "${AWS_DEFAULT_REGION}"
    REACT_APP_AWS_COGNITO_REGION: "${AWS_DEFAULT_REGION}"
    REACT_APP_AWS_USER_POOLS_ID: "eu-south-1_VVTlAbxEV"
    REACT_APP_CLIENT_ID: "7mph1qpebk969vkggt14g8l59d"
```

- Linked my cognito user pool to my code in the `App.js`
```js
import { Amplify } from 'aws-amplify';

Amplify.configure({
  "AWS_PROJECT_REGION": process.env.REACT_APP_AWS_PROJECT_REGION,
  "aws_cognito_region": process.env.REACT_APP_AWS_COGNITO_REGION,
  "aws_user_pools_id": process.env.REACT_APP_AWS_USER_POOLS_ID,
  "aws_user_pools_web_client_id": process.env.REACT_APP_CLIENT_ID,
  "oauth": {}, // (optional) - Hosted UI configuration
  Auth: {
    // We are not using an Identity Pool
    // identityPoolId: process.env.REACT_APP_IDENTITY_POOL_ID, // REQUIRED - Amazon Cognito Identity Pool ID
    region: process.env.REACT_APP_AWS_PROJECT_REGION,           // REQUIRED - Amazon Cognito Region
    userPoolId: process.env.REACT_APP_AWS_USER_POOLS_ID,         // OPTIONAL - Amazon Cognito User Pool ID
    userPoolWebClientId: process.env.REACT_APP_CLIENT_ID,   // OPTIONAL - Amazon Cognito Web Client ID (26-char alphanumeric string)
  }
});
```

## Show Some Components if You Are Logged in Only
- Implemented some components in these pages `HomeFeedPage.js`, `DesktopNavigation.js`, `ProfileInfo.js`, `DesktopSidebar.js`.
### HomeFeedPage.js
- Removed old cookies method for Auth.
```js
import { Auth } from 'aws-amplify';

// set a state (Already Done)
const [user, setUser] = React.useState(null);

// check if we are authenicated
const checkAuth = async () => {
  Auth.currentAuthenticatedUser({
    // Optional, By default is false. 
    // If set to true, this call will send a 
    // request to Cognito to get the latest user data
    bypassCache: false 
  })
  .then((user) => {
    console.log('user',user);
    return Auth.currentAuthenticatedUser()
  }).then((cognito_user) => {
      setUser({
        display_name: cognito_user.attributes.name,
        handle: cognito_user.attributes.preferred_username
      })
  })
  .catch((err) => console.log(err));
};

// check when the page loads if we are authenicated (Already Done)
React.useEffect(()=>{
  loadData();
  checkAuth();
}, [])
```
- We'll want to pass user to the following components: (Already Done)
```js
<DesktopNavigation user={user} active={'home'} setPopped={setPopped} />
<DesktopSidebar user={user} />
```

### DesktopNavigation.js
- We'll rewrite `DesktopNavigation.js` so that it conditionally shows links in the left hand column
on whether you are logged in or not. (Already Done)

### ProfileInfo.js
- Removed old cookies method for Auth.
```js
import { Auth } from 'aws-amplify';

const signOut = async () => {
  try {
      await Auth.signOut({ global: true });
      window.location.href = "/"
  } catch (error) {
      console.log('error signing out: ', error);
  }
}
```

### DesktopSidebar.js
- Rewrote `DesktopSidebar.js` if conditions, to make the code clearer.
```js
  let trending;
  let suggested;
  let join;
  if (props.user) {
    trending = <TrendingSection trendings={trendings} />
    suggested = <SuggestedUsersSection users={users} />
  } else {
    join = <JoinSection />
  }
```

## Implement API Calls to Amazon Coginto for Custom Login, Signup, Recovery and Forgot Password Page

### Signin Page
- Removed old cookies method for Auth.
```js
import { Auth } from 'aws-amplify';

  const [errors, setErrors] = React.useState('');

  const onsubmit = async (event) => {
    setErrors('')
    event.preventDefault();
    Auth.signIn(email, password)
    .then(user => {
      localStorage.setItem("access_token", user.signInUserSession.accessToken.jwtToken)
      window.location.href = "/"
    })
    .catch(error => { 
      if (error.code == 'UserNotConfirmedException') {
        window.location.href = "/confirm"
      }
      setErrors(error.message)
    });
    return false
  }
```
