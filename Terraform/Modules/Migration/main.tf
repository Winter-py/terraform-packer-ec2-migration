terraform {
  required_version = ">= 0.12.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}



# Retrieve attributes of existing EC2 instance
data "aws_instance" "existing_instance" {
  instance_id = "${var.instance_id}"
}

data "aws_eip" "by_public_ip" {
public_ip = data.aws_instance.existing_instance.public_ip
}

data "aws_ami" "packer"{
  most_recent = true
  owners      = ["self"]
  filter {
    name   = "name"
    values = ["${var.Name}-migrated-app"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  } 
}

# Create a new EC2 instance with the same configuration as the existing instance
resource "aws_instance" "new_instance" {
  ami           = data.aws_ami.packer.id
  instance_type = data.aws_instance.existing_instance.instance_type
  key_name      = data.aws_instance.existing_instance.key_name
  subnet_id     = data.aws_instance.existing_instance.subnet_id
  vpc_security_group_ids = data.aws_instance.existing_instance.vpc_security_group_ids
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

    root_block_device {
    encrypted = true
    }

    tags = data.aws_instance.existing_instance.tags

}

resource "aws_eip_association" "eip_assoc" {
  instance_id   = aws_instance.new_instance.id
  allocation_id = data.aws_eip.by_public_ip.id
}

resource "aws_iam_role" "instance_role" {
  name = "${var.Name}_Instance_Role"
  managed_policy_arns = ["arn:aws:iam::aws:policy/AmazonSSMPatchAssociation", "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore","arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM" ]

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })


  tags = {
    tag-key = "policy-${var.Name}"
  }
}
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.Name}_profile"
  role = aws_iam_role.instance_role.name
}