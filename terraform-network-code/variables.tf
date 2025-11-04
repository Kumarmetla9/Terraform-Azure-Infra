# Core Variables
variable "environment" {
  description = "Environment name (e.g., dev, test, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "test", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, test, staging, prod."
  }
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "location" {
  description = "Azure region where resources will be created"
  type        = string
  default     = "East US"
}

# Tagging Variables
variable "owner" {
  description = "Owner of the resources"
  type        = string
}

variable "cost_center" {
  description = "Cost center for billing purposes"
  type        = string
}

# Virtual Network Variables
variable "vnet_address_space" {
  description = "Address space for the virtual network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnets" {
  description = "Map of subnets to create"
  type = map(object({
    address_prefixes = list(string)
    description      = string
  }))
  default = {
    firewall = {
      address_prefixes = ["10.0.0.0/24"]
      description      = "Subnet for firewall and security appliances"
    }
    web = {
      address_prefixes = ["10.0.1.0/24"]
      description      = "Subnet for web servers"
    }
    app = {
      address_prefixes = ["10.0.2.0/24"]
      description      = "Subnet for application servers"
    }
    db = {
      address_prefixes = ["10.0.3.0/24"]
      description      = "Subnet for database servers"
    }
  }
}

# Network Security Group Rules Variables
variable "nsg_rules" {
  description = "Map of NSG rules for different subnet tiers"
  type = map(object({
    inbound_rules = list(object({
      name                       = string
      priority                   = number
      direction                  = string
      access                     = string
      protocol                   = string
      source_port_range          = string
      destination_port_range     = optional(string)
      destination_port_ranges    = optional(list(string))
      source_address_prefix      = optional(string)
      source_address_prefixes    = optional(list(string))
      destination_address_prefix = string
    }))
    outbound_rules = list(object({
      name                       = string
      priority                   = number
      direction                  = string
      access                     = string
      protocol                   = string
      source_port_range          = string
      destination_port_range     = string
      source_address_prefix      = string
      destination_address_prefix = string
    }))
  }))
}