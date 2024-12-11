locals {
  region                       = "eu-north-1"
  alias_record                 = "nginx.magvonim.site"
  instance_type                = "t3.micro"
  cert_arn                     = "arn:aws:acm:eu-north-1:851725559197:certificate/11afe73a-d553-4384-9fb1-39e835b8f880"
  nginx_key_private            = "nginx-key-moveo.pem"
  bastion_key_private          = "bastion-key-moveo.pem"
  nginx_key_public             = "nginx-key-moveo.pub"
  bastion_key_public           = "bastion-key-moveo.pub"

}

