# Rohit — Secure Node.js API on Google Cloud Run

Secure deployment of a containerized Node.js REST API on Google Cloud Run, using DevSecOps principles. Infrastructure is fully managed by Terraform. CI/CD runs on GitHub Actions with Workload Identity Federation.

---

## Architecture Overview

```
GitHub Actions (CI/CD)
       │
       ▼
Artifact Registry ──► Cloud Run (rohit-api)
                              │  (VPC Connector)
                              ▼
                       Cloud SQL PostgreSQL
                       (private VPC only)
                              │
                       Secret Manager
                       (DB credentials)
```

**Traffic between Cloud Run and Cloud SQL never leaves the VPC.**

---

## Project Structure

```
rohit/
├── app/                        # Node.js REST API
│   ├── src/
│   │   ├── index.js            # Express app entry point
│   │   ├── db.js               # PostgreSQL connection pool
│   │   ├── routes/
│   │   │   ├── health.js       # GET /health
│   │   │   └── patients.js     # CRUD /api/patients
│   │   └── middleware/
│   │       └── logger.js       # Winston structured logging
│   └── tests/                  # Jest unit tests
├── Dockerfile                  # Multi-stage, non-root, Alpine
├── .dockerignore
├── scripts/
│   └── init-db.sql             # DB schema bootstrap
├── terraform/
│   ├── main.tf                 # Root module wiring
│   ├── variables.tf
│   ├── outputs.tf
│   ├── versions.tf
│   └── modules/
│       ├── vpc/                # VPC, subnets, VPC connector
│       ├── iam/                # Service accounts + WIF for GitHub Actions
│       ├── cloud_sql/          # PostgreSQL on private VPC
│       ├── secret_manager/     # DB credentials in Secret Manager
│       ├── cloud_run/          # Cloud Run service + Artifact Registry
│       └── monitoring/         # Alerts, log metrics, notification channels
└── .github/
    └── workflows/
        ├── ci.yml              # Lint, test, Docker build, Trivy scan, Terraform validate
        └── cd.yml              # Build, push, deploy on main branch merge
```

---

## Setup & Deployment

### Prerequisites

- GCP project with billing enabled
- Terraform >= 1.6
- `gcloud` CLI authenticated
- GitHub repository

### 1. Enable required GCP APIs

```bash
gcloud services enable \
  run.googleapis.com \
  sqladmin.googleapis.com \
  secretmanager.googleapis.com \
  artifactregistry.googleapis.com \
  vpcaccess.googleapis.com \
  servicenetworking.googleapis.com \
  iam.googleapis.com \
  iamcredentials.googleapis.com \
  monitoring.googleapis.com \
  logging.googleapis.com
```

### 2. Create Terraform state bucket

```bash
gsutil mb -p YOUR_PROJECT_ID gs://rohit-tfstate
gsutil versioning set on gs://rohit-tfstate
```

### 3. Deploy infrastructure

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values

terraform init
terraform plan
terraform apply
```

### 4. Configure GitHub Actions secrets

After `terraform apply`, add these secrets to your GitHub repository:

| Secret | Value |
|--------|-------|
| `GCP_PROJECT_ID` | Your GCP project ID |
| `WIF_PROVIDER` | Output: `workload_identity_provider` |
| `WIF_SERVICE_ACCOUNT` | Output: `cicd_sa_email` |

### 5. Bootstrap the database schema

```bash
gcloud sql connect rohit-postgres --user=rohit_user --database=rohit
# Then paste contents of scripts/init-db.sql
```

### 6. Push to main to trigger CD

```bash
git push origin main
```

---

## API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/health` | Health check (DB connectivity) |
| `GET` | `/api/patients` | List all patients |
| `GET` | `/api/patients/:id` | Get patient by ID |
| `POST` | `/api/patients` | Create patient `{ name, email }` |
| `DELETE` | `/api/patients/:id` | Delete patient |

---

## CI/CD Pipeline

### CI (runs on every push/PR)

1. **ESLint** — code quality check
2. **Jest unit tests** — with coverage report
3. **Docker build** — multi-stage optimized image
4. **Trivy scan** — Docker image vulnerability scan (fails on CRITICAL/HIGH)
5. **Terraform fmt** — formatting check
6. **Terraform validate** — configuration validation
7. **tflint** — Terraform linting

