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

module "network" {
    source        = "./modules/network"

    instance_type         = local.instance_type
    bastion_key_private   = local.bastion_key_private
    bastion_key_public    = local.bastion_key_public
}

module "nginx" {
    source        = "./modules/nginx"
    
    instance_type           = local.instance_type
    alias_record            = local.alias_record
    cert_arn                = local.cert_arn
    private_subnets         = module.network.private_subnets
    public_subnets          = module.network.public_subnets
    vpc_id                  = module.network.vpc_id
    bastion_private_ip      = module.network.bastion_private_ip
    bastion_public_ip       = module.network.bastion_public_ip
    bastion_key_private     = local.bastion_key_private
    nginx_key_private       = local.nginx_key_private
    nginx_key_public        = local.nginx_key_public
    
}