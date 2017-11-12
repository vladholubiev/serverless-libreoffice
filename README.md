# Serverless LibreOffice

![](https://cdn-images-1.medium.com/max/1600/1*4q_I8VM6Gtmtw6TAjORylA.png)

<p align="center">
  <a href="https://vladholubiev.com/serverless-libreoffice">
    Read this blog post on Medium for details: How to Run LibreOffice in AWS Lambda for Dirty-Cheap PDFs at Scale
  </a>
</p>

# Show me the code

This repo contains code used to run the [online demo](https://vladholubiev.com/serverless-libreoffice).


```
├── compile.sh  <-- commands used to compile LibreOffice for Lambda
├── infra       <-- terraform config to deploy example Lambda
│   ├── iam.tf
│   ├── lambda.tf
│   ├── main.tf
│   ├── s3.tf
│   └── vars.tf
└── src         <-- example Lambda function node in Node.js used for website demo
    ├── handler.js
    ├── libreoffice.js
    ├── logic.js
    ├── package.json
    └── s3.js
```
