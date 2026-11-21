# TherapySculpt - Enterprise Azure UAE North Operator & Hosting Guide

This guide provides end-to-end operational instructions for deploying and maintaining the **TherapySculpt** monorepo application on Microsoft Azure in the **UAE North (`uaenorth`)** region.

---

## 1. Compliance & Architecture Overview

Under **UAE Federal Law No. 2 of 2019 (Article 13)** and the **Abu Dhabi Department of Health (DoH) ADHICS v2 Standard**, all electronic health data, screening results, patient identifiers, and clinical audit logs must reside strictly within UAE sovereign boundaries.

### Infrastructure Topology

```mermaid
flowchart TD
    subgraph Users["End Users & Healthcare Providers (UAE)"]
        Patient["Patients (Web / Mobile)"]
        Clinician["Licensed Clinicians (Web Portal)"]
        Admin["Clinical Governance / Audit"]
    end

    subgraph AzureUAE["Microsoft Azure UAE North (uaenorth)"]
        subgraph IngressLayer["Ingress & Container Apps Environment (cae-therapysculpt-uaenorth)"]
            CAPatient["ca-web-patient (Port 3000)<br/>Next.js 15 Standalone"]
            CAClinician["ca-web-clinician (Port 3000)<br/>Next.js 15 Standalone"]
            CAAdmin["ca-web-admin (Port 3000)<br/>Next.js 15 Standalone"]
            CAAPI["ca-api-server (Port 4000)<br/>Fastify / Node 20"]
        end

        subgraph BackgroundWorkers["Asynchronous Background Services"]
            WorkerScoring["worker-scoring (BullMQ)"]
            WorkerCrisis["worker-crisis-dispatch (15m SLA)"]
        end

        subgraph Persistence["Managed UAE Data Stores"]
            PostgreSQL[("Azure Database for PostgreSQL<br/>Flexible Server 16 (SSL Enforced)<br/>psql-therapysculpt-uaenorth")]
            Redis[("Azure Managed Redis<br/>TLS 1.2 (Port 10000)<br/>redis-therapysculpt-uaenorth")]
        end

        subgraph MonitoringRegistry["Observability & Artifacts"]
            ACR["Azure Container Registry<br/>acrtherapysculptuae"]
            LogAnalytics["Log Analytics Workspace<br/>(25-Yr Audit Retention)"]
        end
    end

    Patient -->|HTTPS:443| CAPatient
    Clinician -->|HTTPS:443| CAClinician
    Admin -->|HTTPS:443| CAAdmin

    CAPatient -->|REST API| CAAPI
    CAClinician -->|REST API| CAAPI
    CAAdmin -->|REST API| CAAPI

    CAAPI -->|Prisma TLS:5432| PostgreSQL
    CAAPI -->|BullMQ TLS:10000| Redis
    WorkerScoring --> Redis
    WorkerCrisis --> Redis
    WorkerScoring --> PostgreSQL
    WorkerCrisis --> PostgreSQL

    IngressLayer -.-> LogAnalytics
    ACR -.-> IngressLayer
```

---

## 2. Prerequisites

Ensure the following tools are installed on your workstation:
- **Azure CLI (`az`)**: Version 2.60+ ([Download Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli))
- **Node.js**: Version 20 LTS or higher
- **pnpm**: Version 9.15.0+ (`corepack enable && corepack prepare pnpm@9.15.0 --activate`)
- **Docker**: Version 24+ (Docker Desktop or Docker Engine - required for local Compose testing)

### Step 2.1: Authenticate with Azure

```bash
# Log in to Azure interactively
az login

# List accessible subscriptions
az account list --output table

# Set your target subscription
az account set --subscription "<YOUR_SUBSCRIPTION_NAME_OR_ID>"

# Verify active subscription and location
az account show --query "{Subscription:name, ID:id, TenantId:tenantId}" -o table
```

---

## 3. Local Verification with Docker Compose

Before pushing to Microsoft Azure, test the containerized multi-stage builds and internal network dependencies locally:

```bash
# 1. Start all services in detached mode
docker compose up -d --build

# 2. Inspect container status
docker compose ps

# 3. Verify API Server health endpoint
curl http://localhost:4000/health
# Response: {"status":"ok","region":"uaenorth","service":"api-server"}

# 4. Open web applications in your browser:
#    - Patient Portal:   http://localhost:3000
#    - Clinician Portal: http://localhost:3001
#    - Admin Portal:     http://localhost:3002

# 5. Stop the local stack when finished
docker compose down
```

---

## 4. Automated Provisioning & Deployment to Azure

