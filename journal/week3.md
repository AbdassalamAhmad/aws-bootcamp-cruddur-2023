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
- Encountered an error when authenticating because the user created manually from AWS Cognito Console wasn't **"Verified"**
- Run this command to solve the issue (confirming the password)
```sh
aws cognito-idp admin-set-user-password --username 864ec250-50f1-70e9-9698-10aea66c0e5b --password Test123- --user-pool-id eu-south-1_VVTlAbxEV --permanent
```

- Added **"name"** to our user manually form cognito console.<br>
![image](https://user-images.githubusercontent.com/83673888/223082761-a6b8a5af-d869-4c01-93aa-1b0c1b631af1.png)

### Signup Page
- Clearly, we shouldn't be creating users by ourselves manually so we will create a signup page so that users can automatically signup and create content.
- Removed old cookies method for Auth.
```js
import { Auth } from 'aws-amplify';

const [errors, setErrors] = React.useState('');

const onsubmit = async (event) => {
    event.preventDefault();
    setErrors('')
    console.log('username',username)
    console.log('email',email)
    console.log('name',name)
    try {
        const { user } = await Auth.signUp({
        username: email,
        password: password,
        attributes: {
            name: name,
            email: email,
            preferred_username: username,
        },
        autoSignIn: { // optional - enables auto sign in after user is confirmed
            enabled: true,
        }
        });
        console.log(user);
        window.location.href = `/confirm?email=${email}`
    } catch (error) {
        console.log(error);
        setErrors(error.message)
    }
    return false
}
```

### ConfirmationPage
- Removed old cookies method for Auth.
```js
import { Auth } from 'aws-amplify';

const resend_code = async (event) => {
    setErrors('')
    try {
      await Auth.resendSignUp(email);
      console.log('code resent successfully');
      setCodeSent(true)
    } catch (err) {
      // does not return a code
      // does cognito always return english
      // for this to be an okay match?
      console.log(err)
      if (err.message == 'Username cannot be empty'){
        setErrors("You need to provide an email in order to send Resend Activiation Code")   
      } else if (err.message == "Username/client id combination not found."){
        setErrors("Email is invalid or cannot be found.")   
      }
    }
}

const onsubmit = async (event) => {
    event.preventDefault();
    setErrors('')
    try {
      await Auth.confirmSignUp(email, code);
      window.location.href = "/"
      console.log("hey, your account is confirmed now go to the signin page and log in to see your home feedback.")
    } catch (error) {
      setErrors(error.message)
    }
    return false
  }
```

### Recovery Page
- Implemented Recovery Page
```js
import { Auth } from 'aws-amplify';

const onsubmit_send_code = async (event) => {
  event.preventDefault();
  setErrors('')
  Auth.forgotPassword(username)
  .then((data) => setFormState('confirm_code') )
  .catch((err) => setErrors(err.message) );
  return false
}

const onsubmit_confirm_code = async (event) => {
  event.preventDefault();
  setErrors('')
  if (password == passwordAgain){
    Auth.forgotPasswordSubmit(username, code, password)
    .then((data) => setFormState('success'))
    .catch((err) => setErrors(err.message) );
  } else {
    setErrors('Passwords do not match')
  }
  return false
}
```

## Homework Challenges
- Made sure `Resend Activation Code` works in the `Confirmation Page` after sign up.
![image](https://user-images.githubusercontent.com/83673888/223314869-2204e0ae-38af-4a39-be0b-0be2a2d994ab.png)

- Filled the email automatically inside `Confirmation Page` & `Signin page` once you fill signup form.
```js
// SignupPage.js
// Store email in local storage to use it in confirmation & signin page.
localStorage.setItem('email', email); 
```

```js
    // ConfirmationPage.js
    // Get email from the signup page where we stored the email in localStorage
    React.useEffect(() => {
    const storedEmail = localStorage.getItem('email');
    if (storedEmail) {
        setEmail(storedEmail);
    }
    }, []);
```

```js
    // SigninPage.js
    // Get email from the signup page where we stored the email in localStorage
    React.useEffect(() => {
    const storedEmail = localStorage.getItem('email');
    if (storedEmail) {
        setEmail(storedEmail);
        localStorage.removeItem('email'); // Remove the email from local storage
    }
    }, []);
```

- Transitioned the user after confirming the account to the `Signin page` automatically instead of home page.
```js
// ConfirmationPage.js
window.location.href = "/signin"
```

