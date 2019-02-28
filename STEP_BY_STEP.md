## LibreOffice Meets Serverless - Setup Scalable Document Converter on a Budget

LibreOffice is free and open-source office suite used by millions Linux enthusiasts.
It is a powerful tool, capable of converting between ~100 document formats.

One not-so-known its feature is a headless mode. This means you can run it on 
a server to process documents. There are not so many open-source and even commercial 
tools for this job. Probably the most common use case of running LibreOffice on a server 
is converting files to PDF format. That way any office document can be rendered in a web browser. 

Headless mode means you spawn a process inside a shell instead of launching a program in a window.
Let's say you want to convert thousands of office documents to PDF on your machine.
A naive approach would be to spawn a process once a new file appears in a directory.
Once you face any kind of concurrency problems come in.

A better idea is to use Docker. It is a great containerization software which helps you
to pack a program with its dependencies into one "image" and scale as needed. I was running 
LibreOffice inside Docker containers for a year, and believe me, it requires a lot of care. 

Running multiple instances of headless LibreOffice inside 1 Docker container leads to 
memory leaks, zombie processes, and other not so pleasant issues.  
I have to mention there is a way to run LibreOffice in a “server” mode and talking via a socket, 
but it’s even more unstable. You'll end up writing a lot of code with retry logic and cleanup scripts.

Serverless technology comes as a natural successor after containerization (Docker).
It provides many benefits on top of previous solutions.

* No server management: it's a job for FaaS provider, you supply only the code to run
* Scaling: from 0 to millions of concurrent requests without over-provisioning 
* Price: you pay for the amount of seconds spent running your code!
* Stateless: almost every code execution runs in a fresh environment

The last two are especially useful for running LibreOffice. Stateless means no zombie 
processes or memory leaks! Even if they occur, the next invocation will be inside 
a fresh runtime. No need to clean up failed files or close open sockets.

And a price. LibreOffice is a hungry piece of software. It can take minutes to convert a 
200-page document to PDF, so you better give it plenty of RAM and CPU resources.
A benefit of serverless is that you can control how much you supply. Choose anything 
on a scale from 0.1 to 3 GB RAM. Got 1000 files? Pay only for 10 minutes of used CPU. 
No documents to process today? Great, it's free as you don't waste idle server.

In this tutorial, you'll learn how to make LibreOffice run inside AWS Lambda functions - 
the most popular FaaS provider as of today. And the good news is it will be most likely 
for free! AWS has a generous free tier - 400 000 GB/s for your functions every month! 

### Step 1: Compiling LibreOffice

In order to run anything non-standard in AWS Lambda, you need to compile it first under 
the same environment. Currently, Lambda runs in Amazon Linux version 2017.03.  
You will need a beefy EC2 server with at least 80 GB of storage. 
I recommend a 16 core instance from the C5 family which will compile it in around 30 minutes.

Given only 512 MB of disk space in Lambda, it's a challenge to squeeze whole LibreOffice 
in so little space. The trick is to compile it disabling optional modules such as 
DBC driver or KDE extensions. Next, after removing symbols from shared objects using 
`strip` command reduced LibreOffice size from 2 to 0.4 GB (0.1 GB zipped).

Fortunately, I went through this process already, so you can download pre-compiled artifacts 
from this page: https://github.com/vladgolubev/serverless-libreoffice/releases
You will need `lo.tar.gz` file which will be put into Lambda function later.
If you wish to repeat this yourself, here are the compilation instructions: 
https://github.com/vladgolubev/serverless-libreoffice/blob/master/compile.sh

### Step 2: Creating AWS S3 bucket to store files

This will be a place to store a compiled LibreOffice archive, input office documents, 
and output converted PDF files. The name in example will be `lambda-libreoffice-demo`.
You will need [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/installing.html) installed first.

```bash
$ aws s3api create-bucket --bucket lambda-libreoffice-demo
```

Next, let's download compiled LibreOffice from GitHub and upload it to your new S3 bucket. 
Lambda function will download and unpack it on startup if it wasn't downloaded yet. 
Despite a large file size, it takes under a second since both Lambda and S3 are in the same AWS region.

```bash
$ curl -L https://github.com/vladgolubev/serverless-libreoffice/releases/download/v6.1.0.0.alpha0/lo.tar.gz -o lo.tar.gz
$ aws s3 cp lo.tar.gz s3://lambda-libreoffice-demo/lo.tar.gz --acl public-read-write
```

For the sake of demo, we made the file public, so it can be used later in the function code.

### Step 3: Creating AWS IAM role and policy for AWS Lambda function

First of all, we need to create an AWS IAM role which will allow your Lambda function read/write files on S3 bucket:

```bash
lambda_execution_role_arn=$(aws iam create-role --role-name lambda-pdf \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{
  "Sid": "","Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}' \
  --output text \
  --query 'Role.Arn'
)
echo lambda_execution_role_arn=$lambda_execution_role_arn
```

If all goes well, it should print something like `lambda_execution_role_arn=arn:aws:iam::XXXXXXX:role/lambda-pdf`.
It will be needed later to upload function code. To complete IAM setup, attach a policy to the newly created 
role `lambda-pdf` granting access to the S3 bucket `lambda-libreoffice-demo`.

