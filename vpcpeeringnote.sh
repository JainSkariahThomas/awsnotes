   aws ec2 create-vpc --cidr-block 188.78.0.0/16
   aws ec2 create-tags --resources vpc-01b3df3220dd0b555 --tags Key=Name,Value=interneton
   aws ec2 modify-vpc-attribute --vpc-id vpc-01b3df3220dd0b555 --enable-dns-hostnames "{\"Value\":true}"
   aws ec2 create-internet-gateway
   aws ec2 create-tags --resources igw-0e11e0488195a460c --tags Key=Name,Value=vpconeconnection
   aws ec2 attach-internet-gateway --internet-gateway-id igw-0e11e0488195a460c --vpc-id vpc-01b3df3220dd0b555
aws configure and change the region
aws ec2 create-vpc --cidr-block 188.79.0.0/16
aws ec2 create-tags --resources vpc-09efbc483a1cb1d53 --tags Key=Name,Value=privateconnection

echo "Now switch back to defult region where internetgateway is created"

aws ec2 create-vpc-peering-connection --vpc-id vpc-01b3df3220dd0b555 --peer-vpc-id vpc-09efbc483a1cb1d53 --peer-region us-east-1

echo "Now swicth to private vpc region and accept the peering connection"

aws ec2 accept-vpc-peering-connection --vpc-peering-connection-id pcx-04f4bf6b91adabbb3
aws ec2 describe-availability-zones
aws ec2 create-subnet --vpc-id vpc-09efbc483a1cb1d53 --cidr-block 188.79.0.0/20 --availability-zone us-east-1a
aws ec2 create-tags --resources subnet-091510d626c7d7b1f --tags Key=Name,Value=databaseprivate
aws ec2 create-route-table --vpc-id vpc-09efbc483a1cb1d53
aws ec2 create-tags --resources rtb-07723c63200581e29 --tags Key=Name,Value=privateroutdata
aws ec2 create-route --route-table-id rtb-07723c63200581e29 --destination-cidr-block 188.78.0.0/16 --vpc-peering-connection-id pcx-04f4bf6b91adabbb3
aws ec2 associate-route-table --route-table-id rtb-07723c63200581e29 --subnet-id subnet-091510d626c7d7b1f
aws ec2 create-security-group --group-name Firstinstance1 --description "port 22 allowed" --vpc-id vpc-09efbc483a1cb1d53
aws ec2 authorize-security-group-ingress --group-id sg-0aa4762cb9acb7a1e --protocol tcp --port 22 --cidr 188.78.0.0/16
aws ec2 authorize-security-group-ingress --group-id sg-0aa4762cb9acb7a1e --protocol tcp --port 22 --cidr 188.78.0.0/20
aws ec2 authorize-security-group-ingress --group-id sg-0aa4762cb9acb7a1e --protocol tcp --port 3306 --cidr 188.78.0.0/20
aws ec2 authorize-security-group-ingress --group-id sg-0aa4762cb9acb7a1e --protocol tcp --port 3306 --cidr 188.78.0.0/16
aws ec2 run-instances --image-id ami-062f7200baf2fa504 --subnet-id subnet-091510d626c7d7b1f --key-name awssystem2office --security-group-ids sg-0aa4762cb9acb7a1e --instance-type t2.micro --placement AvailabilityZone=us-east-1a

Now switch to defult vpc region and execute below commands


aws ec2 describe-availability-zones
aws ec2 create-subnet --vpc-id vpc-01b3df3220dd0b555 --cidr-block 188.78.0.0/20 --availability-zone us-east-2a
aws ec2 create-tags --resources subnet-0adb2fe49189dd853 --tags Key=Name,Value=webserver
aws ec2 create-route-table --vpc-id vpc-01b3df3220dd0b555
aws ec2 create-tags --resources rtb-0582c976ea96bd8aa --tags Key=Name,Value=webserverrout
aws ec2 create-route --route-table-id rtb-0582c976ea96bd8aa --destination-cidr-block 0.0.0.0/0 --gateway-id igw-0e11e0488195a460c
aws ec2 create-route --route-table-id rtb-0582c976ea96bd8aa --destination-cidr-block 188.79.0.0/16 --vpc-peering-connection-id pcx-04f4bf6b91adabbb3
aws ec2 associate-route-table --route-table-id rtb-0582c976ea96bd8aa --subnet-id subnet-0adb2fe49189dd853
aws ec2 create-security-group --group-name Firstinstance1 --description "port 22 allowed" --vpc-id vpc-01b3df3220dd0b555
aws ec2 authorize-security-group-ingress --group-id sg-0bd96466f21988fea --protocol tcp --port 22 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id sg-0bd96466f21988fea --protocol tcp --port 80 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id sg-0bd96466f21988fea --protocol tcp --port 443 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id sg-0bd96466f21988fea --protocol tcp --port 3306 --cidr 188.78.0.0/16
aws ec2 authorize-security-group-ingress --group-id sg-0bd96466f21988fea --protocol tcp --port 3306 --cidr 188.78.0.0/20
aws ec2 modify-subnet-attribute --subnet-id subnet-0adb2fe49189dd853 --map-public-ip-on-launch
aws ec2 run-instances --image-id ami-02ccb28830b645a41 --subnet-id subnet-0adb2fe49189dd853 --key-name awsofficekey --security-group-ids sg-0bd96466f21988fea --instance-type t2.micro --placement AvailabilityZone=us-east-2a

