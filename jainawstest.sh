#!/bin/bash

echo "aws-cli-key setup"

aws ec2 create-key-pair --key-name MyKeyPair5 --query 'KeyMaterial' --output text > MyKeyPair5.pem

echo "Adding security rules"

aws ec2 create-security-group --group-name my-aws-class-one --description "My security group"
aws ec2 authorize-security-group-ingress --group-name my-aws-class-one --protocol tcp --port 22 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-name my-aws-class-one --protocol tcp --port 80 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-name my-aws-class-one --protocol tcp --port 443 --cidr 0.0.0.0/0 
echo "setting up ec2 instance with additional ebs and mounting"
aws ec2 run-instances --image-id ami-0217a85e28e625474 --key-name MyKeyPair5 --security-groups my-aws-class-one --instance-type t2.micro --placement AvailabilityZone=ap-south-1a --block-device-mappings DeviceName=/dev/sdb,Ebs={VolumeSize=1} --count 1 --tag-specifications 'ResourceType=volume,Tags=[{Key=Name,Value=clivolume}]' --user-data file:///home/adminz/JAINAWS/Docker/install.txt

echo "Provison finsihed"