```bash
aws iam put-role-policy --role-name lambda-pdf \
  --policy-name "lambda-pdf-execution" \
  --policy-document '{"Version":"2012-10-17",
      "Statement":[{ "Effect":"Allow","Action":["s3:*"],"Resource":"arn:aws:s3:::lambda-libreoffice-demo/*"}]}'
```

### Step 4: Creating AWS Lambda function

I'll use node.js as my language of choice of this example. A couple of things the function will do:

* Downloaded & unpack LibreOffice into `/tmp` directory on startup
* Download input file from S3 to `/tmp`. LibreOffice works with local files only
* Spawn headless LibreOffice process with parameters specifying output conversion format
* Upload converted file back to S3 bucket and return its URL

All of these is a mere 30 lines of code.

Javascript Version
```javascript
const {writeFileSync, readFileSync} = require('fs');
const {execSync} = require('child_process');
const {parse} = require('path');
const {S3} = require('aws-sdk');

// This code runs only once per Lambda "cold start"
execSync(`curl https://s3.amazonaws.com/lambda-libreoffice-demo/lo.tar.gz -o /tmp/lo.tar.gz && cd /tmp && tar -xf /tmp/lo.tar.gz`);

const s3 = new S3({params: {Bucket: 'lambda-libreoffice-demo'}});
const convertCommand = `/tmp/instdir/program/soffice --headless --invisible --nodefault --nofirststartwizard --nolockcheck --nologo --norestore --convert-to pdf --outdir /tmp`;

exports.handler = async ({filename}) => {
  const {Body: inputFileBuffer} = await s3.getObject({Key: filename}).promise();
  writeFileSync(`/tmp/${filename}`, inputFileBuffer);

  execSync(`cd /tmp && ${convertCommand} ${filename}`);

  const outputFilename = `${parse(filename).name}.pdf`;
  const outputFileBuffer = readFileSync(`/tmp/${outputFilename}`);

  await s3
    .upload({
      Key: outputFilename, Body: outputFileBuffer,
      ACL: 'public-read', ContentType: 'application/pdf'
    })
    .promise();

  return `https://s3.amazonaws.com/lambda-libreoffice-demo/${outputFilename}`;
};
```

Python Version
```python
import boto3
import os

s3_bucket = boto3.resource("s3").Bucket("lambda-libreoffice-demo")
os.system("curl https://s3.amazonaws.com/lambda-libreoffice-demo/lo.tar.gz -o /tmp/lo.tar.gz && cd /tmp && tar -xf /tmp/lo.tar.gz")
convertCommand = "instdir/program/soffice --headless --invisible --nodefault --nofirststartwizard --nolockcheck --nologo --norestore --convert-to pdf --outdir /tmp"

def lambda_handler(event,context):
  inputFileName = event['filename']
  # Put object wants to be converted in s3
  with open(f'/tmp/{inputFileName}', 'wb') as data:
      s3_bucket.download_fileobj(inputFileName, data)

  # Execute libreoffice to convert input file
  os.system(f"cd /tmp && {convertCommand} {inputFileName}")

  # Save converted object in S3
  outputFileName, _ = os.path.splitext(inputFileName)
  outputFileName = outputFileName  + ".pdf"
  f = open(f"/tmp/{outputFileName}","rb")
  s3_bucket.put_object(Key=outputFileName,Body=f,ACL="public-read")
  f.close()
```

Conversion output format is controlled via `--convert-to pdf` CLI argument. You can play around and change it to `docx`, 
for example. Note that for demo purposes S3 bucket name is hard-coded and converted file wll be public.
Save the code under `code.js` or `code.py` file name and archive:

```bash
$ zip code.zip code.js  # for Javascript
# OR
$ zip code.zip code.py  # for Python
```

Finally, you're ready to create a Lambda function! Don't forget to replace `XXXXXXXXX` with `lambda_execution_role_arn`
which was printed in previous steps.

```bash
aws lambda create-function --function-name convert-to-pdf \
  --zip-file fileb://$(pwd)/code.zip --runtime nodejs8.10 \
  --handler code.handler --role XXXXXXXXX \
  --timeout 20 --memory-size 3008
```

That's all, your function is deployed and ready to scale.

### Step 5: Test deployed function

Recently created Lambda function accepts JSON with `filename` key corresponding to the file on S3. 
Run this commands to create a dummy text file and put it on S3.

```bash
$ echo "Hello World!" > input.txt
$ aws s3 cp input.txt s3://lambda-libreoffice-demo/input.txt
```

Run the code below to convert `input.txt` into PDF. Converted file will be in the same folder on S3.
First call can take a while, but once Lambda is warmed it will be fast for a while.

```bash
$ aws lambda invoke --function-name convert-to-pdf \
    --payload '{"filename":"input.txt"}' output.txt && cat output.txt

# => https://s3.amazonaws.com/lambda-libreoffice-demo/input.pdf
```

Voila! Opening returned URL in a browser reveals and converted PDF!

![](https://i.imgur.com/4qWgRnh.png)

### Summary

In this tutorial you've built onw dirty-cheap scalable serverless document converter using LibreOffice and AWS.
You do not need to worry about server maintenance, memory leaks in Docker containers, and cleanup/retry logic.

You can play with [online demo](https://vladholubiev.com/serverless-libreoffice), download Terraform configuration and 
compiled LibreOffice archive from the [GitHub repository](https://github.com/vladgolubev/serverless-libreoffice).
