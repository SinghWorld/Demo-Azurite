# Local VM Provisioning Testing with GitHub Actions & Azurite

## Overview
This guide walks you through setting up a complete GitHub Actions workflow that provisions an Azure VM using Terraform with **Azurite** for local state management—no Azure subscription required for testing the workflow.

---

## Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                    GitHub Actions Workflow                    │
├──────────────────────────────────────────────────────────────┤
│                                                                │
│  1. Start Azurite ──> 2. Terraform Init (Azurite Backend)    │
│                                                                │
│  3. Validate & Plan ──> 4. Security Scan (Checkov)           │
│                                                                │
│  5. Apply ──> 6. Test ──> 7. Destroy ──> 8. Cleanup         │
│                                                                │
│       (Terraform State: http://127.0.0.1:10000)              │
│          (Azurite - Local Storage Emulator)                   │
└──────────────────────────────────────────────────────────────┘
```

---

## Prerequisites

- Ubuntu 22.04 (as per your setup)
- `dc-ops` user with sudo access
- Git configured locally
- Basic understanding of Terraform and GitHub Actions

---

## Step 1: Local Setup (Before pushing to GitHub)

### 1.1 Create Repository Structure

```bash
cd ~/projects
mkdir -p terraform-vm-testing
cd terraform-vm-testing

# Create directory structure
mkdir -p terraform
mkdir -p .github/workflows
mkdir -p .ssh
mkdir -p .docs
```

### 1.2 Generate SSH Key Pair (for VM access)

```bash
ssh-keygen -t rsa -b 4096 -f .ssh/id_rsa -N ""

# Verify
ls -la .ssh/
cat .ssh/id_rsa.pub
```

### 1.3 Copy Terraform Files

Place these files in the `terraform/` directory:
- `main.tf` - Backend configuration
- `variables.tf` - Input variables
- `resources.tf` - VM and infrastructure resources
- `outputs.tf` - Output values

### 1.4 Initialize Terraform Locally with Azurite

**Step A: Start Azurite**
```bash
# Terminal 1: Start Azurite
mkdir -p ~/azurite-data
azurite --silent --location ~/azurite-data

# Terminal 2: Verify it's running
curl http://127.0.0.1:10000/devstoreaccount1
# Should return: <ServiceProperties/>
```

**Step B: Initialize Terraform**
```bash
cd terraform/

# Set environment variables
export ARM_USE_AZUREAD=false
export ARM_ENDPOINT=http://127.0.0.1:10000

# Initialize with Azurite backend
terraform init \
  -backend-config="storage_account_name=devstoreaccount1" \
  -backend-config="container_name=tfstate" \
  -backend-config="key=vm.tfstate" \
  -backend-config="resource_group_name=local-dev" \
  -backend-config="use_azuread_auth=false"
```

### 1.5 Validate and Plan Locally

```bash
# Format check
terraform fmt -recursive .

# Validate
terraform validate

# Plan (without actually creating)
terraform plan \
  -var="vm_name=test-vm-local" \
  -var="resource_group_name=local-rg" \
  -var="location=eastus" \
  -out=tfplan
```

**Expected Output:**
```
Plan: 8 to add, 0 to change, 0 to destroy.
```

This shows what WOULD be created. Notice: no real Azure resources are provisioned yet.

---

## Step 2: Setup GitHub Repository

### 2.1 Create GitHub Repository

```bash
# Initialize git
git init
git config user.name "Your Name"
git config user.email "your.email@example.com"

# Create remote (replace with your GitHub repo URL)
git remote add origin https://github.com/YOUR-USERNAME/terraform-vm-testing.git
```

### 2.2 Create Directory Structure

```bash
# Make sure these directories exist:
mkdir -p .github/workflows
mkdir -p terraform
mkdir -p .docs
mkdir -p .ssh
```

### 2.3 Add Workflow File

Copy the workflow YAML to:
```
.github/workflows/vm-provision-workflow.yml
```

### 2.4 Create .gitignore

```bash
cat > .gitignore << 'EOF'
# Terraform files
*.tfstate
*.tfstate.*
*.tfvars
!*.tfvars.example
.terraform/
.terraform.lock.hcl
tfplan

# Environment files
.env
.env.local

# IDE
.vscode/
.idea/
*.swp
*.swo

# SSH keys
.ssh/id_rsa
.ssh/id_rsa.pub

# Artifacts
terraform/outputs.json
*.sarif

# OS
.DS_Store
Thumbs.db
EOF

git add .gitignore
```

### 2.5 Create README

```bash
cat > README.md << 'EOF'
# Terraform VM Provisioning - Local Testing

This repository demonstrates provisioning an Azure VM using Terraform with GitHub Actions,
tested locally using **Azurite** for state management.

## Quick Start (Local Testing)

### Prerequisites
- Azurite: `npm install -g azurite`
- Terraform: `terraform -v` (v1.8.0+)

### Run Locally

1. Start Azurite:
   ```bash
   mkdir -p ~/azurite-data
   azurite --silent --location ~/azurite-data
   ```

2. Initialize Terraform:
   ```bash
   cd terraform/
   export ARM_USE_AZUREAD=false
   export ARM_ENDPOINT=http://127.0.0.1:10000
   
   terraform init \
     -backend-config="storage_account_name=devstoreaccount1" \
     -backend-config="container_name=tfstate" \
     -backend-config="key=vm.tfstate" \
     -backend-config="resource_group_name=local-dev" \
     -backend-config="use_azuread_auth=false"
   ```

3. Plan:
   ```bash
   terraform plan \
     -var="vm_name=test-vm-local" \
     -var="resource_group_name=local-rg" \
     -var="location=eastus" \
     -out=tfplan
   ```

4. Apply (will FAIL due to no real Azure subscription - this is expected):
   ```bash
   terraform apply tfplan
   ```

## Next Steps: Moving to Real Azure

To transition to real Azure:

1. Create Azure Storage Account for state
2. Update workflow to use Azure OIDC authentication
3. Replace Azurite backend with Azure Storage in `terraform/main.tf`
4. Update environment variables in GitHub Actions

EOF

git add README.md
```

### 2.6 Commit and Push

```bash
git add .
git commit -m "Initial commit: Local VM provisioning with Azurite testing"
git branch -M main
git push -u origin main
```

---

## Step 3: Test Workflow in GitHub Actions

### 3.1 Monitor Workflow Execution

Go to your GitHub repo → **Actions** tab → Click on the latest workflow run

### 3.2 Expected Behavior

**For LOCAL TESTING (expected to fail gracefully):**

| Job | Status | Notes |
|-----|--------|-------|
| `azurite-start` | ✅ PASS | Azurite starts successfully |
| `terraform-validate` | ✅ PASS | Terraform validates config |
| `security-scan` | ✅ PASS | Checkov runs (skips cloud checks) |
| `terraform-apply` | ⚠️ FAIL | Expected - no real Azure subscription |
| `test-vm` | ⏭️ SKIPPED | Depends on apply |
| `cleanup` | ✅ PASS | Destroys/cleans up state |

---

## Step 4: Understand the State Management

### Where is State Stored?

**Locally (via Azurite):**
```
http://127.0.0.1:10000/devstoreaccount1/tfstate/vm.tfstate
```

This is stored in: `~/azurite-data/devstoreaccount1/tfstate/`

### Inspect State File

```bash
# While Azurite is running:
az storage blob list \
  --container-name tfstate \
  --connection-string "DefaultEndpointsProtocol=http;AccountName=devstoreaccount1;AccountKey=Eby8vdM02xNOcqFlqUwJPLlmEtlCDXeOFYAixTcSxaU=;BlobEndpoint=http://127.0.0.1:10000/devstoreaccount1;"

# Download state file
az storage blob download \
  --container-name tfstate \
  --name vm.tfstate \
  --file ~/vm.tfstate \
  --connection-string "DefaultEndpointsProtocol=http;AccountName=devstoreaccount1;AccountKey=Eby8vdM02xNOcqFlqUwJPLlmEtlCDXeOFYAixTcSxaU=;BlobEndpoint=http://127.0.0.1:10000/devstoreaccount1;"

# View state
cat ~/vm.tfstate | jq .
```

---

## Step 5: Transition to Real Azure (When Ready)

### 5.1 Create Azure Storage Account

```bash
# Login to Azure
az login

# Create resource group
az group create \
  --name terraform-state-rg \
  --location eastus

# Create storage account
az storage account create \
  --name tfstateprod \
  --resource-group terraform-state-rg \
  --location eastus \
  --sku Standard_LRS \
  --kind StorageV2

# Create container
az storage container create \
  --name tfstate \
  --account-name tfstateprod
```

### 5.2 Update Terraform Backend

Edit `terraform/main.tf`:
```hcl
# Comment out Azurite backend:
# backend "azurerm" {
#   resource_group_name  = "local-dev"
#   storage_account_name = "devstoreaccount1"
#   container_name       = "tfstate"
#   key                  = "vm.tfstate"
#   use_azuread_auth     = false
# }

# Uncomment real Azure backend:
backend "azurerm" {
  resource_group_name  = "terraform-state-rg"
  storage_account_name = "tfstateprod"
  container_name       = "tfstate"
  key                  = "vm.tfstate"
  use_azuread_auth     = true
}
```

### 5.3 Setup Azure OIDC in GitHub

```bash
# Create App Registration (if not exists)
az ad app create --display-name "github-terraform-vm"

# Get app ID
APP_ID=$(az ad app list --display-name "github-terraform-vm" --query "[0].id" -o tsv)

# Create service principal
PRINCIPAL_ID=$(az ad sp create --id $APP_ID --query id -o tsv)

# Assign role (Contributor on subscription)
az role assignment create \
  --role "Contributor" \
  --assignee $PRINCIPAL_ID \
  --scope "/subscriptions/YOUR_SUBSCRIPTION_ID"

# Add federated credentials
az ad app federated-credential create \
  --id $APP_ID \
  --parameters "{
    \"name\": \"github-terraform-vm\",
    \"issuer\": \"https://token.actions.githubusercontent.com\",
    \"subject\": \"repo:YOUR_USERNAME/terraform-vm-testing:ref:refs/heads/main\",
    \"audiences\": [\"api://AzureADTokenExchange\"]
  }"
