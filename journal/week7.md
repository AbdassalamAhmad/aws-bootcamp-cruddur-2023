# Week 7 — Solving CORS with a Load Balancer and Custom Domain

## Implement Timezone fix
- Simplified a code of timezone in backend-flask because it will automatically return UTC Format.
- Fix seed data in ddb
- Abstracted a time function in javascript that was already embeded in our code but it wasn't referencing ISO format.
- Referenced that new function in every file that require time

## Fix an issue with generating env vars for our docker-compose
- The issue is that `source` command run the script in bash even though we are specifining the script to be in ruby.
- Solved the issue with removing the word `source` simply :)

> Check commit details [here](https://github.com/AbdassalamAhmad/aws-bootcamp-cruddur-2023/commit/47e2bfe1372aa2562e83c14d39450f775864938e)