TherapySculpt provides automated provisioning scripts that set up the complete UAE North infrastructure, enforce SSL/TLS, build container images via ACR cloud tasks, execute Prisma migrations, and deploy the Container Apps.

### Option A: Using Bash (Linux / macOS / WSL / Git Bash)

```bash
# 1. (Optional) Pre-set environment variables
export POSTGRES_ADMIN_PASSWORD="YourStrongPassword2026!#"
export LOCATION="uaenorth"

# 2. Make the script executable
chmod +x scripts/deploy-azure.sh

# 3. Execute deployment
./scripts/deploy-azure.sh
```

### Option B: Using Windows PowerShell

```powershell
# 1. Run the PowerShell deployment script
.\scripts\deploy-azure.ps1 -Location "uaenorth"
```

### What the script executes automatically:
1. Validates Azure CLI login and registers `Microsoft.App`, `Microsoft.DBforPostgreSQL`, and `Microsoft.Cache` providers.
2. Creates Resource Group `rg-therapysculpt-prod-uaenorth` in `uaenorth`.
3. Provisions Azure Database for PostgreSQL Flexible Server 16 (`psql-therapysculpt-uaenorth`) with `require_secure_transport=ON`.
4. Provisions Azure Managed Redis (`redis-therapysculpt-uaenorth`) with TLS 1.2 on port 10000.
5. Provisions Azure Container Registry (`acrtherapysculptuae`).
6. Executes `pnpm --filter @therapy-sculpt/database prisma migrate deploy` to synchronize database tables.
7. Provisions Log Analytics Workspace and Azure Container Apps Environment (`cae-therapysculpt-uaenorth`).
8. Builds multi-stage Docker images (`api-server`, `web-patient`, `web-clinician`, `web-admin`) in ACR.
9. Deploys container applications with configured health checks and managed secrets.

---

## 5. How to Retrieve Public URLs & Verify Health

To query the live public URLs (FQDNs) allocated by Azure Container Apps:

```bash
# List all container apps and their public ingress FQDNs
az containerapp list \
  --resource-group rg-therapysculpt-prod-uaenorth \
  --query "[].{Service:name, FQDN:properties.configuration.ingress.fqdn, Status:properties.runningStatus}" \
  --output table
```

### Live Production Endpoints (UAE North):

