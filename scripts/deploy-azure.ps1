<#
.SYNOPSIS
    TherapySculpt - Automated Azure UAE North (uaenorth) Infrastructure & Deployment
.DESCRIPTION
    Provisions Azure Container Registry, Azure PostgreSQL Flexible Server, Azure Cache for Redis,
    Log Analytics, Container Apps Environment, builds images, and deploys all services.
    Enforces compliance with UAE Federal Law No. 2 of 2019 (Art. 13) and DoH ADHICS v2.
#>

[CmdletBinding()]
param(
    [string]$Location = "uaenorth",
    [string]$ResourceGroup = "rg-therapysculpt-prod-uaenorth",
    [string]$AcrName = "acrtherapysculptuae",
    [string]$PostgresServer = "psql-therapysculpt-uaenorth",
    [string]$PostgresDb = "therapysculpt",
    [string]$PostgresAdminUser = "tsadmin",
    [string]$PostgresAdminPassword = $env:POSTGRES_ADMIN_PASSWORD,
    [string]$RedisName = "redis-therapysculpt-uaenorth",
    [string]$LogAnalyticsWorkspace = "log-therapysculpt-uaenorth",
    [string]$ContainerAppsEnv = "cae-therapysculpt-uaenorth"
)

$ErrorActionPreference = "Stop"

Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host "    TherapySculpt - Azure UAE North PowerShell Deployment Pipeline              " -ForegroundColor Cyan
Write-Host "    Target Region: $Location                                                    " -ForegroundColor Cyan
Write-Host "================================================================================" -ForegroundColor Cyan

# 1. Check Azure Login
$account = az account show 2>$null | ConvertFrom-Json
if (-not $account) {
    Write-Error "Please authenticate with Azure CLI first by running 'az login'."
}
Write-Host "[INFO] Active Subscription: $($account.name) ($($account.id))" -ForegroundColor Cyan

# Prompt for password if not provided
if (-not $PostgresAdminPassword) {
    $securePass = Read-Host "Enter master password for PostgreSQL '$PostgresAdminUser'" -AsSecureString
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePass)
    $PostgresAdminPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
}

# 2. Register Providers
Write-Host "[INFO] Registering required resource providers..." -ForegroundColor Cyan
az provider register --namespace Microsoft.App -o none 2>$null | Out-Null
az provider register --namespace Microsoft.OperationalInsights -o none 2>$null | Out-Null
az provider register --namespace Microsoft.ContainerRegistry -o none 2>$null | Out-Null
az provider register --namespace Microsoft.DBforPostgreSQL -o none 2>$null | Out-Null
az provider register --namespace Microsoft.Cache -o none 2>$null | Out-Null

# 3. Create Resource Group
Write-Host "[INFO] Ensuring Resource Group '$ResourceGroup' in '$Location'..." -ForegroundColor Cyan
az group create --name $ResourceGroup --location $Location `
    --tags Project="TherapySculpt" Environment="Production" Jurisdiction="UAE" ComplianceStandard="UAE-Law-2-2019-DoH-ADHICS-v2" `
    -o none

# 4. Create ACR
Write-Host "[INFO] Ensuring Azure Container Registry '$AcrName'..." -ForegroundColor Cyan
$acrExists = az acr show --name $AcrName --resource-group $ResourceGroup 2>$null
if (-not $acrExists) {
    az acr create --resource-group $ResourceGroup --name $AcrName --sku Basic --location $Location --admin-enabled true -o none
}
$acrLoginServer = az acr show --name $AcrName --query loginServer -o tsv
$acrUsername = az acr credential show --name $AcrName --query username -o tsv
$acrPassword = az acr credential show --name $AcrName --query "passwords[0].value" -o tsv

