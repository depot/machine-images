variable "ami-name" {
  type    = string
  default = ""
}

variable "ami-prefix" {
  type    = string
  default = "depot-machine-buildkit"
}

variable "log-token" {
  type      = string
  default   = ""
  sensitive = true
}

locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")

  name = var.ami-name == "" ? "${var.ami-prefix}-${local.timestamp}" : var.ami-name
}

packer {
  required_plugins {
    amazon = {
      version = "1.1.1"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

source "amazon-ebs" "amd64" {
  ami_name              = var.ami-name == "" ? "${var.ami-prefix}-amd64-${local.timestamp}" : "${var.ami-name}-amd64"
  instance_type         = "c6i.large"
  region                = "us-east-1"
  ssh_username          = "ubuntu"
  force_deregister      = true
  force_delete_snapshot = true
  ami_groups            = ["all"]

  # Copy to all non-opt-in regions (in addition to us-east-1 above)
  # See: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-regions-availability-zones.html
  ami_regions = [
    // "ap-northeast-1",
    // "ap-northeast-2",
    // "ap-northeast-3",
    // "ap-south-1",
    // "ap-southeast-1",
    // "ap-southeast-2",
    // "ca-central-1",
    "eu-central-1",
    // "eu-north-1",
    // "eu-west-1",
    // "eu-west-2",
    // "eu-west-3",
    // "sa-east-1",
    // "us-east-2",
    // "us-west-1",
    // "us-west-2",
  ]

  // ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-20230828
  source_ami = "ami-04f215f0e52ec06cf"
  // source_ami_filter {
  //   filters = {
  //     name                = "ubuntu/images/hvm-ssd/ubuntu-*-20.04-*-server-*"
  //     architecture        = "x86_64"
  //     root-device-type    = "ebs"
  //     virtualization-type = "hvm"
  //   }
  //   most_recent = true
  //   owners      = ["099720109477"] # Canonical
  // }

  launch_block_device_mappings {
    device_name           = "/dev/sda1"
    volume_size           = 40
    volume_type           = "gp3"
    delete_on_termination = true
  }

  ami_block_device_mappings {
    device_name = "/dev/sdb"
    no_device   = true
  }

  ami_block_device_mappings {
    device_name = "/dev/sdc"
    no_device   = true
  }

  # Wait up to an hour for the AMI to be ready.
  aws_polling {
    delay_seconds = 15
    max_attempts  = 240
  }
}

build {
  name    = "amd64"
  sources = ["source.amazon-ebs.amd64"]

  provisioner "shell" {
    execute_command = "sudo sh -c '{{ .Vars }} {{ .Path }}'"
    script          = "${path.root}/provision.sh"
    env             = { LOG_TOKEN = var.log-token }
  }
}

source "amazon-ebs" "arm64" {
  ami_name              = var.ami-name == "" ? "${var.ami-prefix}-arm64-${local.timestamp}" : "${var.ami-name}-arm64"
  instance_type         = "c6g.large"
  region                = "us-east-1"
  ssh_username          = "ubuntu"
  force_deregister      = true
  force_delete_snapshot = true
  ami_groups            = ["all"]

  # Copy to all non-opt-in regions (in addition to us-east-1 above)
  # See: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-regions-availability-zones.html
  ami_regions = [
    // "ap-northeast-1",
    // "ap-northeast-2",
    // "ap-northeast-3",
    // "ap-south-1",
    // "ap-southeast-1",
    // "ap-southeast-2",
    // "ca-central-1",
    "eu-central-1",
    // "eu-north-1",
    // "eu-west-1",
    // "eu-west-2",
    // "eu-west-3",
    // "sa-east-1",
    // "us-east-2",
    // "us-west-1",
    // "us-west-2",
  ]

  // ubuntu/images/hvm-ssd/ubuntu-focal-20.04-arm64-server-20230828
  source_ami = "ami-0abeb171ba7210dc7"
  // source_ami_filter {
  //   filters = {
  //     name                = "ubuntu/images/hvm-ssd/ubuntu-*-20.04-*-server-*"
  //     architecture        = "arm64"
  //     root-device-type    = "ebs"
  //     virtualization-type = "hvm"
  //   }
  //   most_recent = true
  //   owners      = ["099720109477"] # Canonical
  // }

  launch_block_device_mappings {
    device_name           = "/dev/sda1"
    volume_size           = 10
    volume_type           = "gp3"
    delete_on_termination = true
  }

  ami_block_device_mappings {
    device_name = "/dev/sdb"
    no_device   = true
  }

  ami_block_device_mappings {
    device_name = "/dev/sdc"
    no_device   = true
  }

  # Wait up to an hour for the AMI to be ready.
  aws_polling {
    delay_seconds = 15
    max_attempts  = 240
  }
}

build {
  name    = "arm64"
  sources = ["source.amazon-ebs.arm64"]

  provisioner "shell" {
    execute_command = "sudo sh -c '{{ .Vars }} {{ .Path }}'"
    script          = "${path.root}/provision.sh"
    env             = { LOG_TOKEN = var.log-token }
  }
}
