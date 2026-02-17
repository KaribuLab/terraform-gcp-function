#!/usr/bin/env bash
set -euo pipefail

# Script de limpieza de recursos GCP para pruebas Terratest.
# Usa gcloud CLI para eliminar Cloud Function y Storage Bucket.
# Best-effort: no falla si los recursos no existen.

GCP_PROJECT_ID="${GCP_PROJECT_ID:-}"
GCP_REGION="${GCP_REGION:-us-central1}"
FUNCTION_NAME="${FUNCTION_NAME:-terratest-gcp-function-test}"
BUCKET_NAME="${BUCKET_NAME:-terratest-bucket-test}"

if [[ -z "$GCP_PROJECT_ID" ]]; then
  echo "Error: GCP_PROJECT_ID no está configurado"
  exit 1
fi

echo "=== Limpieza de recursos GCP ==="
echo "Proyecto: $GCP_PROJECT_ID"
echo "Región: $GCP_REGION"
echo "Función: $FUNCTION_NAME"
echo "Bucket: $BUCKET_NAME"
echo ""

# 1. Eliminar Cloud Function si existe (best-effort, no fallar si no existe)
echo "Eliminando Cloud Function '$FUNCTION_NAME'..."
gcloud functions delete "$FUNCTION_NAME" \
  --project="$GCP_PROJECT_ID" \
  --region="$GCP_REGION" \
  --quiet 2>/dev/null || echo "Cloud Function no existe, omitiendo."

# 2. Eliminar Storage Bucket y sus objetos si existe (best-effort)
echo ""
echo "Eliminando Storage Bucket '$BUCKET_NAME'..."
gsutil -m rm -r "gs://${BUCKET_NAME}" 2>/dev/null || echo "Bucket no existe, omitiendo."

echo ""
echo "=== Limpieza completada ==="
