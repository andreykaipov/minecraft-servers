data "onepassword_vault" "vault" {
  name = "minecraft-servers"
}

data "onepassword_item" "secrets" {
  vault = data.onepassword_vault.vault.uuid
  title = "setup"
}

# generate random username and password
resource "random_string" "vm_username" {
  length  = 10
  special = false
  upper   = false
  numeric = false
}

resource "tls_private_key" "vm_public_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "onepassword_item" "generated_secrets" {
  vault    = data.onepassword_vault.vault.uuid
  title    = var.name
  category = "password"
  section {
    label = ""
    field {
      label = "public_ip_address"
      value = azurerm_public_ip.public_ip.ip_address
    }
    field {
      label = "vm_username"
      value = random_string.vm_username.result
    }
    field {
      label = "vm_private_key"
      value = tls_private_key.vm_public_key.private_key_pem
    }
    field {
      label = "vm_public_key"
      value = tls_private_key.vm_public_key.public_key_openssh
    }
  }
  tags = [
    "minecraft-servers",
  ]
}
