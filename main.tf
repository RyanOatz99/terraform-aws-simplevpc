##### This will create a simple VPC with Public/Private Subnets and NAT Gateway with EIP #####

resource "aws_vpc" "ninja" {
  cidr_block = var.cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true
  instance_tenancy = "default"

  tags = merge(                                                                                                                                               
    {
      Name        = var.name,
      Project     = var.project,
      Environment = var.environment
    },
    var.tags
  )
}

resource "aws_internet_gateway" "ninja" {
  vpc_id = aws_vpc.ninja.id
  
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
  count = length(var.private_subnet_cidr_blocks)
  vpc_id                  = aws_vpc.ninja.id
  cidr_block              = var.private_subnet_cidr_blocks[count.index]
  availability_zone       = var.availability_zones[count.index]
                                                                                                                                                              
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
  count = length(var.private_subnet_cidr_blocks)
  vpc_id = aws_vpc.ninja.id
   
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
  count = length(var.private_subnet_cidr_blocks)
  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.ninja[count.index].id
}     
          
resource "aws_route_table_association" "private" {
  count = length(var.private_subnet_cidr_blocks)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}     

##### PUBLIC CONFIGURATION #####
 
resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidr_blocks)
  vpc_id                  = aws_vpc.ninja.id
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
  vpc_id = aws_vpc.ninja.id
   
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
  gateway_id             = aws_internet_gateway.ninja.id
}  

resource "aws_route_table_association" "public" {
  count = length(var.public_subnet_cidr_blocks)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_main_route_table_association" "main" {
  vpc_id         = aws_vpc.ninja.id 
  route_table_id = aws_route_table.public.id
}

##### NAT GATEWAY #####

resource "aws_eip" "nat" {
  count = length(var.public_subnet_cidr_blocks)
  vpc = true
  
  tags = merge(
    {
      Name        = "Ninja_EIP",
      Project     = var.project,
      Environment = var.environment
    },
    var.tags
  )
}    
 
resource "aws_nat_gateway" "ninja" {
  count = length(var.public_subnet_cidr_blocks)
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

resource "aws_network_acl" "ninja" {
  vpc_id = aws_vpc.ninja.id

  tags = merge(            
    {                      
      Name        = "Ninja_NACL",
      Project     = var.project,
      Environment = var.environment 
    },                     
    var.tags               
  )                        
}        
              
