[CmdletBinding()]
param(
  [string]$SourceNamespace = 'database',
  [string]$SourceSecret = 'keycloak-db-credentials',
  [string]$DestinationNamespace = 'keycloak',
  [string]$DestinationSecret = 'keycloak-db-credentials'
)

$ErrorActionPreference = 'Stop'

$source = kubectl get secret $SourceSecret --namespace $SourceNamespace --output json | ConvertFrom-Json
if (-not $source.data.username -or -not $source.data.password) {
  throw "Secret '$SourceNamespace/$SourceSecret' must contain 'username' and 'password' keys."
}

kubectl create namespace $DestinationNamespace --dry-run=client --output yaml | kubectl apply --filename - | Out-Null

$replica = [ordered]@{
  apiVersion = 'v1'
  kind = 'Secret'
  metadata = [ordered]@{
    name = $DestinationSecret
    namespace = $DestinationNamespace
    labels = [ordered]@{
      'app.kubernetes.io/name' = 'keycloak'
      'app.kubernetes.io/managed-by' = 'manual-secret-sync'
    }
  }
  type = $source.type
  data = [ordered]@{
    username = $source.data.username
    password = $source.data.password
  }
}

$replica | ConvertTo-Json -Depth 10 | kubectl apply --filename - | Out-Null
kubectl get secret $DestinationSecret --namespace $DestinationNamespace --output 'custom-columns=NAME:.metadata.name,TYPE:.type' --no-headers