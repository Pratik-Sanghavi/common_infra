# Argo CD

Install Argo CD into the local Kubernetes cluster:

```powershell
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
helm upgrade --install argocd argo/argo-cd --namespace argocd --create-namespace
```

Apply the application that tracks `local-k8-cluster-1`:

```powershell
kubectl apply -f .\argocd\local-k8-cluster-1.yaml
```

The `Application` assumes deployable Kubernetes manifests, a Kustomize project, or a Helm chart live at the root of `https://github.com/prsanghavi/local-k8-cluster-1.git`. Update `spec.source.path` if they live under a subdirectory.

Open the Argo CD user interface:

```powershell
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Then visit `https://localhost:8080`. The initial password can be read with:

```powershell
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | ForEach-Object { [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($_)) }
```
