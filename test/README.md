# Pruebas del módulo Terraform GCP Function

Este directorio contiene pruebas automatizadas para el módulo de Terraform que crea Cloud Functions en GCP.

## Requisitos previos

1. **Go**: Versión 1.21 o superior
2. **Terraform**: Versión 1.0 o superior
3. **Credenciales de GCP**: Configuradas mediante `gcloud auth application-default login`
4. **Permisos en GCP**:
   - Cloud Functions Admin
   - Storage Admin
   - Service Account Admin
   - IAM Admin

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

### `TestTerraformGcpFunction`

Prueba básica que valida:
- Creación de la Cloud Function
- Estado ACTIVE de la función
- URL del trigger HTTPS
- Respuesta HTTP correcta
- Creación de la cuenta de servicio

### `TestTerraformGcpFunctionWithIAMRoles`

Prueba avanzada que valida:
- Creación de la función con roles IAM adicionales
- Asignación correcta de roles a la cuenta de servicio
- Roles probados: `roles/storage.objectViewer`, `roles/pubsub.subscriber`

## Fixtures

### `fixtures/src/`

Contiene el código fuente de ejemplo de la Cloud Function (Node.js) usado en las pruebas.

### `fixtures/bucket/`

Módulo auxiliar de Terraform para crear el bucket de almacenamiento necesario para las pruebas. El módulo principal ya no crea el bucket, por lo que las pruebas lo crean de forma independiente.

## Limpieza

Las pruebas limpian automáticamente todos los recursos creados mediante `defer terraform.Destroy()`. Si una prueba falla y no se limpian los recursos, puedes eliminarlos manualmente:

```bash
# Eliminar función
gcloud functions delete <nombre-funcion> --region=<region>

# Eliminar bucket
gsutil rm -r gs://<nombre-bucket>

# Eliminar cuenta de servicio
gcloud iam service-accounts delete <nombre-sa>@<proyecto>.iam.gserviceaccount.com
```

## Troubleshooting

### Error: "bucket does not exist"

Asegúrate de que el bucket se creó correctamente. Las pruebas crean el bucket automáticamente, pero si falla, verifica los permisos de Storage Admin.

### Error: "permission denied"

Verifica que tu cuenta tiene los permisos necesarios en el proyecto de GCP.

### Timeout

Si las pruebas tardan mucho, aumenta el timeout:

```bash
go test -v -timeout 60m
```

## Costos

Estas pruebas crean recursos en GCP que pueden generar costos mínimos:
- Cloud Function (1st gen)
- Cloud Storage bucket
- Service Account

Los recursos se eliminan automáticamente al finalizar las pruebas.
