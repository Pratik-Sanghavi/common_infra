param(
  [int]$HostPort = 5000
)

$registryName = "kind-registry"

if (-not (docker ps -a --format '{{.Names}}' | Select-String -SimpleMatch $registryName)) {
  docker run -d --restart=always -p "127.0.0.1:${HostPort}:5000" --network kind --name $registryName registry:2
} else {
  docker start $registryName | Out-Null
  docker network connect kind $registryName 2>$null
}

kubectl apply -f (Join-Path $PSScriptRoot 'local-registry-hosting.yaml')
# Docker Desktop's Kind-based cluster uses a global registry mirror. Configure a
# host-specific endpoint so pulls for the local HTTP registry bypass that mirror.
$registryHosts = @(
  'server = "http://kind-registry:5000"',
  '',
  '[host."http://kind-registry:5000"]',
  'capabilities = ["pull", "resolve"]',
  'skip_verify = true'
) -join "`n"
$encodedRegistryHosts = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($registryHosts))
$nodeNames = kubectl get nodes -o name | ForEach-Object { $_ -replace '^node/', '' }

foreach ($nodeName in $nodeNames) {
  if (docker inspect $nodeName 2>$null) {
    docker exec $nodeName sh -c "mkdir -p '/etc/containerd/certs.d/kind-registry:5000' && echo $encodedRegistryHosts | base64 -d > '/etc/containerd/certs.d/kind-registry:5000/hosts.toml'"
  }
}

Write-Host "Push with:     docker push localhost:${HostPort}/<image>:<tag>"
Write-Host "Deploy with:   kind-registry:5000/<image>:<tag>"
