# Terraform GCP Function

Módulo de Terraform para desplegar Google Cloud Functions con soporte para cuentas de servicio personalizadas y roles IAM.

## Características

- ✅ Despliegue de Cloud Functions (1st gen)
- ✅ Cuenta de servicio dedicada creada automáticamente
- ✅ Asignación flexible de roles IAM
- ✅ Soporte para variables de entorno y secretos
- ✅ Triggers HTTP y eventos
- ✅ Pruebas automatizadas con Terratest

## Uso básico

```hcl
module "cloud_function" {
  source = "github.com/tu-usuario/terraform-gcp-function"

  project_id            = "mi-proyecto-gcp"
  region                = "us-central1"
  function_name         = "mi-funcion"
  function_description  = "Mi Cloud Function"
  function_entry_point  = "helloWorld"
  file_location         = "./src"
  zip_location          = "./build"
  bucket_name           = "mi-bucket-existente"
  
  # Roles IAM adicionales para la función
  function_iam_roles = [
    "roles/storage.objectViewer",
    "roles/pubsub.subscriber",
  ]
}
```

## Variables

| Variable | Descripción | Tipo | Default | Requerido |
|----------|-------------|------|---------|-----------|
| `project_id` | ID del proyecto GCP | `string` | - | ✅ |
| `region` | Región de GCP | `string` | `us-central1` | ❌ |
| `function_name` | Nombre de la función | `string` | - | ✅ |
| `function_description` | Descripción de la función | `string` | - | ✅ |
| `function_entry_point` | Punto de entrada de la función | `string` | - | ✅ |
| `function_runtime` | Runtime de la función | `string` | `nodejs20` | ❌ |
| `function_available_memory_mb` | Memoria disponible (MB) | `number` | `128` | ❌ |
| `function_timeout` | Timeout en segundos | `number` | `60` | ❌ |
| `file_location` | Ubicación del código fuente | `string` | - | ✅ |
| `zip_location` | Ubicación del archivo zip | `string` | - | ✅ |
| `bucket_name` | Nombre del bucket (debe existir) | `string` | - | ✅ |
| `function_iam_roles` | Lista de roles IAM adicionales | `list(string)` | `[]` | ❌ |
| `function_trigger_http` | Habilitar trigger HTTP | `bool` | `true` | ❌ |
| `function_event_trigger` | Configuración de event trigger | `object` | `null` | ❌ |
| `function_environment_variables` | Variables de entorno | `map(string)` | `null` | ❌ |
| `function_secret_environment_variables` | Variables de entorno secretas | `map(object)` | `null` | ❌ |

## Outputs

| Output | Descripción |
|--------|-------------|
| `function_id` | ID de la Cloud Function |
| `function_https_trigger_url` | URL del trigger HTTPS |
| `function_status` | Estado de la función |
| `service_account_email` | Email de la cuenta de servicio |

## Cuenta de servicio y permisos

El módulo crea automáticamente una cuenta de servicio con el formato \`{function_name}-sa@{project_id}.iam.gserviceaccount.com\`.

Por defecto, la cuenta de servicio tiene el rol \`roles/cloudfunctions.invoker\`. Puedes agregar roles adicionales mediante la variable \`function_iam_roles\`:

```hcl
function_iam_roles = [
  "roles/storage.objectViewer",      # Leer objetos de Cloud Storage
  "roles/pubsub.subscriber",         # Suscribirse a tópicos de Pub/Sub
  "roles/datastore.user",            # Acceder a Firestore
  "roles/secretmanager.secretAccessor", # Leer secretos
]
```

## Pruebas con Terratest

Las pruebas de integración usan [Terratest](https://terratest.gruntwork.io/) para validar el despliegue de la Cloud Function en GCP.

### Requisitos previos

- Go 1.21+
- Terraform 1.6+
- Google Cloud SDK (gcloud, gsutil)
- Credenciales de GCP configuradas

### Variables de entorno

| Variable | Descripción | Default |
|----------|-------------|---------|
| \`GCP_PROJECT_ID\` | ID del proyecto GCP | (requerido) |
| \`GCP_REGION\` | Región de GCP | us-central1 |
| \`FUNCTION_NAME\` | Nombre de la función de prueba | (generado automáticamente) |
| \`BUCKET_NAME\` | Nombre del bucket de prueba | (generado automáticamente) |

### Ejecución local

```bash
# Configurar variables de entorno
export GCP_PROJECT_ID="tu-proyecto-id"

# Autenticación
gcloud auth application-default login

# Ejecutar pruebas
cd test
go test -v -timeout 30m
```

Para más detalles sobre las pruebas, consulta [test/README.md](test/README.md).

### Flujo de las pruebas

1. **Creación del bucket**: Se crea un bucket temporal para las pruebas
2. **Despliegue**: Terraform aplica la configuración del módulo
3. **Validación**: Verifica outputs, estado de la función, cuenta de servicio e invocación HTTP
4. **Destroy**: Terraform destruye los recursos
5. **Limpieza**: Se elimina el bucket temporal

## Ejemplos

### Función con acceso a Cloud Storage

```hcl
module "storage_function" {
  source = "github.com/tu-usuario/terraform-gcp-function"

  project_id            = "mi-proyecto"
  function_name         = "procesar-archivos"
  function_description  = "Procesa archivos de Cloud Storage"
  function_entry_point  = "processFile"
  file_location         = "./src"
  zip_location          = "./build"
  bucket_name           = "mi-bucket-codigo"
  
  function_iam_roles = [
    "roles/storage.objectViewer",
    "roles/storage.objectCreator",
  ]
}
```

### Función con trigger de Pub/Sub

```hcl
module "pubsub_function" {
  source = "github.com/tu-usuario/terraform-gcp-function"

  project_id            = "mi-proyecto"
  function_name         = "procesar-mensajes"
  function_description  = "Procesa mensajes de Pub/Sub"
  function_entry_point  = "processMessage"
  file_location         = "./src"
  zip_location          = "./build"
  bucket_name           = "mi-bucket-codigo"
  
  function_trigger_http = false
  function_event_trigger = {
    event_type = "google.pubsub.topic.publish"
    resource   = "projects/mi-proyecto/topics/mi-topic"
  }
  
  function_iam_roles = [
    "roles/pubsub.subscriber",
  ]
}
```

## Licencia

MIT
