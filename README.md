# Terraform GCP Cloud Functions Gen 2

Módulo de Terraform para desplegar Google Cloud Functions 2nd generation con soporte para cuentas de servicio personalizadas y roles IAM.

## Características

- ✅ Cloud Functions 2nd Generation (basado en Cloud Run)
- ✅ Cuenta de servicio dedicada creada automáticamente
- ✅ Asignación flexible de roles IAM
- ✅ Soporte para variables de entorno y secretos
- ✅ Secret volumes desde Secret Manager
- ✅ Triggers HTTP y eventos (Pub/Sub, Storage, etc.)
- ✅ Configuración avanzada de escalado y concurrencia
- ✅ Pruebas automatizadas con Terratest

## Diferencias con Gen 1

Cloud Functions Gen 2 ofrece mejoras significativas:

- **Basado en Cloud Run**: Mayor rendimiento y escalabilidad
- **Más memoria y CPU**: Hasta 32GB de memoria y 8 vCPUs
- **Mayor timeout**: Hasta 60 minutos (vs 9 minutos en Gen 1)
- **Concurrencia**: Múltiples requests por instancia
- **Traffic splitting**: Control de versiones y despliegues graduales
- **Mejor integración**: Con Eventarc para eventos

## Uso básico

```hcl
module "cloud_function" {
  source = "github.com/tu-usuario/terraform-gcp-function"

  project_id            = "mi-proyecto-gcp"
  region                = "us-central1"
  function_name         = "mi-funcion"
  function_description  = "Mi Cloud Function Gen 2"
  function_entry_point  = "helloWorld"
  file_location         = "./src"
  zip_location          = "./build"
  bucket_name           = "mi-bucket-existente"
  
  # Configuración de recursos
  function_available_memory = "512M"
  function_available_cpu    = "1"
  function_timeout          = 60
  
  # Escalado
  function_min_instance_count = 0
  function_max_instance_count = 10
  
  # Roles IAM adicionales para la función
  function_iam_roles = [
    "roles/storage.objectViewer",
    "roles/pubsub.subscriber",
  ]
  
  # Permitir invocación pública (opcional)
  function_invoker_members = ["allUsers"]
}
```

## Variables

### Requeridas

| Variable | Descripción | Tipo |
|----------|-------------|------|
| `project_id` | ID del proyecto GCP | `string` |
| `function_name` | Nombre de la función | `string` |
| `function_entry_point` | Punto de entrada de la función | `string` |
| `file_location` | Ubicación del código fuente | `string` |
| `zip_location` | Ubicación del archivo zip | `string` |
| `bucket_name` | Nombre del bucket (debe existir) | `string` |

### Opcionales - Configuración básica

| Variable | Descripción | Default |
|----------|-------------|---------|
| `region` | Región de GCP | `us-central1` |
| `function_description` | Descripción de la función | `""` |
| `function_runtime` | Runtime (nodejs20, python311, go121, etc.) | `nodejs20` |

### Opcionales - Recursos y escalado

| Variable | Descripción | Default |
|----------|-------------|---------|
| `function_available_memory` | Memoria disponible (256M, 512M, 1Gi, 2Gi, 4Gi, 8Gi, 16Gi, 32Gi) | `256M` |
| `function_available_cpu` | CPUs ('1', '2', '4', '8') | `1` |
| `function_timeout` | Timeout en segundos (máx 3600) | `60` |
| `function_min_instance_count` | Instancias mínimas | `0` |
| `function_max_instance_count` | Instancias máximas | `100` |
| `function_max_instance_request_concurrency` | Requests concurrentes por instancia | `1` |

### Opcionales - Networking

| Variable | Descripción | Default |
|----------|-------------|---------|
| `function_ingress_settings` | Ingress (ALLOW_ALL, ALLOW_INTERNAL_ONLY, ALLOW_INTERNAL_AND_GCLB) | `ALLOW_ALL` |
| `function_all_traffic_on_latest_revision` | Todo el tráfico a la última revisión | `true` |

### Opcionales - Variables de entorno

| Variable | Descripción | Default |
|----------|-------------|---------|
| `function_environment_variables` | Variables de entorno runtime | `null` |
| `function_build_environment_variables` | Variables de entorno build | `null` |
| `function_secret_environment_variables` | Secretos como variables de entorno | `null` |
| `function_secret_volumes` | Secretos montados como volúmenes | `null` |

### Opcionales - Event Trigger

| Variable | Descripción | Default |
|----------|-------------|---------|
| `function_event_trigger` | Configuración de event trigger | `null` |
| `function_event_trigger_region` | Región del event trigger | `null` |

### Opcionales - IAM

| Variable | Descripción | Default |
|----------|-------------|---------|
| `function_iam_roles` | Roles IAM para la service account | `[]` |
| `function_invoker_members` | Quién puede invocar la función | `null` |

### Opcionales - Labels

| Variable | Descripción | Default |
|----------|-------------|---------|
| `function_labels` | Labels para la función | `{}` |

## Outputs