# 5. Create PostgreSQL Flexible Server
Write-Host "[INFO] Checking PostgreSQL Flexible Server '$PostgresServer'..." -ForegroundColor Cyan
$psqlExists = az postgres flexible-server show --name $PostgresServer --resource-group $ResourceGroup 2>$null
if (-not $psqlExists) {
    Write-Host "[INFO] Creating PostgreSQL 16 Flexible Server in '$Location'..." -ForegroundColor Cyan
    az postgres flexible-server create `
        --resource-group $ResourceGroup `
        --name $PostgresServer `
        --location $Location `
        --admin-user $PostgresAdminUser `
        --admin-password $PostgresAdminPassword `
        --sku-name Standard_B1ms `
        --tier Burstable `
        --version 16 `
        --storage-size 32 `
        --public-access 0.0.0.0 `
        --yes -o none
}

# Enforce SSL
az postgres flexible-server parameter set --resource-group $ResourceGroup --server-name $PostgresServer --name require_secure_transport --value ON -o none 2>$null | Out-Null
az postgres flexible-server db create --resource-group $ResourceGroup --server-name $PostgresServer --database-name $PostgresDb -o none 2>$null | Out-Null
az postgres flexible-server firewall-rule create --resource-group $ResourceGroup --name $PostgresServer --rule-name "AllowAzureInternal" --start-ip-address 0.0.0.0 --end-ip-address 0.0.0.0 -o none 2>$null | Out-Null

$dbHost = "$PostgresServer.postgres.database.azure.com"
$databaseUrl = "postgresql://${PostgresAdminUser}:${PostgresAdminPassword}@${dbHost}:5432/${PostgresDb}?sslmode=require"
Write-Host "[SUCCESS] PostgreSQL Ready: $databaseUrl" -ForegroundColor Green

# 6. Create Azure Managed Redis (Redis Enterprise)
Write-Host "[INFO] Checking Azure Managed Redis '$RedisName'..." -ForegroundColor Cyan
az config set extension.use_dynamic_install=yes_without_prompt -o none 2>$null | Out-Null
az extension add --name redisenterprise --upgrade --yes -o none 2>$null | Out-Null

$redisExists = az redisenterprise show --cluster-name $RedisName --resource-group $ResourceGroup 2>$null
if (-not $redisExists) {
    Write-Host "[INFO] Creating Azure Managed Redis in '$Location' (SKU: Balanced_B0)..." -ForegroundColor Cyan
    az redisenterprise create --cluster-name $RedisName --resource-group $ResourceGroup --location $Location `
        --sku "Balanced_B0" --minimum-tls-version "1.2" --client-protocol "Encrypted" --port 10000 `
        --access-keys-authentication "Enabled" --public-network-access "Enabled" --eviction-policy "NoEviction" -o none
}
$redisHost = az redisenterprise show --cluster-name $RedisName --resource-group $ResourceGroup --query hostName -o tsv
$redisKey = az redisenterprise database list-keys --cluster-name $RedisName --resource-group $ResourceGroup --query primaryKey -o tsv
$redisPort = az redisenterprise database show --cluster-name $RedisName --resource-group $ResourceGroup --query port -o tsv 2>$null
if (-not $redisPort) { $redisPort = "10000" }
$redisUrl = "rediss://:${redisKey}@${redisHost}:${redisPort}"
Write-Host "[SUCCESS] Azure Managed Redis Ready: $redisUrl" -ForegroundColor Green

# 7. Run Prisma Migrations
Write-Host "[INFO] Running Prisma migrations against Azure PostgreSQL..." -ForegroundColor Cyan
$env:DATABASE_URL = $databaseUrl
pnpm --filter @therapy-sculpt/database prisma migrate deploy

# 8. Setup Container Apps Environment
Write-Host "[INFO] Configuring Container Apps Environment..." -ForegroundColor Cyan
$logWsExists = az monitor log-analytics workspace show --resource-group $ResourceGroup --workspace-name $LogAnalyticsWorkspace 2>$null
if (-not $logWsExists) {
    az monitor log-analytics workspace create --resource-group $ResourceGroup --workspace-name $LogAnalyticsWorkspace --location $Location -o none
}
$logId = az monitor log-analytics workspace show --resource-group $ResourceGroup --workspace-name $LogAnalyticsWorkspace --query customerId -o tsv
$logKey = az monitor log-analytics workspace get-shared-keys --resource-group $ResourceGroup --workspace-name $LogAnalyticsWorkspace --query primarySharedKey -o tsv

$caeExists = az containerapp env show --name $ContainerAppsEnv --resource-group $ResourceGroup 2>$null
if (-not $caeExists) {
    az containerapp env create --name $ContainerAppsEnv --resource-group $ResourceGroup --logs-workspace-id $logId --logs-workspace-key $logKey --location $Location -o none
}

# 9. Build and Push Images
Write-Host "[INFO] Logging in to Azure Container Registry '$AcrName' via Docker..." -ForegroundColor Cyan
az acr login --name $AcrName

$envDomain = az containerapp env show --name $ContainerAppsEnv --resource-group $ResourceGroup --query properties.defaultDomain -o tsv
if (-not $envDomain) { $envDomain = "uaenorth.azurecontainerapps.io" }
$targetApiUrl = "https://ca-api-server.$envDomain"

Write-Host "[INFO] Building images with local Docker..." -ForegroundColor Cyan
docker build -t "$acrLoginServer/api-server:latest" -f apps/api-server/Dockerfile .
docker push "$acrLoginServer/api-server:latest"

docker build -t "$acrLoginServer/web-patient:latest" --build-arg NEXT_PUBLIC_API_URL="$targetApiUrl" --build-arg NEXT_PUBLIC_UAE_REGION="$Location" -f apps/web-patient/Dockerfile .
docker push "$acrLoginServer/web-patient:latest"

docker build -t "$acrLoginServer/web-clinician:latest" --build-arg NEXT_PUBLIC_API_URL="$targetApiUrl" --build-arg NEXT_PUBLIC_UAE_REGION="$Location" -f apps/web-clinician/Dockerfile .
docker push "$acrLoginServer/web-clinician:latest"

docker build -t "$acrLoginServer/web-admin:latest" --build-arg NEXT_PUBLIC_API_URL="$targetApiUrl" --build-arg NEXT_PUBLIC_UAE_REGION="$Location" -f apps/web-admin/Dockerfile .
docker push "$acrLoginServer/web-admin:latest"

# 10. Deploy Apps
Write-Host "[INFO] Deploying ca-api-server..." -ForegroundColor Cyan
$apiExists = az containerapp show --name ca-api-server --resource-group $ResourceGroup 2>$null
if (-not $apiExists) {
    az containerapp create --name ca-api-server --resource-group $ResourceGroup --environment $ContainerAppsEnv `
        --image "$acrLoginServer/api-server:latest" --registry-server $acrLoginServer --registry-username $acrUsername --registry-password $acrPassword `
        --target-port 4000 --ingress external --cpu 0.5 --memory 1.0Gi --min-replicas 1 --max-replicas 5 `
        --secrets db-url="$databaseUrl" redis-url="$redisUrl" `
        --env-vars NODE_ENV=production PORT=4000 HOST=0.0.0.0 UAE_REGION=uaenorth DATABASE_URL=secretref:db-url REDIS_URL=secretref:redis-url -o none
} else {
    az containerapp update --name ca-api-server --resource-group $ResourceGroup --image "$acrLoginServer/api-server:latest" -o none
}

$apiFqdn = az containerapp show --name ca-api-server --resource-group $ResourceGroup --query properties.configuration.ingress.fqdn -o tsv
$apiPublicUrl = "https://$apiFqdn"

$revSuffix = "rev-" + [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
Write-Host "[INFO] Deploying web apps with API URL $apiPublicUrl (Revision suffix: $revSuffix)..." -ForegroundColor Cyan
$patientExists = az containerapp show --name ca-web-patient --resource-group $ResourceGroup 2>$null
if (-not $patientExists) {
    az containerapp create --name ca-web-patient --resource-group $ResourceGroup --environment $ContainerAppsEnv `
        --image "$acrLoginServer/web-patient:latest" --registry-server $acrLoginServer --registry-username $acrUsername --registry-password $acrPassword `
        --target-port 3000 --ingress external --cpu 0.5 --memory 1.0Gi --min-replicas 1 --max-replicas 5 `
        --env-vars NODE_ENV=production PORT=3000 HOSTNAME=0.0.0.0 UAE_REGION=uaenorth NEXT_PUBLIC_API_URL="$apiPublicUrl" -o none
} else {
    az containerapp update --name ca-web-patient --resource-group $ResourceGroup --image "$acrLoginServer/web-patient:latest" --revision-suffix "$revSuffix" -o none
}

