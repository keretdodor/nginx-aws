variable "instance_type" {
   description = "Instance Type"
   type        = string
}

variable "bastion_key_public" {
  type        = string
  description = "The full alias record"
}

variable "bastion_key_private" {
  type        = string
  description = "The full alias record"
}