COMPLETE AZURITE SETUP - SIMPLE VERSION

**Step 1: Check Node.js version**
```bash
node --version
npm --version
```

If version is less than 14, upgrade:

```sh
# sudo apt remove -y nodejs npm
sudo apt update
# sudo apt install -y nodejs npm

# Install nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash

# Reload shell
source ~/.bashrc

# Install Node.js 20 LTS
nvm install 20

# Use Node.js 20
nvm use 20

# Verify
node --version
npm --version

```
**Step 2: Create and setup Azurite environment**
```bash

# Create directory
mkdir -p ~/azurite-env
cd ~/azurite-env

# Initialize npm
npm init -y

# Install Azurite
npm install azurite

# Create bin directory
mkdir -p ~/azurite-env/bin

# Create data directory
mkdir -p ~/azurite-env/data
```

**Step 3: Create activation script**
```bash

cat > ~/azurite-env/bin/activate << 'EOF'
#!/bin/bash
export PATH="$HOME/azurite-env/node_modules/.bin:$PATH"
export AZURITE_HOME="$HOME/azurite-env"
export AZURITE_DATA="$HOME/azurite-env/data"
export AZURE_STORAGE_CONNECTION_STRING="UseDevelopmentStorage=true;"
export PS1="(azurite-env) $PS1"
echo "✓ Azurite activated!"
EOF

chmod +x ~/azurite-env/bin/activate
```

**Step 4: Install Python SDK (for testing)**
```bash
source ~/azurite-env/bin/activate
sudo apt install python3-pip
pip3 install azure-storage-blob

```
**Step 5: Create test script**
```bash
cat > ~/azurite-env/test.py << 'PYSCRIPT'
from azure.storage.blob import BlobServiceClient

connection_string = "UseDevelopmentStorage=true;"

try:
    blob_service_client = BlobServiceClient.from_connection_string(connection_string)
    
    # Create container
    container_client = blob_service_client.create_container(name="test-container")
    print("✓ Container created successfully!")
    
    # List containers
    print("\n✓ Containers:")
    containers = blob_service_client.list_containers()
    for container in containers:
        print(f"  - {container.name}")
    
except Exception as e:
    print(f"❌ Error: {e}")
PYSCRIPT
```

**HOW TO USE**

**Terminal 1: Start Azurite (keep running)**
```bash
source ~/azurite-env/bin/activate
azurite --silent --location $AZURITE_DATA --skipApiVersionCheck
```
**You should see:**
```sh
Azurite Blob storage is starting at http://127.0.0.1:10000
Azurite Queue storage is starting at http://127.0.0.1:10001
Azurite Table storage is starting at http://127.0.0.1:10002
```
Keep this terminal open.

**Terminal 2: Test it (open new terminal)**
```bash
source ~/azurite-env/bin/activate
python3 ~/azurite-env/test.py
Expected output:
✓ Container created successfully!

✓ Containers:
  - test-container
```

**QUICK COMMANDS (Copy & Paste)**

*Every time you use it:*

**Start Azurite (Terminal 1):**
```bash
source ~/azurite-env/bin/activate
azurite --silent --location $AZURITE_DATA --skipApiVersionCheck
```

**Use Azurite (Terminal 2):**
```bash
source ~/azurite-env/bin/activate
python3 ~/azurite-env/test.py
```

**SETUP VERIFICATION**

Run this to verify everything is installed:
```bash
cd ~/azurite-env
echo "1. Check Node.js:"
node --version

echo -e "\n2. Check npm:"
npm --version

echo -e "\n3. Check Azurite:"
./node_modules/.bin/azurite --version

echo -e "\n4. Check Python SDK:"
python3 -c "from azure.storage.blob import BlobServiceClient; print('✓ Azure SDK installed')"
```

**DIRECTORY STRUCTURE**

After setup, you'll have:
```sh
~/azurite-env/
├── bin/
│   └── activate          (activation script)
├── data/                 (storage files)
├── node_modules/         (Azurite installed here)
├── test.py              (test script)
├── package.json
└── package-lock.json
```

**TROUBLESHOOTING**

If connection fails:
```sh
# Check if Azurite is running
sudo apt install net-tools
netstat -tuln | grep 1000
```
**You should see three ports (10000, 10001, 10002)**
If ports are not showing:
```bash
# Kill any old processes
pkill -f azurite

# Remove old data and restart

rm -rf ~/azurite-env/data/*
source ~/azurite-env/bin/activate
azurite --silent --location $AZURITE_DATA --skipApiVersionCheck
```

**If Python SDK fails:**
```bash
# Reinstall SDK
pip3 install --upgrade azure-storage-blob
```

**ONE-LINER SETUP (Paste all at once)**
```bash
mkdir -p ~/azurite-env/bin ~/azurite-env/data && cd ~/azurite-env && npm init -y && npm install azurite && cat > ~/azurite-env/bin/activate << 'EOF'
#!/bin/bash
export PATH="$HOME/azurite-env/node_modules/.bin:$PATH"
export AZURITE_HOME="$HOME/azurite-env"
export AZURITE_DATA="$HOME/azurite-env/data"
export AZURE_STORAGE_CONNECTION_STRING="UseDevelopmentStorage=true;"
export PS1="(azurite-env) $PS1"
echo "✓ Azurite activated!"
EOF
chmod +x ~/azurite-env/bin/activate && cat > ~/azurite-env/test.py << 'PYSCRIPT'
from azure.storage.blob import BlobServiceClient
connection_string = "UseDevelopmentStorage=true;"
try:
    blob_service_client = BlobServiceClient.from_connection_string(connection_string)
    container_client = blob_service_client.create_container(name="test-container")
    print("✓ Container created successfully!")
    print("\n✓ Containers:")
    for container in blob_service_client.list_containers():
        print(f"  - {container.name}")
except Exception as e:
    print(f"❌ Error: {e}")
PYSCRIPT
source ~/azurite-env/bin/activate && pip3 install azure-storage-blob && echo "✓ Setup complete!"
```
<!-- DONE! Now you can:
✅ Start Azurite with one command
✅ Test it with Python
✅ Use it for local Azure Storage development
✅ Test Terraform state backend locally
✅ Integrate with GitHub Actions -->

---
### To install the official Azure CLI on Ubuntu 22.04 VM, follow these steps.

**1. Update the system**
```sh
sudo apt update && sudo apt upgrade -y
```
**2. Install required packages**
```sh
sudo apt install -y ca-certificates curl apt-transport-https lsb-release gnupg
```
**3. Download and add Microsoft signing key**
```sh
curl -sLS https://packages.microsoft.com/keys/microsoft.asc | \
sudo gpg --dearmor -o /etc/apt/keyrings/microsoft.gpg
```

**4. Add Azure CLI repository**
```sh
AZ_REPO=$(lsb_release -cs)

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" | \
sudo tee /etc/apt/sources.list.d/azure-cli.list
```
**5. Install Azure CLI**
```sh
sudo apt update
sudo apt install -y azure-cli
```
**6. Verify installation**
```sh
az version

You should see output similar to:

{
  "azure-cli": "2.x.x",
  "azure-cli-core": "2.x.x"
}
```
---