# -----------------------
# RESOURCE GROUP
# -----------------------
variable "resource_group_name" {
  type        = string
  description = "Azure Resource Group name"
}

variable "location" {
  type        = string
  description = "Azure region"
  default     = "southeastasia"
}

# -----------------------
# NETWORK
# -----------------------
variable "vnet_name" {
  type        = string
  description = "Virtual Network name"
  default     = "sports-rental-vnet"
}

variable "vnet_address_space" {
  type        = list(string)
  description = "VNet address space"
  default     = ["10.0.0.0/16"]
}

variable "subnet_name" {
  type        = string
  description = "Subnet name"
  default     = "default"
}

variable "subnet_address_prefixes" {
  type        = list(string)
  description = "Subnet CIDR"
  default     = ["10.0.1.0/24"]
}

# -----------------------
# PUBLIC IP / NSG / NIC
# -----------------------
variable "public_ip_name" {
  type        = string
  description = "Public IP name"
  default     = "sports-rental-pip"
}

variable "nsg_name" {
  type        = string
  description = "Network Security Group name"
  default     = "sports-rental-nsg"
}

variable "nic_name" {
  type        = string
  description = "Network Interface name"
  default     = "sports-rental-nic"
}

# -----------------------
# VM CONFIG
# -----------------------
variable "vm_name" {
  type        = string
  description = "Virtual Machine name"
  default     = "vm-sport-web"
}

variable "vm_size" {
  type        = string
  description = "VM size"
  default     = "Standard_B1s"
}

variable "admin_username" {
  type        = string
  description = "Admin username for VM"
  default     = "azureuser"
}

variable "ssh_public_key_path" {
  type        = string
  description = "Path to SSH public key (e.g. ~/.ssh/id_rsa.pub)"
}

# -----------------------
# APPLICATION
# -----------------------
variable "repo_url" {
  type        = string
  description = "GitHub repository URL for web application"
  default     = "https://github.com/Teerawatgg/web_sport_customer.git"
}

# -----------------------
# DATABASE
# -----------------------
variable "db_name" {
  type        = string
  description = "Database name"
  default     = "sports_rental_system"
}

variable "db_user" {
  type        = string
  description = "Database username"
  default     = "sports_user"
}

variable "db_password" {
  type        = string
  description = "Database password"
  sensitive   = true
}