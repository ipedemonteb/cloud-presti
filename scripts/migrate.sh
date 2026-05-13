#!/bin/bash
set -e

ACTION=${1:-up}

echo "==> Corriendo migraciones (${ACTION})"
# Limpiamos el archivo temporal antes por si existiera
rm -f /tmp/migrate-response.json

# Invocamos la Lambda
aws lambda invoke \
  --function-name cloud-presti-db-migrations \
  --log-type Tail \
  --region us-east-1 \
  --cli-read-timeout 0 \
  --cli-binary-format raw-in-base64-out \
  --payload "{\"action\": \"${ACTION}\"}" \
  --query 'LogResult' \
  --output text \
  /tmp/migrate-response.json | (base64 -d 2>/dev/null || base64 -D)

echo ""
echo "=== Output de la invocación ==="
cat /tmp/migrate-response.json
echo ""

if grep -q '"errorType"' /tmp/migrate-response.json || grep -q '"errorMessage"' /tmp/migrate-response.json; then
  echo "ERROR: Las migraciones fallaron."
  exit 1
fi

echo "Migraciones completadas exitosamente."
