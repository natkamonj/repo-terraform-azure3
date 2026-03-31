resource_group_name = "rg-sports-rental"
location            = "southeastasia"

vnet_name               = "sports-rental-vnet"
vnet_address_space      = ["10.0.0.0/16"]
subnet_name             = "default"
subnet_address_prefixes = ["10.0.1.0/24"]

public_ip_name    = "sports-rental-pip"

nsg_name = "sports-rental-nsg"
nic_name = "sports-rental-nic"

vm_name  = "vm-sport-web"
vm_size  = "Standard_D2s_v3"

admin_username      = "azureuser"
ssh_public_key_path = "~/.ssh/id_rsa.pub"

repo_url   = "https://github.com/natkamonj/web_sport_customer.git"


db_name     = "sports_rental_system"
db_user     = "sports_user"
db_password = "YourStrongPassword123!"