| Output | Descripción |
|--------|-------------|
| `function_id` | ID de la Cloud Function |
| `function_name` | Nombre de la función |
| `function_url` | URL de la función |
| `function_state` | Estado de la función |
| `service_account_email` | Email de la cuenta de servicio |
| `function_environment` | Entorno de la función (GEN_2) |

## Cuenta de servicio y permisos

El módulo crea automáticamente una cuenta de servicio con el formato \`{function_name}-sa@{project_id}.iam.gserviceaccount.com\`.

Puedes agregar roles mediante la variable \`function_iam_roles\`:

```hcl
function_iam_roles = [
  "roles/storage.objectViewer",      # Leer objetos de Cloud Storage
  "roles/pubsub.subscriber",         # Suscribirse a tópicos de Pub/Sub
  "roles/datastore.user",            # Acceder a Firestore
  "roles/secretmanager.secretAccessor", # Leer secretos
  "roles/cloudsql.client",           # Conectar a Cloud SQL
]
```

## Invocación de la función

Por defecto, la función requiere autenticación. Para permitir invocación pública:

```hcl
function_invoker_members = ["allUsers"]
```

Para permitir solo a usuarios específicos:

```hcl
function_invoker_members = [
  "user:usuario@example.com",
  "serviceAccount:mi-sa@proyecto.iam.gserviceaccount.com"
]
```

## Ejemplos

### Función HTTP básica

```hcl
module "http_function" {
  source = "github.com/tu-usuario/terraform-gcp-function"

  project_id            = "mi-proyecto"
  function_name         = "api-endpoint"
  function_description  = "API endpoint HTTP"
  function_entry_point  = "handleRequest"
  file_location         = "./src"
  zip_location          = "./build"
  bucket_name           = "mi-bucket-codigo"
  
  function_available_memory = "512M"
  function_timeout          = 30
  
  function_invoker_members = ["allUsers"]
}
```

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
  
  function_available_memory = "1Gi"
  function_available_cpu    = "2"
  
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
  
  function_event_trigger = {
    event_type   = "google.cloud.pubsub.topic.v1.messagePublished"
    pubsub_topic = "projects/mi-proyecto/topics/mi-topic"
    retry_policy = "RETRY_POLICY_RETRY"
  }
  
  function_iam_roles = [
    "roles/pubsub.subscriber",
  ]
}
```

### Función con secretos

```hcl
module "secure_function" {
  source = "github.com/tu-usuario/terraform-gcp-function"

  project_id            = "mi-proyecto"
  function_name         = "funcion-segura"
  function_description  = "Función con secretos"
  function_entry_point  = "handler"
  file_location         = "./src"
  zip_location          = "./build"
  bucket_name           = "mi-bucket-codigo"
  
  # Secretos como variables de entorno
  function_secret_environment_variables = {
    API_KEY = {
      secret  = "mi-api-key"
      version = "latest"
    }
    DB_PASSWORD = {
      secret  = "db-password"
      version = "1"
    }
  }
  
  # Secretos como archivos montados
  function_secret_volumes = {
    credentials = {
      mount_path = "/secrets"
      secret     = "service-account-key"
      versions = [{
        version = "latest"
        path    = "key.json"
      }]
    }
  }
  
  function_iam_roles = [
    "roles/secretmanager.secretAccessor",
  ]
}
```

### Función con alta concurrencia

```hcl
module "concurrent_function" {
  source = "github.com/tu-usuario/terraform-gcp-function"

  project_id            = "mi-proyecto"
  function_name         = "api-alta-carga"
  function_description  = "API con alta concurrencia"
  function_entry_point  = "handleRequest"
  file_location         = "./src"
  zip_location          = "./build"
  bucket_name           = "mi-bucket-codigo"
  
  function_available_memory                = "2Gi"
  function_available_cpu                   = "4"
  function_min_instance_count              = 5
  function_max_instance_count              = 100
  function_max_instance_request_concurrency = 80
  
  function_invoker_members = ["allUsers"]
}
```

## Pruebas con Terratest

Las pruebas de integración usan [Terratest](https://terratest.gruntwork.io/) para validar el despliegue de la Cloud Function en GCP.

### Requisitos previos

- Go 1.21+
- Terraform 1.3+
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

## Migración desde Gen 1

Si estás migrando desde Cloud Functions Gen 1:

1. **Actualiza el runtime**: Gen 2 usa runtimes más recientes
2. **Cambia el formato de memoria**: De `128` (MB) a `"256M"` (string)
3. **Revisa el entry point**: Gen 2 usa Functions Framework
4. **Actualiza event triggers**: Formato diferente para eventos
5. **Revisa IAM**: Gen 2 usa Cloud Run IAM para invocación

### Ejemplo de código Gen 1 vs Gen 2

**Gen 1:**
```javascript
exports.helloWorld = (req, res) => {
  res.send('Hello World!');
};
```

**Gen 2:**
```javascript
const functions = require('@google-cloud/functions-framework');

functions.http('helloWorld', (req, res) => {
  res.send('Hello World!');
});
```

## Requisitos

- Terraform >= 1.3
- Google Provider >= 5.0
- APIs habilitadas en GCP:
  - Cloud Functions API
  - Cloud Build API
  - Cloud Run API
  - Artifact Registry API (recomendado)

## Licencia

MIT
