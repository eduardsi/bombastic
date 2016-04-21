variable "access_key" {}
variable "secret_key" {}
variable "region" {}

provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region = "${var.region}"
}


variable "public_key_path" {
  default = "~/.ssh/terraform.pub"
}

resource "aws_key_pair" "auth" {
  key_name = "terraform-key"
  public_key = "${file(var.public_key_path)}"
}

resource "aws_security_group" "default" {
  name = "mega-securiy"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "webapp" {
    ami = "ami-2c657646"
    instance_type = "t1.micro"
    key_name = "${aws_key_pair.auth.id}"
    vpc_security_group_ids = ["${aws_security_group.default.id}"]
    provisioner "local-exec" {
        command = "echo ${self.public_ip} > publicIp.txt"
    }
    count = 3
    availability_zone = "${lookup(var.webappAvailabilityZones, count.index)}"
}

resource "aws_elb" "web" {
  instances = ["${aws_instance.webapp.*.id}"]
  availability_zones = ["${values(var.webappAvailabilityZones)}"]
  listener {
    instance_port     = 8080
    instance_protocol = "http"
    lb_port           = 8080
    lb_protocol       = "http"
  }
}

output "webAppDns" {
    value = "${aws_elb.web.dns_name}"
}


/*provider "aws" {
  alias = "dev"
  region = "${var.aws_region}"
  access_key = "${var.dev_access_key}"
  secret_key = "${var.dev_secret_key}"
}

# in dev account create iam policy, which will grants admin rights
resource "aws_iam_policy" "external_admin_policy" {
    provider = "aws.dev"*/
