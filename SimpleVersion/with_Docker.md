**Option B: Pull the Latest Azurite Image (Cleaner long-term)**
```bash
docker stop azurite && docker rm azurite

docker pull mcr.microsoft.com/azure-storage/azurite:latest

docker run -d \
  -p 10000:10000 -p 10001:10001 -p 10002:10002 \
  --name azurite \
  -v ~/azurite-data:/data \
  mcr.microsoft.com/azure-storage/azurite \
  azurite --skipApiVersionCheck --location /data
```

**Check what version you now have:**
```bash
docker inspect mcr.microsoft.com/azure-storage/azurite:latest | grep -i version
```

**Verify it started correctly**
```bash
# Should show the container running
docker ps | grep azurite
```
**Check logs — should show "Azurite Blob service is starting" etc.**
```sh
docker logs azurite

# Expected log output:
Azurite Blob service is starting at http://0.0.0.0:10000
Azurite Blob service is successfully listening at http://0.0.0.0:10000
Azurite Queue service is starting at http://0.0.0.0:10001
```

**Verify After Either Fix**
```bash
az storage container list --connection-string "$AZURE_STORAGE_CONNECTION_STRING"
```
You should get [] (empty array) — that's correct and means it's working.



*******************************************************
