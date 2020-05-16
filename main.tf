# Create a VPC
resource "aws_vpc" "ninja" {
  cidr_block = var.cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true
  instance_tenancy = "default"


  tags = {
    Name 	= var.name,
    Project	= var.project,
    Environment	= var.environment
  }
}

resource "aws_internet_gateway" "ninja" {
  vpc_id = aws_vpc.ninja.id
                   
  tags = merge(
    {         
      Name        = "Ninja_IGW",
      Project     = var.project,
      Environment = var.environment
    },        
    var.tags
  )         
}
    
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.ninja.id
  cidr_block        = var.private_subnet_cidr_blocks
  availability_zone = var.availability_zones
           
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
  vpc_id = aws_vpc.ninja.id
   
  tags = merge(
    {
      Name        = "PrivateRouteTable",
      Project     = var.project,
      Environment = var.environment
    },                                                                                                                                                        
    var.tags
  )
}  

resource "aws_route" "private" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.ninja.id
}     
          
resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}     
 
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.ninja.id
  cidr_block              = var.public_subnet_cidr_blocks
  availability_zone       = var.availability_zones
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
      Name        = "PublicRouteTable",
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
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

#### NAT GATEWAY ####

resource "aws_eip" "nat" {
  vpc = true
  
  tags = merge(
    {
      Name        = "ninja_EIP",
      Project     = var.project,
      Environment = var.environment
    },
    var.tags
  )
}    
 
  
resource "aws_nat_gateway" "ninja" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id
  
  tags = merge(
    {
      Name        = "ninja_NATGW",
      Project     = var.project,
      Environment = var.environment
    },
    var.tags
  )
}              