### CD (runs only on `main` merge, after CI passes)

1. Authenticate to GCP via **Workload Identity Federation** (no JSON keys)
2. Build and push Docker image to **Artifact Registry**
3. Re-scan pushed image with Trivy (fails on CRITICAL)
4. Deploy to **Cloud Run**
5. Verify deployment via `/health` endpoint

---

## Security Measures

### IAM — Principle of Least Privilege
- No primitive roles (Owner/Editor/Viewer) used anywhere
- `rohit-cloudrun-sa`: `artifactregistry.reader` + `secretmanager.secretAccessor` + `logging.logWriter` + `monitoring.metricWriter`
- `rohit-cicd-sa`: `artifactregistry.writer` + `run.developer` + `iam.serviceAccountUser`
- Secret Manager IAM scoped to the individual secret, not project-wide

### Authentication
- GitHub Actions uses **Workload Identity Federation (OIDC)** — no long-lived JSON keys
- Repository-scoped attribute condition prevents other repos from impersonating the SA

### Network
- Cloud SQL has **no public IP** (`ipv4_enabled = false`)
- All Cloud Run → Cloud SQL traffic routes through the **VPC connector** (`PRIVATE_RANGES_ONLY` egress)
- Firewall denies all ingress by default; only VPC-internal ranges allowed

### Secret Management
- Database password generated by Terraform (`random_password`) and stored in **Secret Manager**
- Injected at runtime via Cloud Run secret env var — never in code, logs, or CI configs
- `.env` files are gitignored; `.env.example` has no real values

### Container Security
- Multi-stage Docker build — builder stage discarded
- `node:20-alpine` base — minimal attack surface
- Runs as **non-root user** (`appuser`)
- `apk --no-cache upgrade` patches Alpine security updates at build time
- Trivy scans block deployment on CRITICAL vulnerabilities

### Application
- `helmet` sets secure HTTP headers
- Rate limiting (100 req/min per IP)
- Request body size limit (10kb)
- Parameterized SQL queries (no SQL injection risk)
- Structured JSON logging via Winston (no sensitive data logged)

---

## Monitoring & Alerting

### Log-based Metrics
- `rohit/error_count` — counts ERROR+ severity logs from the Cloud Run service
- `rohit/request_latency` — distribution of HTTP request latencies

### Alert Policies

| Condition | Threshold | Channel |
|-----------|-----------|---------|
| CPU utilization | > 70% for 1 min | Google Chat (warning) |
| CPU utilization | > 80% for 5 min | Email + Google Chat (critical) |
| Memory utilization | > 70% for 1 min | Google Chat (warning) |
| Memory utilization | > 80% for 5 min | Email + Google Chat (critical) |
| Error log rate | > 10 errors in 5 min | Email + Google Chat (critical) |

### Notification Channels
Both configured in Terraform:
- `google_monitoring_notification_channel.email` — email alert for critical
- `google_monitoring_notification_channel.google_chat` — webhook for warnings and critical

---

## Assumptions

1. **PostgreSQL 15** used over MySQL (better JSON support, query insights).
2. **`db-g1-small`** Cloud SQL tier assumed sufficient for assessment; production would use `db-n1-standard-2` or higher with read replicas.
3. Cloud Run set to **allow unauthenticated** (public API). For internal use, this should be changed to authenticated with IAP or API gateway.
4. Terraform state stored in GCS. Remote state locking via GCS object versioning.
5. Database schema migration is manual (`scripts/init-db.sql`) for simplicity. Production would use a migration tool (e.g., Flyway, golang-migrate).
6. `REGIONAL` availability for Cloud SQL (multi-zone failover within a region).

---

## Local Development

```bash
# Start a local PostgreSQL
docker run -d --name pg -e POSTGRES_PASSWORD=changeme -e POSTGRES_DB=rohit -p 5432:5432 postgres:15-alpine

# Set up env
cp .env.example .env

# Install and run
cd app
npm install
npm run dev

# Run tests
npm test

# Lint
npm run lint
```
