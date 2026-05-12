#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TF_DIR="${SCRIPT_DIR}/terraform"

if [ -z "$TF_STATE_BUCKET" ] || [ -z "$TF_LOCK_TABLE" ]; then
  echo "Faltan variables de entorno:"
  echo "  export TF_STATE_BUCKET=<nombre-del-bucket>"
  echo "  export TF_LOCK_TABLE=<nombre-de-la-tabla>"
  exit 1
fi

read -p "Escribí 'destroy' para confirmar: " CONFIRM
if [ "$CONFIRM" != "destroy" ]; then
  echo "Cancelado."
  exit 1
fi

TF_INIT_ARGS=(
  -backend-config="bucket=${TF_STATE_BUCKET}"
  -backend-config="key=terraform.tfstate"
  -backend-config="region=us-east-1"
  -backend-config="dynamodb_table=${TF_LOCK_TABLE}"
)

# --- Terraform destroy ---
echo "==> Terraform destroy"
cd "${TF_DIR}"
terraform init -reconfigure "${TF_INIT_ARGS[@]}"
terraform destroy -auto-approve

echo ""
echo "Infraestructura destruida."
