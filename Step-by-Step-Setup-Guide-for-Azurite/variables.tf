variable "vm_name" {
  description = "Name of the Virtual Machine"
  type        = string
  default     = "test-vm-local"

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]{1,15}$", var.vm_name))
    error_message = "VM name must be 1-15 characters, alphanumeric and hyphens only."
  }
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "local-rg"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "eastus"

  validation {
    condition     = contains(["eastus", "westus", "westus2", "eastus2", "southcentralus", "centralus"], var.location)
    error_message = "Location must be a valid Azure region."
  }
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "vm_size" {
  description = "Size of the VM"
  type        = string
  default     = "Standard_B2s"
}

variable "image_publisher" {
  description = "Image publisher"
  type        = string
  default     = "Canonical"
}

variable "image_offer" {
  description = "Image offer"
  type        = string
  default     = "0001-com-ubuntu-server-jammy"
}

variable "image_sku" {
  description = "Image SKU"
  type        = string
  default     = "22_04-lts-gen2"
}

variable "image_version" {
  description = "Image version"
  type        = string
  default     = "latest"
}

variable "tags" {
  description = "Tags for resources"
  type        = map(string)
  default = {
    Environment = "development"
    CreatedBy   = "Terraform"
    Purpose     = "Testing"
  }
}
