variable "instance_type" {
   description = "Instance Type"
   type        = string
}

variable "private_subnets" {
  type        = list
  description = "List of subnets from the VPC module"
}

variable "public_subnets" {
  type        = list
  description = "List of subnets from the VPC module"
}

variable "vpc_id" {
  type        = string
  description = "The vpc id"
}

variable "alias_record" {
  type        = string
  description = "The full alias record"
}

variable "cert_arn" {
  type        = string
  description = "The certificate ARN"
}

variable "bastion_private_ip" {
  type        = string
  description = "The full alias record"
}

variable "bastion_public_ip" {
  type        = string
  description = "The full alias record"
}

variable "nginx_key_public" {
  type        = string
  description = "The full alias record"
}

variable "nginx_key_private" {
  type        = string
  description = "The full alias record"
}

variable "bastion_key_private" {
  type        = string
  description = "The full alias record"
}
