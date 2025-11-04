# Production Environment Variables
environment  = "prod"
project_name = "Prod"
location     = "East US"

# Tagging
owner       = "TF-Cloud Infrastructure"
cost_center = "company1"

# Virtual Network Configuration (Production - separate address space)
vnet_address_space = ["0.0.0.0/16"]

# Subnet Configuration for different tiers
subnets = {
  firewall = {
    address_prefixes = ["0.0.0.0/24"]
    description      = "Subnet for firewall and security appliances"
  }
  web = {
    address_prefixes = ["0.0.0.0/24"]
    description      = "Subnet for web servers"
  }
  app = {
    address_prefixes = ["0.0.0.0/24"]  
    description      = "Subnet for application servers"
  }
  db = {
    address_prefixes = ["0.0.0.0/24"]
    description      = "Subnet for database servers"
  }
}
