##### This will create a simple VPC with Public/Private Subnets and NAT Gateway with EIP #####

resource "aws_vpc" "vpc" {
  cidr_block           = var.cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true
  instance_tenancy     = "default"

  tags = merge(
    {
      Name        = var.name,
      Project     = var.project,
      Environment = var.environment
    },
    var.tags
  )
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = merge(
    {
      Name        = var.igw,
      Project     = var.project,
      Environment = var.environment
    },
    var.tags
  )
}

##### PRIVATE CONFIGURATION #####

resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidr_blocks)
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.private_subnet_cidr_blocks[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = merge(
    {
      Name        = "Private_Subnet",
      Project     = var.project,
      Environment = var.environment
    },
    var.tags
  )
}

resource "aws_route_table" "private" {
  count  = length(var.private_subnet_cidr_blocks)
  vpc_id = aws_vpc.vpc.id

  tags = merge(
    {
      Name        = "Private_RT",
      Project     = var.project,
      Environment = var.environment
    },
    var.tags
  )
}

resource "aws_route" "private" {
  count                  = length(var.private_subnet_cidr_blocks)
  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.natgw[count.index].id
}

resource "aws_route_table_association" "private" {
  count          = length(var.private_subnet_cidr_blocks)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

##### PUBLIC CONFIGURATION #####

resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidr_blocks)
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.public_subnet_cidr_blocks[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = merge(
    {
      Name        = "Public_Subnet",
      Project     = var.project,
      Environment = var.environment
    },
    var.tags
  )
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id

  tags = merge(
    {
      Name        = "Public_RT",
      Project     = var.project,
      Environment = var.environment
    },
    var.tags
  )
}

resource "aws_route" "public" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public" {
  count          = length(var.public_subnet_cidr_blocks)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_main_route_table_association" "main" {
  vpc_id         = aws_vpc.vpc.id
  route_table_id = aws_route_table.public.id
}

##### NAT GATEWAY #####

resource "aws_eip" "nat" {
  count = length(var.public_subnet_cidr_blocks)
  vpc   = true

  tags = merge(
    {
      Name        = "Ninja_EIP",
      Project     = var.project,
      Environment = var.environment
    },
    var.tags
  )
}

resource "aws_nat_gateway" "natgw" {
  count         = length(var.public_subnet_cidr_blocks)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(
    {
      Name        = "Ninja_NATGW",
      Project     = var.project,
      Environment = var.environment
    },
    var.tags
  )
}

##### VPC ENDPOINT #####

resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.vpc.id
  service_name = "com.amazonaws.${var.region}.s3"
  route_table_ids = flatten([
    aws_route_table.public.id,
    aws_route_table.private.*.id
  ])

  tags = merge(
    {
      Name        = "VPC_EP_S3",
      Project     = var.project,
      Environment = var.environment
    },
    var.tags
  )
}

##### EFS ####

resource "aws_security_group" "allow_tls" {
  name        = "Allow NFS"
  description = "Allow NFS inbound traffic from VPC"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description = "NFS from VPC"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    {
      Name        = "EFS-ALLOW-FROM-VPC",
      Project     = var.project,
      Environment = var.environment
    },
    var.tags
  )
}

resource "aws_efs_file_system" "efs" {
  creation_token = "efs-ecs"
  encrypted      = var.encrypted

  tags = merge(
    {
      Name        = "EFS-ECS",
      Project     = var.project,
      Environment = var.environment
    },
    var.tags
  )
}

resource "aws_efs_mount_target" "efs_target" {
  count = length(var.private_subnet_cidr_blocks)

  file_system_id  = aws_efs_file_system.efs.id
  subnet_id       = aws_subnet.private[count.index].id
  security_groups = [aws_security_group.allow_tls.id]
}
