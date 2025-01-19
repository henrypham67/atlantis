# Variables
CIDR_BLOCK=10.0.0.0/16
SUBNET_CIDR_BLOCK=10.0.1.0/24
REGION=us-east-1
VPC_NAME=atlantis-vpc
SUBNET_NAME=atlantis-public-subnet-1a
AVAILABILITY_ZONE=us-east-1a

# Commands
.PHONY: docker aws random create_vpc destroy_vpc

docker:
	docker compose up -d

aws:
	cd self-infra && \
	terraform init && \
	terraform apply --auto-approve

random:
	@echo $$(echo $$RANDOM$$RANDOM | md5sum | head -c 12)

create-vpc:
	@echo "Creating VPC..."
	$(eval VPC_ID := $(shell aws ec2 create-vpc --cidr-block 10.0.0.0/16 --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=atlantis-vpc}]' --query 'Vpc.VpcId' --output text 2>/dev/null))
	@echo "Created VPC: $(VPC_ID)"

	@echo "Enabling DNS support and hostnames..."
	aws ec2 modify-vpc-attribute --vpc-id $(VPC_ID) --enable-dns-support > /dev/null 2>&1
	aws ec2 modify-vpc-attribute --vpc-id $(VPC_ID) --enable-dns-hostnames > /dev/null 2>&1

	@echo "Creating Internet Gateway..."
	$(eval IGW_ID := $(shell aws ec2 create-internet-gateway --tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value=atlantis-igw}]' --query 'InternetGateway.InternetGatewayId' --output text 2>/dev/null))
	aws ec2 attach-internet-gateway --internet-gateway-id $(IGW_ID) --vpc-id $(VPC_ID) > /dev/null 2>&1
	@echo "Created and attached Internet Gateway: $(IGW_ID)"

	@echo "Creating Route Table..."
	$(eval RT_ID := $(shell aws ec2 create-route-table --vpc-id $(VPC_ID) --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=atlantis-public-rt}]' --query 'RouteTable.RouteTableId' --output text 2>/dev/null))
	aws ec2 create-route --route-table-id $(RT_ID) --destination-cidr-block 0.0.0.0/0 --gateway-id $(IGW_ID) > /dev/null 2>&1
	@echo "Created Route Table: $(RT_ID)"

	@echo "Creating Public Subnet in us-east-1a..."
	$(eval SUBNET_ID := $(shell aws ec2 create-subnet --vpc-id $(VPC_ID) --cidr-block 10.0.1.0/24 --availability-zone us-east-1a --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=atlantis-public-subnet-1a}]' --query 'Subnet.SubnetId' --output text 2>/dev/null))
	aws ec2 associate-route-table --route-table-id $(RT_ID) --subnet-id $(SUBNET_ID) > /dev/null 2>&1
	aws ec2 modify-subnet-attribute --subnet-id $(SUBNET_ID) --map-public-ip-on-launch > /dev/null 2>&1
	@echo "Created Public Subnet: $(SUBNET_ID)"

destroy-vpc:
	@echo "Fetching resources for cleanup..."

	# Fetch the VPC ID based on the name tag
	$(eval VPC_ID := $(shell aws ec2 describe-vpcs --filters "Name=tag:Name,Values=atlantis-vpc" --query "Vpcs[0].VpcId" --output text))
	@echo "VPC ID: $(VPC_ID)"

	# Fetch Internet Gateway ID
	$(eval IGW_ID := $(shell aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$(VPC_ID)" --query "InternetGateways[0].InternetGatewayId" --output text))
	@echo "Internet Gateway ID: $(IGW_ID)"

	# Fetch Route Table ID
	$(eval RT_ID := $(shell aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$(VPC_ID)" "Name=tag:Name,Values=atlantis-public-rt" --query "RouteTables[0].RouteTableId" --output text))
	@echo "Route Table ID: $(RT_ID)"

	# Fetch Subnet ID
	$(eval SUBNET_ID := $(shell aws ec2 describe-subnets --filters "Name=vpc-id,Values=$(VPC_ID)" "Name=tag:Name,Values=atlantis-public-subnet-1a" --query "Subnets[0].SubnetId" --output text))
	@echo "Subnet ID: $(SUBNET_ID)"

	@echo "Starting resource cleanup..."

	# Delete Subnet
	aws ec2 delete-subnet --subnet-id $(SUBNET_ID)
	@echo "Deleted Subnet: $(SUBNET_ID)"

	# Delete Route from Route Table
	aws ec2 delete-route --route-table-id $(RT_ID) --destination-cidr-block 0.0.0.0/0
	@echo "Deleted Route from Route Table: $(RT_ID)"

	# Delete Route Table
	aws ec2 delete-route-table --route-table-id $(RT_ID)
	@echo "Deleted Route Table: $(RT_ID)"

	# Detach Internet Gateway
	aws ec2 detach-internet-gateway --internet-gateway-id $(IGW_ID) --vpc-id $(VPC_ID)
	@echo "Detached Internet Gateway: $(IGW_ID)"

	# Delete Internet Gateway
	aws ec2 delete-internet-gateway --internet-gateway-id $(IGW_ID)
	@echo "Deleted Internet Gateway: $(IGW_ID)"

	# Delete VPC
	aws ec2 delete-vpc --vpc-id $(VPC_ID)
	@echo "Deleted VPC: $(VPC_ID)"

