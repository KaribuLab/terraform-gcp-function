#!/usr/bin/env bash
set -euo pipefail

# Script de orquestación para pruebas Terratest.
# Ejecuta pre-limpieza, pruebas y post-limpieza.
# La limpieza siempre se ejecuta, incluso si las pruebas fallan o hay interrupción.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cleanup() {
  echo ""
  echo "=== Post-limpieza ==="
  bash "$SCRIPT_DIR/cleanup_gcp_resources.sh"
}

# Garantizar limpieza en salida normal, por error o por interrupción
trap cleanup EXIT

echo "=== Pre-limpieza ==="
bash "$SCRIPT_DIR/cleanup_gcp_resources.sh"

echo ""
echo "=== Ejecutando pruebas Terratest ==="
cd "$REPO_ROOT/test"
TEST_EXIT_CODE=0
go test -v -timeout 30m || TEST_EXIT_CODE=$?

exit $TEST_EXIT_CODE
