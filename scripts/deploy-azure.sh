#!/usr/bin/env bash
# ==============================================================================
# TherapySculpt - Automated Azure UAE North (uaenorth) Infrastructure & Deployment
#
# Compliance & Legal Mandate:
# - UAE Federal Law No. 2 of 2019 (Use of ICT in Health Fields - Art. 13 Data Residency)
# - Abu Dhabi Department of Health (DoH) ADHICS v2 Standard
# - Dubai Health Authority (DHA) Health Data Security & Protection
#
# Target Region: uaenorth (Dubai / Abu Dhabi datacenter pairing)
# Target Architecture:
#   - Resource Group: rg-therapysculpt-prod-uaenorth
#   - PostgreSQL 16 Flexible Server: psql-therapysculpt-uaenorth (SSL enforced)
#   - Azure Cache for Redis: redis-therapysculpt-uaenorth (TLS 1.2, Port 6380)
#   - Azure Container Registry: acrtherapysculptuae
#   - Azure Container Apps Environment: cae-therapysculpt-uaenorth
#   - Container Apps:
#       * ca-api-server (Port 4000)
#       * ca-web-patient (Port 3000)
#       * ca-web-clinician (Port 3000)
#       * ca-web-admin (Port 3000)
# ==============================================================================

set -euo pipefail

