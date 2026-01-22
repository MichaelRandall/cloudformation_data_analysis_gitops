# PostgreSQL on EC2 with CloudFormation

This repository contains infrastructure-as-code (IaC) to quickly deploy a PostgreSQL database on AWS EC2 using CloudFormation. It includes persistent EBS storage, S3-based SQL script initialization, and automated setup.

## Overview

This solution provides:
- **EC2 Instance** (t3.micro) running PostgreSQL 15 on Amazon Linux 2023
- **Persistent EBS Volume** (10 GB gp3) for database data
- **IAM Permissions** for EC2 to read SQL initialization scripts from S3
- **Security Group** for SSH and PostgreSQL access
- **Automated Setup** including user creation, remote connections, and database initialization from an S3-hosted SQL script

## Files

### `postgresql_ec2_cloudformation.yaml`
The CloudFormation template that defines all AWS resources:
- **Security Group**: Allows SSH (port 22) and PostgreSQL (port 5432)
- **IAM Role & Instance Profile**: Grants EC2 permission to read from S3
- **EBS Volume**: Persistent 10 GB storage mounted at `/var/lib/pgsql/data`
- **EC2 Instance**: Runs PostgreSQL with automatic initialization

### `params.json`
Configuration parameters for the CloudFormation stack:
- `KeyName`: EC2 Key Pair for SSH access
- `VpcId`: Target VPC ID
- `SubnetId`: Target Subnet ID (must be in same AZ as the volume)
- `SQLScriptS3Path`: S3 path to your SQL initialization script (e.g., `s3://bucket/init.sql`)
- `DBAdminUser`: PostgreSQL superuser (default: `dbadmin`)
- `AppUser`: Application user account (default: `dev_user`)
- Passwords are set at deployment time

### `deploy.sh`
Bash script that automates the deployment process:
1. Prompts for database passwords (masked input)
2. Converts `params.json` to CloudFormation parameter format
3. Deploys the stack with `aws cloudformation deploy`
4. Retrieves and displays the PostgreSQL connection command
5. Optionally deletes the stack when done

## Prerequisites

- **AWS Account** with appropriate permissions (CloudFormation, EC2, IAM, EBS)
- **AWS CLI** installed and configured with a named profile
- **jq** for JSON parsing (used in `deploy.sh`)
- **EC2 Key Pair** already created in AWS
- **S3 bucket** containing your SQL initialization script
- **VPC and Subnet** already created in your AWS account

## Setup & Usage

### 1. Prepare Your SQL Script
Upload your SQL initialization script to S3:
```bash
aws s3 cp your_script.sql s3://your-bucket/create_statements.sql
```

### 2. Update `params.json`
Edit `params.json` with your AWS environment details:
```json
[
    {
        "ParameterKey": "KeyName",
        "ParameterValue": "your-key-pair-name"
    },
    {
        "ParameterKey": "VpcId",
        "ParameterValue": "vpc-xxxxxxxxx"
    },
    {
        "ParameterKey": "SubnetId",
        "ParameterValue": "subnet-xxxxxxxxx"
    },
    {
        "ParameterKey": "SQLScriptS3Path",
        "ParameterValue": "s3://your-bucket/create_statements.sql"
    },
    ...
]
```

### 3. Run the Deployment
```bash
chmod +x deploy.sh
./deploy.sh
```

The script will:
- Prompt for DB Admin and App User passwords
- Deploy the CloudFormation stack
- Display the PostgreSQL connection command upon completion
- Optionally clean up the stack

### 4. Connect to PostgreSQL
Use the connection command provided by the script:
```bash
psql -h <public-ip> -U <app-user> -d postgres
```

## Configuration

### EC2 Instance Size
Modify `InstanceType` in the template to change instance size (default: `t3.micro`).

### EBS Volume Size
Adjust the `Size` property of `PostgresDataVolume` (default: 10 GB).

### PostgreSQL Port
The default port is 5432. To change it, modify the security group ingress rule.

### SQL Initialization
Place your database creation statements in an SQL file and upload to S3. The `SQLScriptS3Path` parameter points to this file.

## Security Considerations

⚠️ **Security Groups**: The security group allows SSH and PostgreSQL connections from `0.0.0.0/0` (anywhere). For production:
- Restrict SSH to your IP address
- Restrict PostgreSQL access to application security groups only
- Use AWS Secrets Manager for password management

⚠️ **Passwords**: The deployment script prompts for passwords at runtime. Keep them secure and never commit them to version control.

## Cleanup

To delete the stack and avoid ongoing charges:
```bash
aws cloudformation delete-stack --profile <your-profile> --stack-name my-postgres-test-stack
```

Or use the optional cleanup prompt in the deployment script.

## Outputs

After deployment, CloudFormation provides:
- **InstancePublicIP**: The public IP address of your PostgreSQL server
- **PostgresLoginCommand**: Ready-to-use connection command

## Troubleshooting

### Stack Creation Fails
- Verify the subnet is in the same AZ as your intended volume
- Check AWS CLI profile is correctly configured
- Ensure IAM permissions allow CloudFormation, EC2, and IAM operations

### Can't Connect to Database
- Verify security group allows your IP on port 5432
- Check EC2 instance is running: `aws ec2 describe-instances`
- Verify PostgreSQL is running on the instance via SSH

### SQL Script Didn't Execute
- Confirm S3 path is correct and the bucket is readable by the EC2 IAM role
- Check that the SQL script exists and is properly formatted
- Review EC2 user data logs: `sudo tail -f /var/log/cloud-init-output.log`

## Licensing

This project is provided as-is for educational and testing purposes.