```

### 5.4 Update GitHub Actions Workflow

Modify `vm-provision-workflow.yml` to use Azure OIDC instead of hardcoded credentials:

```yaml
env:
  AZURE_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}
  AZURE_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID }}
  AZURE_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
  ARM_USE_AZUREAD: true
  ARM_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}
  ARM_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID }}
  ARM_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
  ARM_USE_OIDC: true
```

---

## Troubleshooting

### Issue: "Connection refused" from Azurite

**Solution:** Verify Azurite is running:
```bash
curl http://127.0.0.1:10000/devstoreaccount1
```

### Issue: Terraform init fails

**Solution:** Check environment variables are set:
```bash
echo $ARM_USE_AZUREAD
echo $ARM_ENDPOINT
```

### Issue: State file not persisting

**Solution:** Ensure Azurite data directory has write permissions:
```bash
ls -la ~/azurite-data/
chmod -R 755 ~/azurite-data/
```

### Issue: SSH key issues in VM provisioning

**Solution:** Regenerate and update:
```bash
ssh-keygen -t rsa -b 4096 -f .ssh/id_rsa -N ""
```

---

## Key Concepts

| Concept | Explanation |
|---------|-------------|
| **Azurite** | Local Azure Storage emulator - runs on your machine, no subscription needed |
| **Terraform State** | Tracks your infrastructure; stored in Azurite during testing |
| **GitHub Actions** | CI/CD platform that runs your workflows |
| **Workflow Jobs** | Azurite, Validate, Scan, Apply, Test, Cleanup run in sequence |
| **Checkov** | Security scanning tool that validates Terraform code |

---

## Security Notes

- **SSH Key:** Keep `.ssh/id_rsa` private - never commit to GitHub
- **Azurite:** Only for local/testing - never use in production
- **Credentials:** Use Azure OIDC (not account keys) for real Azure
- **NSG Rules:** Current setup allows SSH from anywhere - restrict in production

---

## Next Steps

1. ✅ Test workflow locally with Azurite
2. ✅ Push to GitHub and verify workflow runs
3. ✅ Create real Azure resources (subscription, OIDC)
4. ✅ Transition workflow to real Azure
5. ✅ Add drift detection for ongoing monitoring
6. ✅ Integrate with your existing Terraform pipelines

---

## Contact

For issues or questions, refer to:
- [Azurite Documentation](https://learn.microsoft.com/en-us/azure/storage/common/storage-use-azurite)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
EOF

git add README.md
git commit -m "Add comprehensive setup guide"
git push
```