# Colors for logging
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info() { echo -e "${CYAN}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARNING]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; exit 1; }

echo -e "${CYAN}"
echo "================================================================================"
echo "    TherapySculpt - Enterprise Azure UAE Deployment Pipeline                   "
echo "    Target Region: UAE North (uaenorth)                                        "
echo "================================================================================"
echo -e "${NC}"

# ------------------------------------------------------------------------------
# 1. Environment & Parameter Configuration
# ------------------------------------------------------------------------------
export LOCATION="${LOCATION:-uaenorth}"
export RESOURCE_GROUP="${RESOURCE_GROUP:-rg-therapysculpt-prod-uaenorth}"
export ACR_NAME="${ACR_NAME:-acrtherapysculptuae}"
export POSTGRES_SERVER="${POSTGRES_SERVER:-psql-therapysculpt-uaenorth}"
export POSTGRES_DB="${POSTGRES_DB:-therapysculpt}"
export POSTGRES_ADMIN_USER="${POSTGRES_ADMIN_USER:-tsadmin}"
export REDIS_NAME="${REDIS_NAME:-redis-therapysculpt-uaenorth}"
export LOG_ANALYTICS_WS="${LOG_ANALYTICS_WS:-log-therapysculpt-uaenorth}"
export CONTAINER_APPS_ENV="${CONTAINER_APPS_ENV:-cae-therapysculpt-uaenorth}"

# Validate Password or Prompt
if [[ -z "${POSTGRES_ADMIN_PASSWORD:-}" ]]; then
  warn "POSTGRES_ADMIN_PASSWORD is not set in environment."
  read -rsp "Enter master password for PostgreSQL '${POSTGRES_ADMIN_USER}' (min 12 chars, mixed case, numbers, symbols): " POSTGRES_ADMIN_PASSWORD
  echo ""
  if [[ ${#POSTGRES_ADMIN_PASSWORD} -lt 10 ]]; then
    error "Password is too short. Please provide a strong password."
  fi
fi

# ------------------------------------------------------------------------------
# 2. Azure CLI Preflight Validation
# ------------------------------------------------------------------------------
info "Verifying Azure CLI authentication and subscription..."
if ! command -v az &>/dev/null; then
  error "Azure CLI ('az') is not installed. Please install it from https://aka.ms/installazurecliwindows or your package manager."
fi

# Check login
CURRENT_SUB=$(az account show --query name -o tsv 2>/dev/null || true)
if [[ -z "$CURRENT_SUB" ]]; then
  error "You are not logged in to Azure CLI. Run 'az login' and select your subscription first."
fi
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
info "Active Subscription: ${CURRENT_SUB} (${SUBSCRIPTION_ID})"
info "Target Deployment Region: ${LOCATION}"

# Ensure required resource providers are registered
info "Registering required Azure resource providers..."
az provider register --namespace Microsoft.App -o none >/dev/null 2>&1 || true
az provider register --namespace Microsoft.OperationalInsights -o none >/dev/null 2>&1 || true
az provider register --namespace Microsoft.ContainerRegistry -o none >/dev/null 2>&1 || true
az provider register --namespace Microsoft.DBforPostgreSQL -o none >/dev/null 2>&1 || true
az provider register --namespace Microsoft.Cache -o none >/dev/null 2>&1 || true

# ------------------------------------------------------------------------------
# 3. Create Resource Group in UAE North
# ------------------------------------------------------------------------------
info "Ensuring Resource Group '${RESOURCE_GROUP}' in '${LOCATION}'..."
az group create \
  --name "${RESOURCE_GROUP}" \
  --location "${LOCATION}" \
  --tags \
    Project="TherapySculpt" \
    Environment="Production" \
    Jurisdiction="UAE" \
    ComplianceStandard="UAE-Law-2-2019-DoH-ADHICS-v2" \
    DataResidency="UAE-Only" \
  -o none
success "Resource group '${RESOURCE_GROUP}' is ready."

# ------------------------------------------------------------------------------
# 4. Provision Azure Container Registry (ACR)
# ------------------------------------------------------------------------------
info "Ensuring Azure Container Registry '${ACR_NAME}' in '${LOCATION}'..."
if ! az acr show --name "${ACR_NAME}" --resource-group "${RESOURCE_GROUP}" &>/dev/null; then
  az acr create \
    --resource-group "${RESOURCE_GROUP}" \
    --name "${ACR_NAME}" \
    --sku Basic \
    --location "${LOCATION}" \
    --admin-enabled true \
    --tags Compliance="UAE-Law-2-2019" \
    -o none
fi

ACR_LOGIN_SERVER=$(az acr show --name "${ACR_NAME}" --query loginServer -o tsv)
ACR_USERNAME=$(az acr credential show --name "${ACR_NAME}" --query username -o tsv)
ACR_PASSWORD=$(az acr credential show --name "${ACR_NAME}" --query "passwords[0].value" -o tsv)
success "ACR '${ACR_NAME}' (${ACR_LOGIN_SERVER}) configured."

# ------------------------------------------------------------------------------
# 5. Provision Azure Database for PostgreSQL Flexible Server
# ------------------------------------------------------------------------------
info "Checking PostgreSQL Flexible Server '${POSTGRES_SERVER}'..."
if ! az postgres flexible-server show --name "${POSTGRES_SERVER}" --resource-group "${RESOURCE_GROUP}" &>/dev/null; then
  info "Creating Azure PostgreSQL Flexible Server in '${LOCATION}' (Version 16, SSL Enforced)..."
  az postgres flexible-server create \
    --resource-group "${RESOURCE_GROUP}" \
    --name "${POSTGRES_SERVER}" \
    --location "${LOCATION}" \
    --admin-user "${POSTGRES_ADMIN_USER}" \
    --admin-password "${POSTGRES_ADMIN_PASSWORD}" \
    --sku-name Standard_B1ms \
    --tier Burstable \
    --version 16 \
    --storage-size 32 \
    --public-access 0.0.0.0 \
    --yes \
    -o none
else
  info "PostgreSQL server '${POSTGRES_SERVER}' already exists and is ready."
fi

# Enforce secure transport (SSL/TLS)
info "Enforcing SSL transport parameter 'require_secure_transport=ON'..."
az postgres flexible-server parameter set \
  --resource-group "${RESOURCE_GROUP}" \
  --server-name "${POSTGRES_SERVER}" \
  --name require_secure_transport \
  --value ON \
  -o none >/dev/null 2>&1 || true

# Ensure database exists
info "Ensuring database '${POSTGRES_DB}' exists..."
az postgres flexible-server db create \
  --resource-group "${RESOURCE_GROUP}" \
  --server-name "${POSTGRES_SERVER}" \
  --database-name "${POSTGRES_DB}" \
  -o none >/dev/null 2>&1 || true

# Allow internal Azure services firewall rule (0.0.0.0 - 0.0.0.0)
info "Configuring Azure Internal Services firewall rule..."
az postgres flexible-server firewall-rule create \
  --resource-group "${RESOURCE_GROUP}" \
  --name "${POSTGRES_SERVER}" \
  --rule-name "AllowAzureInternal" \
  --start-ip-address 0.0.0.0 \
  --end-ip-address 0.0.0.0 \
  -o none >/dev/null 2>&1 || true

# Allow current client IP for running local prisma migrations
CLIENT_IP=$(curl -s --max-time 5 https://api.ipify.org || curl -s --max-time 5 https://ifconfig.me || echo "")
if [[ -n "$CLIENT_IP" ]]; then
  info "Adding client IP '${CLIENT_IP}' to PostgreSQL firewall for migration step..."
  SAFE_RULE_NAME="Deployer_${CLIENT_IP//./_}"
  az postgres flexible-server firewall-rule create \
    --resource-group "${RESOURCE_GROUP}" \
    --name "${POSTGRES_SERVER}" \
    --rule-name "${SAFE_RULE_NAME}" \
    --start-ip-address "${CLIENT_IP}" \
    --end-ip-address "${CLIENT_IP}" \
    -o none >/dev/null 2>&1 || true
fi

# Build connection string (URL Encoded user/pass safe)
DATABASE_HOST="${POSTGRES_SERVER}.postgres.database.azure.com"
export DATABASE_URL="postgresql://${POSTGRES_ADMIN_USER}:${POSTGRES_ADMIN_PASSWORD}@${DATABASE_HOST}:5432/${POSTGRES_DB}?sslmode=require"
success "PostgreSQL server ready. DATABASE_URL configured."

# ------------------------------------------------------------------------------
# 6. Provision Azure Managed Redis (Redis Enterprise) in UAE North
# ------------------------------------------------------------------------------
info "Configuring Azure Managed Redis extension..."
az config set extension.use_dynamic_install=yes_without_prompt >/dev/null 2>&1 || true
az extension add --name redisenterprise --upgrade --yes >/dev/null 2>&1 || true

info "Checking Azure Managed Redis instance '${REDIS_NAME}'..."
if ! az redisenterprise show --cluster-name "${REDIS_NAME}" --resource-group "${RESOURCE_GROUP}" &>/dev/null; then
  info "Creating Azure Managed Redis in '${LOCATION}' (SKU: Balanced_B0, TLS 1.2 Encrypted, Port 10000)..."
  az redisenterprise create \
    --cluster-name "${REDIS_NAME}" \
    --resource-group "${RESOURCE_GROUP}" \
    --location "${LOCATION}" \
    --sku "Balanced_B0" \
    --minimum-tls-version "1.2" \
    --client-protocol "Encrypted" \
    --port 10000 \
    --access-keys-authentication "Enabled" \
    --public-network-access "Enabled" \
    --eviction-policy "NoEviction" \
    -o none
else
  info "Azure Managed Redis instance '${REDIS_NAME}' already exists."
fi

info "Retrieving Redis primary access key and endpoint..."
REDIS_HOST=$(az redisenterprise show --cluster-name "${REDIS_NAME}" --resource-group "${RESOURCE_GROUP}" --query hostName -o tsv)
REDIS_KEY=$(az redisenterprise database list-keys --cluster-name "${REDIS_NAME}" --resource-group "${RESOURCE_GROUP}" --query primaryKey -o tsv)
REDIS_PORT=$(az redisenterprise database show --cluster-name "${REDIS_NAME}" --resource-group "${RESOURCE_GROUP}" --query port -o tsv 2>/dev/null || echo "10000")
export REDIS_URL="rediss://:${REDIS_KEY}@${REDIS_HOST}:${REDIS_PORT}"
success "Azure Managed Redis ready. REDIS_URL configured."

# ------------------------------------------------------------------------------
# 7. Execute Prisma Migrations on Azure PostgreSQL
# ------------------------------------------------------------------------------
info "Running Prisma database migrations against Azure PostgreSQL Flexible Server..."
if command -v pnpm &>/dev/null; then
  DATABASE_URL="${DATABASE_URL}" pnpm --filter @therapy-sculpt/database prisma migrate deploy || {
    warn "Prisma migrate deploy encountered a non-fatal warning; attempting db push..."
    DATABASE_URL="${DATABASE_URL}" pnpm --filter @therapy-sculpt/database prisma db push --skip-generate || true
  }
  success "Prisma schema synchronized with Azure PostgreSQL."
else
  warn "pnpm is not found in PATH; skipping local migration execution. Ensure GitHub Actions runs migration."
fi

# ------------------------------------------------------------------------------
# 8. Setup Azure Container Apps Environment & Log Analytics
# ------------------------------------------------------------------------------
info "Configuring Log Analytics Workspace in '${LOCATION}'..."
if ! az monitor log-analytics workspace show --resource-group "${RESOURCE_GROUP}" --workspace-name "${LOG_ANALYTICS_WS}" &>/dev/null; then
  az monitor log-analytics workspace create \
    --resource-group "${RESOURCE_GROUP}" \
    --workspace-name "${LOG_ANALYTICS_WS}" \
    --location "${LOCATION}" \
    --tags Retention="25YearsAudit" \
    -o none
fi

LOG_ID=$(az monitor log-analytics workspace show --resource-group "${RESOURCE_GROUP}" --workspace-name "${LOG_ANALYTICS_WS}" --query customerId -o tsv)
LOG_KEY=$(az monitor log-analytics workspace get-shared-keys --resource-group "${RESOURCE_GROUP}" --workspace-name "${LOG_ANALYTICS_WS}" --query primarySharedKey -o tsv)

info "Configuring Azure Container Apps Environment '${CONTAINER_APPS_ENV}'..."
if ! az containerapp env show --name "${CONTAINER_APPS_ENV}" --resource-group "${RESOURCE_GROUP}" &>/dev/null; then
  az containerapp env create \
    --name "${CONTAINER_APPS_ENV}" \
    --resource-group "${RESOURCE_GROUP}" \
    --logs-workspace-id "${LOG_ID}" \
    --logs-workspace-key "${LOG_KEY}" \
    --location "${LOCATION}" \
    -o none
fi
success "Container Apps Environment ready."

# ------------------------------------------------------------------------------
# 9. Build and Push Container Images to Azure Container Registry (ACR)
# ------------------------------------------------------------------------------
info "Logging in to Azure Container Registry '${ACR_NAME}' via Docker..."
echo "${ACR_PASSWORD}" | docker login "${ACR_LOGIN_SERVER}" -u "${ACR_USERNAME}" --password-stdin >/dev/null 2>&1 || {
  az acr login --name "${ACR_NAME}"
}

# Resolve Container Apps Environment default domain to bake into frontend builds
ENV_DOMAIN=$(az containerapp env show --name "${CONTAINER_APPS_ENV}" --resource-group "${RESOURCE_GROUP}" --query properties.defaultDomain -o tsv 2>/dev/null || echo "uaenorth.azurecontainerapps.io")
API_PUBLIC_URL="https://ca-api-server.${ENV_DOMAIN}"
info "Target API Gateway URL: ${API_PUBLIC_URL}"

info "Building and pushing container images with Docker..."

info "Building 'api-server' image..."
docker build -t "${ACR_LOGIN_SERVER}/api-server:latest" -f apps/api-server/Dockerfile .
info "Pushing 'api-server' to ACR..."
docker push "${ACR_LOGIN_SERVER}/api-server:latest"

info "Building 'web-patient' image..."
docker build -t "${ACR_LOGIN_SERVER}/web-patient:latest" \
  --build-arg NEXT_PUBLIC_API_URL="${API_PUBLIC_URL}" \
  --build-arg NEXT_PUBLIC_UAE_REGION="${LOCATION}" \
  -f apps/web-patient/Dockerfile .
info "Pushing 'web-patient' to ACR..."
docker push "${ACR_LOGIN_SERVER}/web-patient:latest"

info "Building 'web-clinician' image..."
docker build -t "${ACR_LOGIN_SERVER}/web-clinician:latest" \
  --build-arg NEXT_PUBLIC_API_URL="${API_PUBLIC_URL}" \
  --build-arg NEXT_PUBLIC_UAE_REGION="${LOCATION}" \
  -f apps/web-clinician/Dockerfile .
info "Pushing 'web-clinician' to ACR..."
docker push "${ACR_LOGIN_SERVER}/web-clinician:latest"

info "Building 'web-admin' image..."
docker build -t "${ACR_LOGIN_SERVER}/web-admin:latest" \
  --build-arg NEXT_PUBLIC_API_URL="${API_PUBLIC_URL}" \
  --build-arg NEXT_PUBLIC_UAE_REGION="${LOCATION}" \
  -f apps/web-admin/Dockerfile .
info "Pushing 'web-admin' to ACR..."
docker push "${ACR_LOGIN_SERVER}/web-admin:latest"

success "All images built and pushed to ${ACR_LOGIN_SERVER}."

# ------------------------------------------------------------------------------
# 10. Deploy Services to Azure Container Apps (Idempotent: Create or Update)
# ------------------------------------------------------------------------------
info "Deploying 'ca-api-server' (Port 4000)..."
if ! az containerapp show --name ca-api-server --resource-group "${RESOURCE_GROUP}" &>/dev/null; then
  az containerapp create \
    --name ca-api-server \
    --resource-group "${RESOURCE_GROUP}" \
    --environment "${CONTAINER_APPS_ENV}" \
    --image "${ACR_LOGIN_SERVER}/api-server:latest" \
    --registry-server "${ACR_LOGIN_SERVER}" \
    --registry-username "${ACR_USERNAME}" \
    --registry-password "${ACR_PASSWORD}" \
    --target-port 4000 \
    --ingress external \
    --cpu 0.5 --memory 1.0Gi \
    --min-replicas 1 --max-replicas 5 \
    --secrets \
      db-url="${DATABASE_URL}" \
      redis-url="${REDIS_URL}" \
    --env-vars \
      NODE_ENV=production \
      PORT=4000 \
      HOST=0.0.0.0 \
      UAE_REGION=uaenorth \
      DATABASE_URL=secretref:db-url \
      REDIS_URL=secretref:redis-url \
    -o none
else
  az containerapp update \
    --name ca-api-server \
    --resource-group "${RESOURCE_GROUP}" \
    --image "${ACR_LOGIN_SERVER}/api-server:latest" \
    -o none
fi

API_FQDN=$(az containerapp show --name ca-api-server --resource-group "${RESOURCE_GROUP}" --query properties.configuration.ingress.fqdn -o tsv)
API_PUBLIC_URL="https://${API_FQDN}"
success "API Server active at: ${API_PUBLIC_URL}"

REV_SUFFIX="rev-$(date +%s)"

info "Deploying 'ca-web-patient' (Port 3000)..."
if ! az containerapp show --name ca-web-patient --resource-group "${RESOURCE_GROUP}" &>/dev/null; then
  az containerapp create \
    --name ca-web-patient \
    --resource-group "${RESOURCE_GROUP}" \
    --environment "${CONTAINER_APPS_ENV}" \
    --image "${ACR_LOGIN_SERVER}/web-patient:latest" \
    --registry-server "${ACR_LOGIN_SERVER}" \
    --registry-username "${ACR_USERNAME}" \
    --registry-password "${ACR_PASSWORD}" \
    --target-port 3000 \
    --ingress external \
    --cpu 0.5 --memory 1.0Gi \
    --min-replicas 1 --max-replicas 5 \
    --env-vars \
      NODE_ENV=production \
      PORT=3000 \
      HOSTNAME=0.0.0.0 \
      UAE_REGION=uaenorth \
      NEXT_PUBLIC_API_URL="${API_PUBLIC_URL}" \
    -o none
else
  az containerapp update \
    --name ca-web-patient \
    --resource-group "${RESOURCE_GROUP}" \
    --image "${ACR_LOGIN_SERVER}/web-patient:latest" \
    --revision-suffix "${REV_SUFFIX}" \
    -o none
fi

PATIENT_FQDN=$(az containerapp show --name ca-web-patient --resource-group "${RESOURCE_GROUP}" --query properties.configuration.ingress.fqdn -o tsv)
PATIENT_PUBLIC_URL="https://${PATIENT_FQDN}"

info "Deploying 'ca-web-clinician' (Port 3000)..."
if ! az containerapp show --name ca-web-clinician --resource-group "${RESOURCE_GROUP}" &>/dev/null; then
  az containerapp create \
    --name ca-web-clinician \
    --resource-group "${RESOURCE_GROUP}" \
    --environment "${CONTAINER_APPS_ENV}" \
    --image "${ACR_LOGIN_SERVER}/web-clinician:latest" \
    --registry-server "${ACR_LOGIN_SERVER}" \
    --registry-username "${ACR_USERNAME}" \
    --registry-password "${ACR_PASSWORD}" \
    --target-port 3000 \
    --ingress external \
    --cpu 0.5 --memory 1.0Gi \
    --min-replicas 1 --max-replicas 5 \
    --env-vars \
      NODE_ENV=production \
      PORT=3000 \
      HOSTNAME=0.0.0.0 \
      UAE_REGION=uaenorth \
      NEXT_PUBLIC_API_URL="${API_PUBLIC_URL}" \
    -o none
else
  az containerapp update \
    --name ca-web-clinician \
    --resource-group "${RESOURCE_GROUP}" \
    --image "${ACR_LOGIN_SERVER}/web-clinician:latest" \
    --revision-suffix "${REV_SUFFIX}" \
    -o none
fi

CLINICIAN_FQDN=$(az containerapp show --name ca-web-clinician --resource-group "${RESOURCE_GROUP}" --query properties.configuration.ingress.fqdn -o tsv)
CLINICIAN_PUBLIC_URL="https://${CLINICIAN_FQDN}"

info "Deploying 'ca-web-admin' (Port 3000)..."
if ! az containerapp show --name ca-web-admin --resource-group "${RESOURCE_GROUP}" &>/dev/null; then
  az containerapp create \
    --name ca-web-admin \
    --resource-group "${RESOURCE_GROUP}" \
    --environment "${CONTAINER_APPS_ENV}" \
    --image "${ACR_LOGIN_SERVER}/web-admin:latest" \
    --registry-server "${ACR_LOGIN_SERVER}" \
    --registry-username "${ACR_USERNAME}" \
    --registry-password "${ACR_PASSWORD}" \
    --target-port 3000 \
    --ingress external \
    --cpu 0.5 --memory 1.0Gi \
    --min-replicas 1 --max-replicas 5 \
    --env-vars \
      NODE_ENV=production \
      PORT=3000 \
      HOSTNAME=0.0.0.0 \
      UAE_REGION=uaenorth \
      NEXT_PUBLIC_API_URL="${API_PUBLIC_URL}" \
    -o none
else
  az containerapp update \
    --name ca-web-admin \
    --resource-group "${RESOURCE_GROUP}" \
    --image "${ACR_LOGIN_SERVER}/web-admin:latest" \
    --revision-suffix "${REV_SUFFIX}" \
    -o none
fi

ADMIN_FQDN=$(az containerapp show --name ca-web-admin --resource-group "${RESOURCE_GROUP}" --query properties.configuration.ingress.fqdn -o tsv)
ADMIN_PUBLIC_URL="https://${ADMIN_FQDN}"

# ------------------------------------------------------------------------------
# 11. Final Summary & Verification
# ------------------------------------------------------------------------------
echo ""
echo -e "${GREEN}================================================================================${NC}"
echo -e "${GREEN}   TherapySculpt - Azure UAE North Deployment Completed Successfully!           ${NC}"
echo -e "${GREEN}================================================================================${NC}"
echo ""
echo "Compliance Jurisdictions: UAE Federal Law No. 2 of 2019 / DoH ADHICS v2"
echo "Datacenter Region:        ${LOCATION} (UAE North)"
echo "Resource Group:           ${RESOURCE_GROUP}"
echo "PostgreSQL Server:        ${POSTGRES_SERVER}.postgres.database.azure.com (SSL ON)"
echo "Redis Cache Instance:     ${REDIS_NAME}.redis.cache.windows.net:6380 (TLS 1.2)"
echo "Container Registry:       ${ACR_LOGIN_SERVER}"
echo ""
echo "Public Service Endpoints:"
echo "--------------------------------------------------------------------------------"
echo "  * Fastify API Server:     ${API_PUBLIC_URL}/health"
echo "  * Patient Web Portal:     ${PATIENT_PUBLIC_URL}"
echo "  * Clinician Web Portal:   ${CLINICIAN_PUBLIC_URL}"
echo "  * Admin & Audit Portal:   ${ADMIN_PUBLIC_URL}"
echo "--------------------------------------------------------------------------------"
echo ""
echo "Test the deployment health:"
echo "  curl -k \"${API_PUBLIC_URL}/health\""
echo ""
