provider "azurerm" {
  features {}
  subscription_id = "f939fbbd-cf94-451b-a45c-1be6bc755761"
}

resource "azurerm_linux_virtual_machine" "example" {
  name                = "example-vm"
  resource_group_name = "mikeo-resources"
  location            = "East US"
  size                = "Standard_DS1_v2"
  admin_username      = "azureuser"

  network_interface_ids = [
    data.azurerm_network_interface.example.id,
  ]

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("~/.ssh/id_mo.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}

data "azurerm_network_interface" "example" {
  name                = "example-nic"
  resource_group_name = "mikeo-resources"
}

# resource "azurerm_network_interface" "example" {
#   name                = "example-nic"
#   location            = "East US"
#   resource_group_name = "mikeo-resources"

#   ip_configuration {
#     name                          = "internal"
#     subnet_id                     = azurerm_subnet.example.id
#     private_ip_address_allocation = "Dynamic"
#   }
# }

resource "azurerm_virtual_network" "example" {
  name                = "example-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = "East US"
  resource_group_name = "mikeo-resources"
}

resource "azurerm_subnet" "example" {
  name                 = "example-subnet"
  resource_group_name  = "mikeo-resources"
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_managed_disk" "example_data" {
  name                 = "example-data-disk"
  location             = "East US"
  resource_group_name  = "mikeo-resources"
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 32
}

resource "azurerm_virtual_machine_data_disk_attachment" "example" {
  managed_disk_id    = azurerm_managed_disk.example_data.id
  virtual_machine_id = azurerm_linux_virtual_machine.example.id
  lun                = 0
  caching            = "ReadWrite"
}

resource "azurerm_network_security_group" "example" {
  name                = "example-nsg"
  location            = "East US"
  resource_group_name = "mikeo-resources"

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# resource "azurerm_network_interface_security_group_association" "example" {
#   network_interface_id      = azurerm_network_interface.example.id
#   network_security_group_id = azurerm_network_security_group.example.id
# }

resource "azurerm_virtual_machine_extension" "mount_disk" {
  name                 = "mountdatadisk"
  virtual_machine_id   = azurerm_linux_virtual_machine.example.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.1"

  protected_settings = <<PROTECTED_SETTINGS
{
  "script": "${base64encode(file("scripts/setup-datadisk.sh"))}"
}
PROTECTED_SETTINGS
}
