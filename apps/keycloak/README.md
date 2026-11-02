# Keycloak

Keycloak is deployed from the Codecentric `keycloakx` Helm chart by `argocd/applications/keycloak.yaml` and runs in the `keycloak` namespace. The chart uses the official `quay.io/keycloak/keycloak:26.8.1` image and connects to the CloudNativePG cluster declared in `apps/postgres`.
## One-time database credentials

Create the source credential in the `database` namespace before syncing the Keycloak application. The secret is intentionally not committed to Git.

```powershell
$password = [Net.NetworkCredential]::new('', (Read-Host 'Keycloak database password' -AsSecureString)).Password
kubectl create secret generic keycloak-db-credentials -n database `
  --from-literal=username=keycloak `
  --from-literal=password="$password" `
  --dry-run=client -o yaml | kubectl apply -f -
Remove-Variable password
```

CloudNativePG uses this secret to manage the `keycloak` login role. Copy the same credentials into Keycloak's namespace for the Helm release:

```powershell
.\scripts\Copy-KeycloakDatabaseSecret.ps1
```

## One-time Keycloak administrator credential

Create this Secret before the Keycloak Helm application syncs. Keeping it outside the chart prevents a generated password from drifting during Argo CD reconciliation.

```powershell
$adminPassword = [Net.NetworkCredential]::new('', (Read-Host 'Keycloak admin password' -AsSecureString)).Password
kubectl create namespace keycloak --dry-run=client -o yaml | kubectl apply -f -
kubectl create secret generic keycloak-admin-credentials -n keycloak `
  --from-literal=admin-password="$adminPassword" `
  --dry-run=client -o yaml | kubectl apply -f -
Remove-Variable adminPassword
```

## Access

With Docker Desktop's local LoadBalancer support, open `http://localhost:8082/admin` and sign in as `admin` with the password you created above.