# Serverless LibreOffice

![](https://cdn-images-1.medium.com/max/1600/1*4q_I8VM6Gtmtw6TAjORylA.png)

<p align="center">
  <a href="https://vladholubiev.com/serverless-libreoffice">
    👉🏻 Read the blog post on Medium: How to Run LibreOffice in AWS Lambda for Dirty-Cheap PDFs at Scale 👈🏻
  </a>
</p>

# Show Me the Code

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
    ├── package.json <-- put lo.tar.gz in this folder to deploy. Download it below
    └── s3.js
```

Compiled and ready to use archive can be downloaded under [Releases section](https://github.com/vladgolubev/serverless-libreoffice/releases).

# How To Help

## Reduce Cold Start Time

Currently ƛ unpacks 109 MB .tar.gz to `/tmp` folder which takes ~1-2 seconds on cold start.

Would be nice to create a single compressed executable to save unpack time and increase portability.
I tried using [Ermine](http://www.magicermine.com/) packager and it works!!
But unfortunately this is commercial software.
Similar open-source analogue [Statifier](http://statifier.sourceforge.net/) produces broken binaries.

Maybe someone has another idea how to create a single executable from a folder full of shared objects.

## Further Size Reduction

I am not a Linux or C++ expert, so for sure I missed some easy "hacks"
to reduce size of compiled LibreOffice.

Mostly I just excluded from compilation as much unrelated stuff as possible.
And stripped symbols from shared objects.

Here is the list of: [available RPM packages](https://gist.github.com/vladgolubev/1dac4ed47a5febf110c668074c6b671c)
and [libraries](https://gist.github.com/vladgolubev/439559fc7597a4fb51eaa9e97b72f319)
available in AWS Lambda Environment, which can be helpful.
