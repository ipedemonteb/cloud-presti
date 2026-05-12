#!/bin/bash
set -e

ACTION=${1:-up}

echo "==> Corriendo migraciones (${ACTION})"
aws lambda invoke \
  --function-name cloud-presti-db-migrations \
  --log-type Tail \
  --region us-east-1 \
  --cli-read-timeout 0 \
  --cli-binary-format raw-in-base64-out \
  --payload "{\"action\": \"${ACTION}\"}" \
  --query 'LogResult' \
  --output text \
  /tmp/migrate-response.json | base64 -d

echo ""
cat /tmp/migrate-response.json

if grep -q '"errorType"' /tmp/migrate-response.json; then
  echo "ERROR: Las migraciones fallaron."
  exit 1
fi

echo "Migraciones completadas."
