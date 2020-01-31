#!/bin/bash
echo "This script is to setup vpc peering and provision ec2 instance"

read -p "The vpc Name for the Project =" Publicvpc

read -p "Please enter the cidrBlock =" vpcCidrBlock
read -p "Please enter the subnet associted with the cidrbloc = " subnetipadd

vpcId=`aws ec2 create-vpc --cidr-block $vpcCidrBlock --query 'Vpc.VpcId' --output text`
aws ec2 create-tags --resources $vpcId --tags Key=Name,Value=$Publicvpc

echo "Enabling DNS Hostname for the VPC"

aws ec2 modify-vpc-attribute --vpc-id $vpcId --enable-dns-hostnames "{\"Value\":true}"
echo "Creting Internet Gateway for the VPC"
read -p "Choose InternetGateway name = " internetgateway
internetGatewayId=`aws ec2 create-internet-gateway --query 'InternetGateway.InternetGatewayId' --output text` 
aws ec2 create-tags --resources $internetGatewayId --tags Key=Name,Value=$internetgateway
echo " Attaching the Internet Gateway to the VPC"
aws ec2 attach-internet-gateway --internet-gateway-id $internetGatewayId --vpc-id $vpcId


echo " Swicthing to second region virgina " 

read -p "The vpc Name for the Project =" PrivateVPC
read -p "Please enter the cidrBlock =" PrivateCidrBlock
read -p "Please enter the subnet associted with the cidrbloc = " Privatesubnetipadd

PrivatevpcId=`aws ec2 create-vpc --cidr-block $vpcCidrBlock --profile virginaaccount --query 'Vpc.VpcId' --output text`
aws ec2 create-tags --resources $PrivatevpcId --tags Key=Name,Value=$PrivateVPC --profile virginaaccount


echo "Now switch back to defult region where internetgateway is created"

VPCpeeringID=`aws ec2 create-vpc-peering-connection --vpc-id $vpcId --peer-vpc-id $PrivatevpcId --peer-region us-east-1 --query 'VpcPeeringConnection.VpcPeeringConnectionId' --output text`

echo "Now swicth to private vpc region and accept the peering connection"

aws ec2 accept-vpc-peering-connection --vpc-peering-connection-id $VPCpeeringID --profile virginaaccount
echo "Creating the Subnet associated with the VPC"
aws ec2 describe-availability-zones --profile virginaaccount
read -p "Please mention the subnet = " PrivateAZsub

Privatesubnetid=`aws ec2 create-subnet --vpc-id $PrivatevpcId --cidr-block $Privatesubnetipadd --availability-zone $PrivateAZsub --query 'Subnet.SubnetId' --output text` --profile virginaaccount

read -p "Please enter the subnet name = " Privatesubnetname
aws ec2 create-tags --resources $Privatesubnetid --tags Key=Name,Value=$Privatesubnetname --profile virginaaccount

echo "Creating RouteTable for the VPC"
read -p "Please enter the router table name = " PrivaterouterName

PrivateRouteTable=`aws ec2 create-route-table --vpc-id $PrivatevpcId --query 'RouteTable.RouteTableId' --output text` --profile virginaaccount
aws ec2 create-tags --resources $PrivateRouteTable --tags Key=Name,Value=$PrivaterouterName --profile virginaaccount

echo "Setting up associated-route-table"
AssociationIdPrivate=`aws ec2 associate-route-table --route-table-id $PrivateRouteTable --subnet-id $Privatesubnetid --query 'AssociationId' --output text` --profile virginaaccount

echo "Creating a route Table"
aws ec2 create-route --route-table-id $PrivateRouteTable --destination-cidr-block $vpcCidrBlock --vpc-peering-connection-id $VPCpeeringID --profile virginaaccount

read -p "First security rule name = " Firstinstance1
read -p "Second security rule name = " Secondinstance2
Privatesecurityid=`aws ec2 create-security-group --group-name $Firstinstance1 --description "port 22 allowed" --vpc-id $PrivatevpcId --query 'GroupId' --output text` --profile virginaaccount
aws ec2 authorize-security-group-ingress --group-id $Privatesecurityid --protocol tcp --port 22 --cidr $vpcCidrBlock --profile virginaaccount
aws ec2 authorize-security-group-ingress --group-id $Privatesecurityid --protocol tcp --port 22 --cidr $subnetipadd --profile virginaaccount
aws ec2 authorize-security-group-ingress --group-id $Privatesecurityid --protocol tcp --port 3306 --cidr $subnetipadd --profile virginaaccount
aws ec2 authorize-security-group-ingress --group-id $Privatesecurityid --protocol tcp --port 3306 --cidr $subnetipadd --profile virginaaccount
read -p "Please mention the ec2instance name = " MyInstance1

aws ec2 run-instances --image-id ami-062f7200baf2fa504 --subnet-id $Privatesubnetid --key-name awssystem2office --security-group-ids $Privatesecurityid --instance-type t2.micro --placement AvailabilityZone=$PrivateAZsub --profile virginaaccount

echo "Now switch to defult vpc region and execute below commands"

aws ec2 describe-availability-zones
read -p "Please mention the subnet = " PublicDcAZ
Publicsubnetid=`aws ec2 create-subnet --vpc-id $vpcId --cidr-block $subnetipadd --availability-zone $PublicDcAZ --query 'Subnet.SubnetId' --output text`
read -p "Please enter the subnet name = " Publicsubnetname
aws ec2 create-tags --resources $Publicsubnetid --tags Key=Name,Value=$Publicsubnetname

echo "Creating RouteTable for the VPC"
read -p "Please enter the router table name = " Publicrouterfirst

RouteTable1=`aws ec2 create-route-table --vpc-id $vpcId --query 'RouteTable.RouteTableId' --output text`
aws ec2 create-tags --resources $RouteTable1 --tags Key=Name,Value=$Publicrouterfirst

echo "Setting up associated-route-table"
PublicassociationId1=`aws ec2 associate-route-table --route-table-id $RouteTable1 --subnet-id $Publicsubnetid --query 'AssociationId' --output text`

echo "Creating a route Table"
aws ec2 create-route --route-table-id $RouteTable1 --destination-cidr-block 0.0.0.0/0 --gateway-id $internetGatewayId
aws ec2 create-route --route-table-id $RouteTable1 --destination-cidr-block $PrivateCidrBlock --vpc-peering-connection-id $VPCpeeringID
PublicsecurityID=`aws ec2 create-security-group --group-name $Secondinstance2 --description "port 22 allowed from internal" --vpc-id $vpcId --query 'GroupId' --output text`


aws ec2 authorize-security-group-ingress --group-id $PublicsecurityID --protocol tcp --port 22 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $PublicsecurityID --protocol tcp --port 80 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $PublicsecurityID --protocol tcp --port 443 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $PublicsecurityID --protocol tcp --port 3306 --cidr $vpcCidrBlock
aws ec2 authorize-security-group-ingress --group-id $PublicsecurityID --protocol tcp --port 3306 --cidr $subnetipadd
aws ec2 modify-subnet-attribute --subnet-id $Publicsubnetid --map-public-ip-on-launch
aws ec2 run-instances --image-id ami-02ccb28830b645a41 --subnet-id $Publicsubnetid --key-name awsofficekey --security-group-ids PublicsecurityID --instance-type t2.micro --placement AvailabilityZone=$PublicDcAZ
