The process to migrate a customer instance from Windows Server 2012 R2, Windows Server 2016, Windows Server 2019 to Windows Server 2022. The process involves the following steps

- Backing up the old instance (Database/IIS/Nginx)
- Creating a new AMI using packer with all requirdrequired tools and applications 
- Restoring the backed up data onto a new server AMI
- Creating the new instance with the old Elastic IP, tags, Instance type 


##  Packer Inputs


| Syntax      | Description | Type | Required|
| ----------- | ----------- | -----------| -----------|
| Region      | The AWS region for the AMI Build       | String | Yes |
| Name   | Application or Server name        | String | Yes |
| Source | Source of backup, This could be a S3 bucket or a Network Location | String | Yes |
