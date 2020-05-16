variable "name" {
  default     = "Ninja_VPC"
  type        = string
  description = "Ninja Games Day VPC"
}

variable "project" {
  type        = string
  description = "Name of project this VPC is meant to house"
}

variable "environment" {
  type        = string
  description = "Name of environment this VPC is targeting"
}

variable "region" {
  default     = "us-east-1"
  type        = string
  description = "Region of the VPC"
}

variable "cidr_block" {
  default     = "10.0.0.0/16"
  type        = string
  description = "CIDR block for the VPC"
}

variable "public_subnet_cidr_blocks" {
  default     = "10.0.0.0/24"
  type        = string
  description = "List of public subnet CIDR blocks"
}

variable "private_subnet_cidr_blocks" {
  default     = "10.0.1.0/24"
  type        = string
  description = "List of private subnet CIDR blocks"
}

variable "availability_zones" {
  default     = "us-east-1a"
  type        = string
  description = "List of availability zones"
}

variable "tags" {
  default     = {}
  type        = map(string)
  description = "Extra tags to attach to the VPC resources"
}

