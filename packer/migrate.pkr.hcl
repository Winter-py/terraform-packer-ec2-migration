packer {
  required_plugins {
    amazon = {
      version = ">= 1.2.5"
      source  = "github.com/hashicorp/amazon"
    }
  }
}


locals {secret = aws_secretsmanager("${var.Secret_Arn}","Password")}

source "amazon-ebs" "firstrun-windows" {
  ami_name             = "${var.Name}-migrated-app"
  communicator         = "winrm"
  instance_type        = "t3.large"
  region               = "${var.region}"
  vpc_id               = "${var.vpc_id}"
  iam_instance_profile = "AmazonSSMRoleForInstancesQuickSetup"
  subnet_id            = "${var.subnet_id}"


  run_tags = {
    Name       = "${var.Name}"
    Automation = "Migration"
  }
  metadata_options {
    instance_metadata_tags = "enabled"
  }
  source_ami_filter {
    filters = {
      Name                = "Windows_Server-2022-English-Full-SQL_2019_Express*"
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
    Name        = "${var.Name}"
    Environment = "${var.Environment}"
    Date        = "${local.timestamp}"
  }
}

#build block invokes sources and runs provisioning steps on them.
#Sample_IIS_Server_Setup is not need if you already have a golden image.
build {
  Name    = "packer-build"
  sources = ["source.amazon-ebs.firstrun-windows"]

  provisioner "powershell" {
    script = "./Scripts/Sample_IIS_Server_Setup.ps1"  
  }

  provisioner "file" {
    destination = "C:\\Packer\\RestoreInstance.ps1"
    source      = "./Scripts/RestoreInstance.ps1"
  }

  provisioner "powershell" {
    elevated_user     = "Administrator"
    elevated_password = "${local.secret}"
    inline            = ["powershell C:\\Packer\\RestoreInstance.ps1 -SourceLocation ${var.source}"]
  }

}
