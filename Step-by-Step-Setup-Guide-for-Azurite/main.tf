terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
    }
  }

  # For local testing with Azurite, uncomment the backend block below
  # This will be initialized via GitHub Actions with backend-config flags
  backend "azurerm" {
    resource_group_name  = "local-dev"
    storage_account_name = "devstoreaccount1"
    container_name       = "tfstate"
    key                  = "vm.tfstate"
    use_azuread_auth     = false
  }

  # When ready for REAL Azure (comment out Azurite backend above):
  # backend "azurerm" {
  #   resource_group_name  = "terraform-state-rg"
  #   storage_account_name = "tfstateprod"
  #   container_name       = "tfstate"
  #   key                  = "vm.tfstate"
  #   use_azuread_auth     = true
  # }
}

provider "azurerm" {
  features {}

  # For Azurite testing (local):
  # Uncomment these for local development:
  # skip_provider_registration = true
  # use_cli                    = false
  # 
  # For real Azure (comment out for Azurite):
  # use_cli = true
}