---

## Step 6: Verify Everything Works

### 6.1 Run Workflow Locally (Simulation)

```bash
cd ~/projects/terraform-vm-testing

# Start Azurite
mkdir -p ~/azurite-data
azurite --silent --location ~/azurite-data &

# Run Terraform steps manually
cd terraform/

export ARM_USE_AZUREAD=false
export ARM_ENDPOINT=http://127.0.0.1:10000

# Init
terraform init \
  -backend-config="storage_account_name=devstoreaccount1" \
  -backend-config="container_name=tfstate" \
  -backend-config="key=vm.tfstate" \
  -backend-config="resource_group_name=local-dev" \
  -backend-config="use_azuread_auth=false"

# Validate
terraform validate

# Plan
terraform plan \
  -var="vm_name=test-vm-local" \
  -var="resource_group_name=local-rg" \
  -var="location=eastus"

# Check state in Azurite
curl http://127.0.0.1:10000/devstoreaccount1/tfstate/vm.tfstate | jq .
```

### 6.2 Monitor GitHub Actions

Push to GitHub and watch the workflow execute in the **Actions** tab.

---

## Summary

You now have:

✅ **Local Azurite setup** - Test Terraform state management without Azure subscription
✅ **Terraform IaC** - Complete VM infrastructure as code
✅ **GitHub Actions workflow** - Automated pipeline with validation, security scanning, and cleanup
✅ **Security scanning** - Checkov integration for policy compliance
✅ **State management** - Terraform state stored in Azurite (local testing)
✅ **Transition path** - Clear steps to move to real Azure

---

**Next Phase:** Once you verify this works locally, you can extend it with:
- Drift detection (your expertise!)
- Slack notifications
- Issue auto-creation on drift
- Multiple environments (dev/stage/prod)
- Azure OIDC authentication
- Real resource provisioning to Azure

Would you like me to guide you through any of these next steps?
