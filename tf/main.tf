terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=5.55"
    }
  }

  required_version = ">= 1.7.0"

  backend "s3" {
    bucket = "nginx-bucket-with-respect"
    key    = "tfstate.json"
    region = "eu-north-1"

  }

}
provider "aws" {
  region = local.region
}


module "nginx" {
    source = "./modules/network"

}