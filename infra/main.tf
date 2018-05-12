provider "aws" {
  region  = "us-east-1"
  version = "~> 1.18"
  profile = "vlad"
}

provider "archive" {
  version = "~> 1.0"
}

terraform {
  backend "s3" {
    acl     = "private"
    bucket  = "vladholubiev-tf-state"
    key     = "env-prod/libreoffice/main.tfstate"
    encrypt = "true"
    region  = "eu-central-1"
    profile = "vlad"
  }
}