| Service | Public FQDN | Health / Entry Route |
| :--- | :--- | :--- |
| **API Server (Fastify)** | `https://ca-api-server.redwave-0acb0d4d.uaenorth.azurecontainerapps.io` | [`/health`](https://ca-api-server.redwave-0acb0d4d.uaenorth.azurecontainerapps.io/health) |
| **Patient Web Portal** | `https://ca-web-patient.redwave-0acb0d4d.uaenorth.azurecontainerapps.io` | [`/` (redirects to `/en`)](https://ca-web-patient.redwave-0acb0d4d.uaenorth.azurecontainerapps.io/) \| [`/ar`](https://ca-web-patient.redwave-0acb0d4d.uaenorth.azurecontainerapps.io/ar) |
| **Clinician Web Portal** | `https://ca-web-clinician.redwave-0acb0d4d.uaenorth.azurecontainerapps.io` | [`/` (redirects to `/en`)](https://ca-web-clinician.redwave-0acb0d4d.uaenorth.azurecontainerapps.io/) \| [`/ar`](https://ca-web-clinician.redwave-0acb0d4d.uaenorth.azurecontainerapps.io/ar) |
| **Admin & Audit Portal** | `https://ca-web-admin.redwave-0acb0d4d.uaenorth.azurecontainerapps.io` | [`/` (redirects to `/en`)](https://ca-web-admin.redwave-0acb0d4d.uaenorth.azurecontainerapps.io/) \| [`/ar`](https://ca-web-admin.redwave-0acb0d4d.uaenorth.azurecontainerapps.io/ar) |

> [!NOTE]
> All frontends are built using Next.js 15 App Router with full bilingual localized routing (`app/[lang]`). Root requests (`/`) automatically issue a 307 redirect to the English locale (`/en`), while Arabic can be reached directly via `/ar`.

### Direct Portal FQDN Retrieval:

```bash
# 1. API Server Health URL
API_FQDN=$(az containerapp show --name ca-api-server --resource-group rg-therapysculpt-prod-uaenorth --query properties.configuration.ingress.fqdn -o tsv)
echo "API Health: https://${API_FQDN}/health"

# 2. Patient Portal URL
PATIENT_FQDN=$(az containerapp show --name ca-web-patient --resource-group rg-therapysculpt-prod-uaenorth --query properties.configuration.ingress.fqdn -o tsv)
echo "Patient Web Portal: https://${PATIENT_FQDN}"

# 3. Clinician Portal URL
CLINICIAN_FQDN=$(az containerapp show --name ca-web-clinician --resource-group rg-therapysculpt-prod-uaenorth --query properties.configuration.ingress.fqdn -o tsv)
echo "Clinician Web Portal: https://${CLINICIAN_FQDN}"

# 4. Admin & Audit Portal URL
ADMIN_FQDN=$(az containerapp show --name ca-web-admin --resource-group rg-therapysculpt-prod-uaenorth --query properties.configuration.ingress.fqdn -o tsv)
echo "Admin Governance Portal: https://${ADMIN_FQDN}"
```

### Probing API Health via cURL:

```bash
curl -i "https://${API_FQDN}/health"
```
Expected output:
```json
HTTP/2 200
content-type: application/json; charset=utf-8

{"status":"ok","region":"uaenorth","service":"api-server"}
```

---

## 6. Configuring GitHub Actions CI/CD Pipeline

The `.github/workflows/deploy-azure.yml` pipeline automatically builds, tests, runs database migrations, and deploys new container versions upon every push to `main`.

### Required GitHub Repository Secrets

Navigate to your GitHub Repository -> **Settings** -> **Secrets and variables** -> **Actions** -> **New repository secret**:

| Secret Name | Description | Example / Source |
| :--- | :--- | :--- |
| `AZURE_CLIENT_ID` | Service Principal / Managed Identity App ID | `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` |
| `AZURE_TENANT_ID` | Azure Active Directory Tenant ID | `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` |
| `AZURE_SUBSCRIPTION_ID` | Azure Subscription ID | `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` |
| `AZURE_CREDENTIALS` | *(Alternative)* Full Service Principal JSON output | `{"clientId": "...", "clientSecret": "..."}` |
| `DATABASE_URL` | PostgreSQL connection string with SSL | `postgresql://tsadmin:Pass@psql-therapysculpt-uaenorth.../therapysculpt?sslmode=require` |
| `NEXT_PUBLIC_API_URL` | Full public URL of the Fastify API Server | `https://ca-api-server.<id>.uaenorth.azurecontainerapps.io` |

### Setting Up Azure OIDC Federated Credentials (Recommended)

To authenticate GitHub Actions without storing long-lived secrets:

```bash
# 1. Create Azure AD Application & Service Principal
APP_ID=$(az ad app create --display-name "github-actions-therapysculpt" --query appId -o tsv)
SP_ID=$(az ad sp create --id "$APP_ID" --query id -o tsv)

# 2. Assign Contributor role on Resource Group
az role assignment create \
  --role "Contributor" \
  --assignee "$APP_ID" \
  --scope "/subscriptions/<SUBSCRIPTION_ID>/resourceGroups/rg-therapysculpt-prod-uaenorth"

# 3. Create OIDC Federated Credential for GitHub repository
az ad app federated-credential create \
  --id "$APP_ID" \
  --parameters '{
    "name": "github-main-branch",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:<GITHUB_ORG_OR_USER>/TherapySculpt:ref:refs/heads/main",
    "audiences": ["api://AzureADTokenExchange"]
  }'
```

---

## 7. Monitoring, Logs & Diagnostics

### View Real-Time Live Container Logs:

```bash
# Stream API Server logs
az containerapp logs show \
  --name ca-api-server \
  --resource-group rg-therapysculpt-prod-uaenorth \
  --follow

# Stream Web Patient logs
az containerapp logs show \
  --name ca-web-patient \
  --resource-group rg-therapysculpt-prod-uaenorth \
  --follow
```

### Ingress & Scaling Settings:

Each Azure Container App is configured with auto-scaling from 1 to 5 replicas based on concurrent HTTP requests (100 requests per replica). To update scaling rules:

```bash
az containerapp update \
  --name ca-api-server \
  --resource-group rg-therapysculpt-prod-uaenorth \
  --min-replicas 2 \
  --max-replicas 10
```

---

## 8. Emergency Runbook & Rollback Procedures

### Rollback Container App Revision:

```bash
# List all active and previous revisions
az containerapp revision list \
  --name ca-api-server \
  --resource-group rg-therapysculpt-prod-uaenorth \
  --output table

# Revert traffic to a previous stable revision
az containerapp ingress traffic set \
  --name ca-api-server \
  --resource-group rg-therapysculpt-prod-uaenorth \
  --revision-weight <STABLE_REVISION_NAME>=100
```
