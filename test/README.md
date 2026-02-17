# Pruebas del módulo Terraform GCP Cloud Functions Gen 2

Este directorio contiene pruebas automatizadas para el módulo de Terraform que crea Cloud Functions 2nd generation en GCP.

## Requisitos previos

1. **Go**: Versión 1.21 o superior
2. **Terraform**: Versión 1.3 o superior
3. **Credenciales de GCP**: Configuradas mediante \`gcloud auth application-default login\`
4. **Permisos en GCP**:
   - Cloud Functions Admin
   - Cloud Run Admin
   - Cloud Build Editor
   - Storage Admin
   - Service Account Admin
   - IAM Admin

## APIs requeridas en GCP

Asegúrate de que las siguientes APIs estén habilitadas en tu proyecto:

```bash
gcloud services enable cloudfunctions.googleapis.com
gcloud services enable cloudbuild.googleapis.com
gcloud services enable run.googleapis.com
gcloud services enable artifactregistry.googleapis.com
gcloud services enable eventarc.googleapis.com
```

## Variables de entorno

Las pruebas requieren las siguientes variables de entorno:

```bash
export GCP_PROJECT_ID="tu-proyecto-gcp"      # REQUERIDO
export GCP_REGION="us-central1"              # Opcional (default: us-central1)
export BUCKET_NAME="nombre-bucket-test"      # Opcional (se genera automáticamente)
export FUNCTION_NAME="nombre-funcion-test"   # Opcional (se genera automáticamente)
```

## Ejecutar las pruebas

### Todas las pruebas

```bash
cd test
go test -v -timeout 30m
```

### Una prueba específica

```bash
cd test
go test -v -timeout 30m -run TestTerraformGcpFunction
```

### Con logs detallados de Terraform

```bash
cd test
TF_LOG=DEBUG go test -v -timeout 30m
```

## Estructura de las pruebas

### \`TestTerraformGcpFunction\`

Prueba básica que valida:
- Creación de la Cloud Function Gen 2
- Estado ACTIVE de la función
- URL de la función
- Respuesta HTTP correcta
- Creación de la cuenta de servicio

### \`TestTerraformGcpFunctionWithIAMRoles\`

Prueba avanzada que valida:
- Creación de la función con roles IAM adicionales
- Asignación correcta de roles a la cuenta de servicio
- Roles probados: \`roles/storage.objectViewer\`, \`roles/pubsub.subscriber\`

## Fixtures

### \`fixtures/src/\`

Contiene el código fuente de ejemplo de la Cloud Function Gen 2 (Node.js) usado en las pruebas.

**Nota importante**: El código usa \`@google-cloud/functions-framework\` que es requerido para Cloud Functions Gen 2.

### \`fixtures/bucket/\`

Módulo auxiliar de Terraform para crear el bucket de almacenamiento necesario para las pruebas. El módulo principal ya no crea el bucket, por lo que las pruebas lo crean de forma independiente.

## Diferencias con Gen 1

Las pruebas para Gen 2 incluyen cambios importantes:

1. **Outputs diferentes**:
   - \`function_status\` → \`function_state\`
   - \`function_https_trigger_url\` → \`function_url\`

2. **Código de la función**:
   - Usa \`@google-cloud/functions-framework\`
   - Formato diferente de exports

3. **Tiempos de despliegue**:
   - Gen 2 puede tardar más en desplegarse (Cloud Build + Cloud Run)
   - Se recomienda timeout de 30 minutos para las pruebas

## Limpieza

Las pruebas limpian automáticamente todos los recursos creados mediante \`defer terraform.Destroy()\`. Si una prueba falla y no se limpian los recursos, puedes eliminarlos manualmente:

```bash
# Eliminar función
gcloud functions delete <nombre-funcion> --gen2 --region=<region>

# Eliminar bucket
gsutil rm -r gs://<nombre-bucket>

# Eliminar cuenta de servicio
gcloud iam service-accounts delete <nombre-sa>@<proyecto>.iam.gserviceaccount.com
```

## Troubleshooting

### Error: "API not enabled"

Habilita las APIs requeridas:

```bash
gcloud services enable cloudfunctions.googleapis.com cloudbuild.googleapis.com run.googleapis.com
```

### Error: "bucket does not exist"

Asegúrate de que el bucket se creó correctamente. Las pruebas crean el bucket automáticamente, pero si falla, verifica los permisos de Storage Admin.

### Error: "permission denied"

Verifica que tu cuenta tiene los permisos necesarios en el proyecto de GCP. Gen 2 requiere permisos adicionales de Cloud Run.

### Error: "Build failed"

Verifica que el \`package.json\` incluye \`@google-cloud/functions-framework\` como dependencia:

```json
{
  "dependencies": {
    "@google-cloud/functions-framework": "^3.0.0"
  }
}
```

### Timeout

Cloud Functions Gen 2 puede tardar más en desplegarse que Gen 1. Si las pruebas tardan mucho, aumenta el timeout:

```bash
go test -v -timeout 60m
```

### Error: "Function not accessible"

Gen 2 requiere permisos explícitos de Cloud Run para invocación. Las pruebas configuran \`function_invoker_members = ["allUsers"]\` automáticamente, pero si usas el módulo manualmente, asegúrate de configurar este parámetro.

## Costos

Estas pruebas crean recursos en GCP que pueden generar costos mínimos:
- Cloud Function Gen 2 (basado en Cloud Run)
- Cloud Build (para compilar la función)
- Cloud Storage bucket
- Service Account

Los recursos se eliminan automáticamente al finalizar las pruebas.

## Comparación Gen 1 vs Gen 2

| Aspecto | Gen 1 | Gen 2 |
|---------|-------|-------|
| **Base** | Infraestructura propia | Cloud Run |
| **Memoria máx** | 8GB | 32GB |
| **CPU máx** | 4 vCPU | 8 vCPU |
| **Timeout máx** | 540s (9 min) | 3600s (60 min) |
| **Concurrencia** | 1 request/instancia | Hasta 1000 requests/instancia |
| **Cold start** | ~1-2s | ~1-3s |
| **Precio** | Por invocación | Por tiempo de CPU + memoria |

## Recursos adicionales

- [Documentación oficial de Cloud Functions Gen 2](https://cloud.google.com/functions/docs/2nd-gen/overview)
- [Migración de Gen 1 a Gen 2](https://cloud.google.com/functions/docs/2nd-gen/migrate-to-2nd-gen)
- [Functions Framework](https://github.com/GoogleCloudPlatform/functions-framework-nodejs)
- [Terratest](https://terratest.gruntwork.io/)