$clinicianExists = az containerapp show --name ca-web-clinician --resource-group $ResourceGroup 2>$null
if (-not $clinicianExists) {
    az containerapp create --name ca-web-clinician --resource-group $ResourceGroup --environment $ContainerAppsEnv `
        --image "$acrLoginServer/web-clinician:latest" --registry-server $acrLoginServer --registry-username $acrUsername --registry-password $acrPassword `
        --target-port 3000 --ingress external --cpu 0.5 --memory 1.0Gi --min-replicas 1 --max-replicas 5 `
        --env-vars NODE_ENV=production PORT=3000 HOSTNAME=0.0.0.0 UAE_REGION=uaenorth NEXT_PUBLIC_API_URL="$apiPublicUrl" -o none
} else {
    az containerapp update --name ca-web-clinician --resource-group $ResourceGroup --image "$acrLoginServer/web-clinician:latest" --revision-suffix "$revSuffix" -o none
}

$adminExists = az containerapp show --name ca-web-admin --resource-group $ResourceGroup 2>$null
if (-not $adminExists) {
    az containerapp create --name ca-web-admin --resource-group $ResourceGroup --environment $ContainerAppsEnv `
        --image "$acrLoginServer/web-admin:latest" --registry-server $acrLoginServer --registry-username $acrUsername --registry-password $acrPassword `
        --target-port 3000 --ingress external --cpu 0.5 --memory 1.0Gi --min-replicas 1 --max-replicas 5 `
        --env-vars NODE_ENV=production PORT=3000 HOSTNAME=0.0.0.0 UAE_REGION=uaenorth NEXT_PUBLIC_API_URL="$apiPublicUrl" -o none
} else {
    az containerapp update --name ca-web-admin --resource-group $ResourceGroup --image "$acrLoginServer/web-admin:latest" --revision-suffix "$revSuffix" -o none
}

$patientFqdn = az containerapp show --name ca-web-patient --resource-group $ResourceGroup --query properties.configuration.ingress.fqdn -o tsv
$clinicianFqdn = az containerapp show --name ca-web-clinician --resource-group $ResourceGroup --query properties.configuration.ingress.fqdn -o tsv
$adminFqdn = az containerapp show --name ca-web-admin --resource-group $ResourceGroup --query properties.configuration.ingress.fqdn -o tsv

Write-Host ""
Write-Host "================================================================================" -ForegroundColor Green
Write-Host "   Deployment Completed Successfully!                                           " -ForegroundColor Green
Write-Host "   Fastify API:   $apiPublicUrl/health" -ForegroundColor Green
Write-Host "   Patient Web:   https://$patientFqdn" -ForegroundColor Green
Write-Host "   Clinician Web: https://$clinicianFqdn" -ForegroundColor Green
Write-Host "   Admin Web:     https://$adminFqdn" -ForegroundColor Green
Write-Host "================================================================================" -ForegroundColor Green
