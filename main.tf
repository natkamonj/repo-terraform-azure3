terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.117"
    }
  }
}
provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = var.vnet_address_space
}

resource "azurerm_subnet" "subnet" {
  name                 = var.subnet_name
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.subnet_address_prefixes
}

resource "azurerm_public_ip" "pip" {
  name                = var.public_ip_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_security_group" "nsg" {
  name                = var.nsg_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "allow-http"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-ssh"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface" "nic" {
  name                = var.nic_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip.id
  }
}

resource "azurerm_network_interface_security_group_association" "nsg_assoc" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                = var.vm_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  size                = var.vm_size
  admin_username      = var.admin_username

  network_interface_ids = [
    azurerm_network_interface.nic.id
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(var.ssh_public_key_path)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  custom_data = local.custom_data

  disable_password_authentication = true
}


locals {
  cloud_init = <<-CLOUDCONFIG
#cloud-config
package_update: true
package_upgrade: false

packages:
  - apache2
  - php
  - php-mysql
  - mariadb-server
  - git

write_files:
  - path: /usr/local/bin/websport-deploy.sh
    permissions: '0755'
    content: |
      #!/bin/bash
      set -x
      exec > >(tee -a /var/log/websport-deploy.log) 2>&1

      echo "===== START DEPLOY ====="

      systemctl enable apache2
      systemctl start apache2
      systemctl enable mariadb
      systemctl start mariadb

      until mysqladmin ping --silent; do
        sleep 2
      done

      mysql -e "CREATE DATABASE IF NOT EXISTS \`${var.db_name}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" || true
      mysql -e "CREATE USER IF NOT EXISTS '${var.db_user}'@'localhost' IDENTIFIED BY '${var.db_password}';" || true
      mysql -e "GRANT ALL PRIVILEGES ON \`${var.db_name}\`.* TO '${var.db_user}'@'localhost';" || true
      mysql -e "FLUSH PRIVILEGES;" || true

      rm -rf /opt/web_sport_customer
      git clone "${var.repo_url}" /opt/web_sport_customer

      if [ -f /opt/web_sport_customer/sports_rental_system.sql ]; then
        mysql "${var.db_name}" < /opt/web_sport_customer/sports_rental_system.sql || true
      fi

      rm -rf /var/www/html/*
      cp -R /opt/web_sport_customer/* /var/www/html/

      chown -R www-data:www-data /var/www/html
      find /var/www/html -type d -exec chmod 755 {} \;
      find /var/www/html -type f -exec chmod 644 {} \;

      cat > /var/www/html/database.php <<EOF
      <?php
      \$conn = new mysqli("localhost", "${var.db_user}", "${var.db_password}", "${var.db_name}");
      if (\$conn->connect_error) {
          die("Connection failed: " . \$conn->connect_error);
      }
      \$conn->set_charset("utf8mb4");
      ?>
      EOF

      for d in customer staff executive warehouse rector; do
        if [ -d "/var/www/html/$d" ]; then
          cp /var/www/html/database.php "/var/www/html/$d/database.php" || true
        fi
      done

      # -----------------------------
      # FIX PATHS IN CUSTOMER
      # -----------------------------
      if [ -d /var/www/html/customer ]; then
        find /var/www/html/customer -type f \( -name "*.js" -o -name "*.ts" -o -name "*.html" -o -name "*.php" \) -exec sed -i \
          -e 's|/sports_rental_system/customer/api/|/customer/api/|g' \
          -e 's|sports_rental_system/customer/api/|/customer/api/|g' \
          -e 's|/sports_rental_system/uploads/equipment/|/uploads/equipment/|g' \
          -e 's|sports_rental_system/uploads/equipment/|/uploads/equipment/|g' \
          -e 's|/sports_rental_system/uploads/field/B001/|/uploads/field/B001/|g' \
          -e 's|/sports_rental_system/uploads/field/B002/|/uploads/field/B002/|g' \
          -e 's|/sports_rental_system/uploads/field/B003/|/uploads/field/B003/|g' \
          -e 's|/sports_rental_system/uploads/field/B004/|/uploads/field/B004/|g' \
          -e 's|/sports_rental_system/uploads/field/B010/|/uploads/field/B010/|g' \
          -e 's|sports_rental_system/uploads/field/B001/|/uploads/field/B001/|g' \
          -e 's|sports_rental_system/uploads/field/B002/|/uploads/field/B002/|g' \
          -e 's|sports_rental_system/uploads/field/B003/|/uploads/field/B003/|g' \
          -e 's|sports_rental_system/uploads/field/B004/|/uploads/field/B004/|g' \
          -e 's|sports_rental_system/uploads/field/B010/|/uploads/field/B010/|g' \
          -e 's|/sports_rental_system/uploads/|/uploads/|g' \
          -e 's|sports_rental_system/uploads/|/uploads/|g' {} + || true
      fi

      # -----------------------------
      # FIX PATHS IN STAFF
      # -----------------------------
      if [ -d /var/www/html/staff ]; then
        find /var/www/html/staff -type f \( -name "*.js" -o -name "*.ts" -o -name "*.html" -o -name "*.php" \) -exec sed -i \
          -e 's|/sports_rental_system/staff/api/|/staff/api/|g' \
          -e 's|sports_rental_system/staff/api/|/staff/api/|g' \
          -e 's|/sports_rental_system/uploads/equipment/|/uploads/equipment/|g' \
          -e 's|sports_rental_system/uploads/equipment/|/uploads/equipment/|g' \
          -e 's|/sports_rental_system/uploads/field/B001/|/uploads/field/B001/|g' \
          -e 's|/sports_rental_system/uploads/field/B002/|/uploads/field/B002/|g' \
          -e 's|/sports_rental_system/uploads/field/B003/|/uploads/field/B003/|g' \
          -e 's|/sports_rental_system/uploads/field/B004/|/uploads/field/B004/|g' \
          -e 's|/sports_rental_system/uploads/field/B010/|/uploads/field/B010/|g' \
          -e 's|sports_rental_system/uploads/field/B001/|/uploads/field/B001/|g' \
          -e 's|sports_rental_system/uploads/field/B002/|/uploads/field/B002/|g' \
          -e 's|sports_rental_system/uploads/field/B003/|/uploads/field/B003/|g' \
          -e 's|sports_rental_system/uploads/field/B004/|/uploads/field/B004/|g' \
          -e 's|sports_rental_system/uploads/field/B010/|/uploads/field/B010/|g' \
          -e 's|/sports_rental_system/uploads/|/uploads/|g' \
          -e 's|sports_rental_system/uploads/|/uploads/|g' {} + || true
      fi


      # -----------------------------
      # CREATE API SYMLINKS
      # -----------------------------
      if [ -d /var/www/html/customer/backend/api ] && [ ! -e /var/www/html/customer/api ]; then
        ln -s /var/www/html/customer/backend/api /var/www/html/customer/api || true
      fi

      if [ -d /var/www/html/staff/backend/api ] && [ ! -e /var/www/html/staff/api ]; then
        ln -s /var/www/html/staff/backend/api /var/www/html/staff/api || true
      fi

      if [ -d /var/www/html/executive/backend/api ] && [ ! -e /var/www/html/executive/api ]; then
        ln -s /var/www/html/executive/backend/api /var/www/html/executive/api || true
      fi

      if [ -d /var/www/html/warehouse/backend/api ] && [ ! -e /var/www/html/warehouse/api ]; then
        ln -s /var/www/html/warehouse/backend/api /var/www/html/warehouse/api || true
      fi

      if [ -d /var/www/html/rector/backend/api ] && [ ! -e /var/www/html/rector/api ]; then
        ln -s /var/www/html/rector/backend/api /var/www/html/rector/api || true
      fi

      # -----------------------------
      # FIX IMAGE PATHS IN DB
      # -----------------------------
      mysql "${var.db_name}" -e "UPDATE equipment_master SET image_url = REPLACE(REPLACE(REPLACE(TRIM(image_url), '/sports_rental_system/uploads/', '/uploads/'), 'uploads\\', '/uploads/'), '\\\\', '/');" || true
      mysql "${var.db_name}" -e "UPDATE venues SET image_url = REPLACE(REPLACE(REPLACE(TRIM(image_url), '/sports_rental_system/uploads/', '/uploads/'), 'uploads\\', '/uploads/'), '\\\\', '/');" || true

      # backward-compatible path for old hardcoded URLs like /sports_rental_system/uploads/...
      if [ ! -e /var/www/html/sports_rental_system ]; then
        ln -s /var/www/html /var/www/html/sports_rental_system || true
      fi

      # -----------------------------
      # ROOT REDIRECT
      # -----------------------------
      cat > /var/www/html/index.php <<EOF
      <?php
        # header("Location: /customer/frontend/");
      exit;
      ?>
      EOF

      chown www-data:www-data /var/www/html/index.php
      chmod 644 /var/www/html/index.php

      systemctl restart apache2

      echo "===== DEPLOY DONE ====="

runcmd:
  - bash /usr/local/bin/websport-deploy.sh
CLOUDCONFIG

  custom_data = base64encode(local.cloud_init)
}

