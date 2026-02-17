package test

import (
	"fmt"
	"net/http"
	"os"
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/http-helper"
	"github.com/gruntwork-io/terratest/modules/retry"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestTerraformGcpFunction(t *testing.T) {
	projectID := requireEnv(t, "GCP_PROJECT_ID")
	region := getEnvOrDefault("GCP_REGION", "us-central1")
	bucketName := getEnvOrDefault("BUCKET_NAME", fmt.Sprintf("terratest-bucket-%d", time.Now().Unix()))
	functionName := getEnvOrDefault("FUNCTION_NAME", fmt.Sprintf("terratest-func-%d", time.Now().Unix()))

	// Crear bucket antes de aplicar el módulo (el módulo ya no crea el bucket)
	createBucket(t, projectID, bucketName, region)
	defer deleteBucket(t, projectID, bucketName)

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "..",
		Vars: map[string]interface{}{
			"project_id":             projectID,
			"region":                 region,
			"file_location":          "./test/fixtures/src",
			"zip_location":           "./test",
			"bucket_name":            bucketName,
			"function_name":          functionName,
			"function_description":   "Test function for Terratest",
			"function_entry_point":   "helloWorld",
			"function_iam_roles":     []string{}, // Lista vacía para pruebas básicas
		},
		BackendConfig: map[string]interface{}{
			"path": "test/.terraform/terraform.tfstate",
		},
	})

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	// 1. Validar outputs
	functionID := terraform.Output(t, terraformOptions, "function_id")
	assert.NotEmpty(t, functionID, "function_id no debe estar vacío")

	functionState := terraform.Output(t, terraformOptions, "function_state")
	assert.Equal(t, "ACTIVE", functionState, "La función debe estar ACTIVE")

	functionURL := terraform.Output(t, terraformOptions, "function_url")
	require.NotEmpty(t, functionURL, "La URL de la función no debe estar vacía")

	// 2. Validar funcionalidad HTTP
	validateHTTPResponse(t, functionURL)

	// 3. Validar configuración de la función (via outputs o estado)
	assert.Contains(t, functionID, functionName, "function_id debe contener el nombre de la función")

	// 4. Validar que la cuenta de servicio fue creada
	serviceAccountEmail := terraform.Output(t, terraformOptions, "service_account_email")
	expectedServiceAccountEmail := fmt.Sprintf("%s-sa@%s.iam.gserviceaccount.com", functionName, projectID)
	assert.Equal(t, expectedServiceAccountEmail, serviceAccountEmail, "La cuenta de servicio debe tener el formato esperado")
}

func TestTerraformGcpFunctionWithIAMRoles(t *testing.T) {
	projectID := requireEnv(t, "GCP_PROJECT_ID")
	region := getEnvOrDefault("GCP_REGION", "us-central1")
	bucketName := getEnvOrDefault("BUCKET_NAME", fmt.Sprintf("terratest-bucket-%d", time.Now().Unix()))
	functionName := getEnvOrDefault("FUNCTION_NAME", fmt.Sprintf("terratest-func-%d", time.Now().Unix()))

	// Crear bucket antes de aplicar el módulo
	createBucket(t, projectID, bucketName, region)
	defer deleteBucket(t, projectID, bucketName)

	// Roles adicionales para probar
	iamRoles := []string{
		"roles/storage.objectViewer",
		"roles/pubsub.subscriber",
	}

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "..",
		Vars: map[string]interface{}{
			"project_id":             projectID,
			"region":                 region,
			"file_location":          "./test/fixtures/src",
			"zip_location":           "./test",
			"bucket_name":            bucketName,
			"function_name":          functionName,
			"function_description":   "Test function with IAM roles",
			"function_entry_point":   "helloWorld",
			"function_iam_roles":     iamRoles,
		},
		BackendConfig: map[string]interface{}{
			"path": "test/.terraform/terraform.tfstate",
		},
	})

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	// Validar que la función fue creada
	functionID := terraform.Output(t, terraformOptions, "function_id")
	assert.NotEmpty(t, functionID, "function_id no debe estar vacío")

	// Validar que la cuenta de servicio fue creada
	serviceAccountEmail := terraform.Output(t, terraformOptions, "service_account_email")
	assert.NotEmpty(t, serviceAccountEmail, "service_account_email no debe estar vacío")

	t.Logf("Función creada con roles IAM: %v", iamRoles)
	t.Logf("Service Account: %s", serviceAccountEmail)
}

func validateHTTPResponse(t *testing.T, url string) {
	t.Helper()

	maxRetries := 10
	timeBetweenRetries := 10 * time.Second

	_, err := retry.DoWithRetryE(t, "Invoking Cloud Function", maxRetries, timeBetweenRetries, func() (string, error) {
		statusCode, body := http_helper.HTTPDo(t, "GET", url, nil, nil, nil)
		if statusCode != http.StatusOK {
			return "", fmt.Errorf("código de respuesta inesperado: %d, body: %s", statusCode, string(body))
		}
		if len(body) == 0 {
			return "", fmt.Errorf("respuesta vacía")
		}
		return string(body), nil
	})
	require.NoError(t, err)
}

func requireEnv(t *testing.T, name string) string {
	t.Helper()
	value := getEnvOrDefault(name, "")
	if value == "" {
		t.Fatalf("variable de entorno %s es requerida", name)
	}
	return value
}

func getEnvOrDefault(name, defaultValue string) string {
	if v := getEnv(name); v != "" {
		return v
	}
	return defaultValue
}

func getEnv(name string) string {
	return os.Getenv(name)
}

func createBucket(t *testing.T, projectID, bucketName, region string) {
	t.Helper()
	t.Logf("Creando bucket: %s", bucketName)

	terraformOptions := &terraform.Options{
		TerraformDir: "./fixtures/bucket",
		Vars: map[string]interface{}{
			"project_id":   projectID,
			"bucket_name":  bucketName,
			"region":       region,
		},
	}

	terraform.InitAndApply(t, terraformOptions)
}

func deleteBucket(t *testing.T, projectID, bucketName string) {
	t.Helper()
	t.Logf("Eliminando bucket: %s", bucketName)

	terraformOptions := &terraform.Options{
		TerraformDir: "./fixtures/bucket",
		Vars: map[string]interface{}{
			"project_id":  projectID,
			"bucket_name": bucketName,
		},
	}

	terraform.Destroy(t, terraformOptions)
}
