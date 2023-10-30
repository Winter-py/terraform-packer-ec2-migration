packer {
  required_plugins {
    amazon = {
      version = ">= 1.2.5"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

source "amazon-ebs" "firstrun-windows" {
  ami_name             = "${var.name}-migrated-app"
  communicator         = "winrm"
  instance_type        = "t3.large"
  region               = "${var.region}"
  vpc_id               = "${var.vpc_id}"
  iam_instance_profile = "AmazonSSMRoleForInstancesQuickSetup"
  subnet_id            = "${var.subnet_id}"


  run_tags = {
    Name       = "${var.name}"
    Automation = "Migration"
  }
  metadata_options {
    instance_metadata_tags = "enabled"
  }
  source_ami_filter {
    filters = {
      name                = "Windows_Server-2022-English-Full-SQL_2019_Express*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["amazon", "aws-marketplace", "microsoft"]
  }
  user_data_file = "./init_win.txt"
  winrm_password = "${local.secret}"
  winrm_username = "Administrator"


  tags = {
    Name        = "${var.name}"
    Environment = "${var.Environment}"
    Date        = "${local.timestamp}"
  }
}