# cloud-presti

Plataforma fintech que sugiere potenciales clientes a entidades financieras mediante un motor de scoring crediticio basado en datos del BCRA. Proyecto académico para la materia Cloud Computing (ITBA).

## Arquitectura

```
┌─────────────────────────────────────────────────────────────┐
│                        AWS (us-east-1)                      │
│                                                             │
│   S3 (frontend estático)      VPC 10.0.0.0/16              │
│   ┌──────────────────┐        ┌──────────────────────────┐  │
│   │  React + Vite    │        │  Subnets públicas (NAT)  │  │
│   │  Dashboard SPA   │        │  Subnets privadas        │  │
│   └──────────────────┘        └──────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
         ↑
         │ terraform apply (GitHub Actions)
         │
┌─────────────────┐
│  Python Engine  │  ← datos BCRA → preprocessing → MLP → score 0.0–1.0
└─────────────────┘
```

## Estructura del repositorio

```
cloud-presti/
├── frontend/        # SPA React + Vite (dashboard para entidades financieras)
├── engine/          # Motor de scoring crediticio en Python
├── terraform/       # Infraestructura AWS con Terraform
│   └── modules/
│       └── network/ # Módulo reutilizable de VPC
├── backend/         # (en desarrollo)
└── .github/
    └── workflows/
        └── terraform.yml  # CI/CD de infraestructura
```

## Cómo funciona el scoring

1. **Fuente de datos**: archivos del BCRA (`deudores.txt` + `24DSF.txt`)
2. **Features**: ~23 variables por CUIT — situación actual, días de atraso, ratios de cobertura, tendencia a 24 meses, etc.
3. **Modelo**: MLP (TensorFlow/Keras) → `Input → Dense(16, relu) → Dense(1, sigmoid)`
4. **Score**: valor continuo entre `0.0` (irrecuperable) y `1.0` (excelente)
5. **Recomendación**: el dashboard muestra productos financieros elegibles según el score de cada cliente

Ver [`engine/README.md`](engine/README.md) para documentación detallada del pipeline.

---

## Infraestructura (Terraform)

La infraestructura vive en `terraform/` y se despliega sobre AWS con Terraform >= 1.9.

### Recursos actuales

| Recurso | Descripción |
|---|---|
| `aws_s3_bucket` | Hosting estático del frontend |
| VPC module | VPC con subnets públicas/privadas, NAT Gateways, Internet Gateway y Security Groups |

### Getting started (local)

#### Requisitos

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.9
- [AWS CLI](https://aws.amazon.com/cli/) configurado con credenciales válidas
- Node.js 20+ (para el build del frontend)

#### 1. Crear el bucket de Terraform state (una sola vez)

```bash
aws s3api create-bucket \
  --bucket <tu-bucket-de-state> \
  --region us-east-1

aws s3api put-bucket-versioning \
  --bucket <tu-bucket-de-state> \
  --versioning-configuration Status=Enabled
```

#### 2. Construir el frontend

```bash
cd frontend
npm ci
npm run build
cd ..
```

#### 3. Inicializar Terraform con tu bucket de state

```bash
cd terraform
terraform init \
  -backend-config="bucket=<tu-bucket-de-state>" \
  -backend-config="key=terraform.tfstate" \
  -backend-config="region=us-east-1"
```

#### 4. Aplicar

```bash
terraform plan -var="bucket_name=<tu-bucket-de-frontend>"
terraform apply -var="bucket_name=<tu-bucket-de-frontend>"
```

---

## CI/CD (GitHub Actions)

El workflow `.github/workflows/terraform.yml` automatiza el despliegue de infraestructura.

### Comportamiento

| Evento | Acción |
|---|---|
| Push a `main` (cambios en `terraform/` o `frontend/`) | Build frontend → `terraform plan` → `terraform apply` |
| PR a `main` (cambios en `terraform/` o `frontend/`) | Build frontend → `terraform plan` (solo muestra cambios, no aplica) |

### Configuración de GitHub

En **Settings → Secrets and variables → Actions** del repositorio:

**Secrets** (se renuevan con cada sesión del lab):

| Secret | Descripción |
|---|---|
| `AWS_ACCESS_KEY_ID` | Access key de AWS |
| `AWS_SECRET_ACCESS_KEY` | Secret key de AWS |
| `AWS_SESSION_TOKEN` | Session token (requerido en cuentas de laboratorio) |

**Variables** (se configuran una sola vez):

| Variable | Ejemplo | Descripción |
|---|---|---|
| `TF_STATE_BUCKET` | `cloud-presti-tfstate` | Bucket S3 para el Terraform state |
| `TF_FRONTEND_BUCKET_NAME` | `cloud-presti-frontend` | Bucket S3 del frontend |

> **Nota sobre cuentas de laboratorio**: las credenciales temporales de AWS Academy vencen cada 4–12 horas. Cuando el workflow falle por autenticación, actualizá los tres Secrets desde la consola del lab y el próximo run funcionará.

---

## Módulo de red (network)

Módulo Terraform reutilizable que crea una VPC completa. Ver [`terraform/modules/network/README.md`](terraform/modules/network/README.md) para documentación de variables, outputs y ejemplos de uso.

## Engine de scoring

Pipeline de preprocessing y entrenamiento del modelo crediticio. Ver [`engine/README.md`](engine/README.md).
