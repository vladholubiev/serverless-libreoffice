# Serverless LibreOffice

[![](https://cdn-images-1.medium.com/max/1600/1*4q_I8VM6Gtmtw6TAjORylA.png)](https://vladholubiev.com/serverless-libreoffice)

<p align="center">
  <a href="https://medium.com/@vladholubiev/how-to-run-libreoffice-in-aws-lambda-for-dirty-cheap-pdfs-at-scale-b2c6b3d069b4">
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

Compiled and ready to use archive can be downloaded under [Releases section](https://github.com/vladgolubev/serverless-libreoffice/releases). Also check out [NPM package with bundled LibreOffice for Lambda (85 MB)](https://github.com/shelfio/aws-lambda-libreoffice).

✨ Check out a new [Lambda Layer with LibreOffice](https://github.com/shelfio/libreoffice-lambda-layer)!

# How to compile by yourself

> Check out a comprehensive [step-by-step tutorial](STEP_BY_STEP.md) from 0 to deployed function.

To run this, you will need to [Docker](https://docs.docker.com/install/) and [docker-compose](https://docs.docker.com/compose/install/) installed.

1. Install and configure Docker and docker-compose locally or on a `c5.2xlarge` spot instance with ~ 8 GB (the default) of storage attached.
1. In a terminal, run `docker-compose run --rm libreoffice`. It will compile LibreOffice and then copy layers.zip to your local drive.

# Help

- [List of RPM Packages available in AWS Lambda](https://gist.github.com/vladgolubev/1dac4ed47a5febf110c668074c6b671c)
- [List of Libraries available in AWS Lambda](https://gist.github.com/vladgolubev/439559fc7597a4fb51eaa9e97b72f319)

# Related Projects

- [Docker in AWS Lambda](https://github.com/vladgolubev/docker-in-aws-lambda)
- [NPM package with bundled LibreOffice for Lambda (85 MB)](https://github.com/shelfio/aws-lambda-libreoffice)
- [Lambda Layer with LibreOffice](https://github.com/shelfio/libreoffice-lambda-layer)

# How To Help

## Reduce Cold Start Time

Currently ƛ unpacks 109 MB .tar.gz to `/tmp` folder which takes ~1-2 seconds on cold start.

Would be nice to create a single compressed executable to save unpack time and increase portability.
I tried using [Ermine](http://www.magicermine.com/) packager and it works!!
But unfortunately this is commercial software.
Similar open-source analogue [Statifier](http://statifier.sourceforge.net/) produces broken binaries.

Maybe someone has another idea how to create a single executable from a folder full of shared objects.

**UPD:** TODO: Check out [node-packer](https://github.com/pmq20/node-packer) and [libsquash](https://github.com/pmq20/libsquash) (no FUSE required!)

## Further Size Reduction

I am not a Linux or C++ expert, so for sure I missed some easy "hacks"
to reduce size of compiled LibreOffice.

Mostly I just excluded from compilation as much unrelated stuff as possible.
And stripped symbols from shared objects.

Here is the list of: [available RPM packages](https://gist.github.com/vladgolubev/1dac4ed47a5febf110c668074c6b671c)
and [libraries](https://gist.github.com/vladgolubev/439559fc7597a4fb51eaa9e97b72f319)
available in AWS Lambda Environment, which can be helpful.

You can also use multi compression level, with upx and then decompress after brotli.

## Testing

Update repo for testing. Return before S3 for example, hardcode or generate files to convert and setup variables. Then simply run:

```
docker run \
 -v "\$PWD":/var/task \
 lambci/lambda:nodejs12.x src/handler.handler
```

After successful execution, get the resulted files to check the pdfs.

```
docker ps -a
```

Find exect container id.

Then execute

```
docker cp containerId:/tmp/filename.pdf ./filename.pdf
```

Then check your results locally

## License

MIT © [Vlad Holubiev](https://vladholubiev.com)
