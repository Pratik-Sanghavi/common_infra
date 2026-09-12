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

Write-Host "Push with:     docker push localhost:${HostPort}/<image>:<tag>"
Write-Host "Deploy with:   kind-registry:5000/<image>:<tag>"
