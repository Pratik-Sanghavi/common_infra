ARG ARGOCD_VERSION=v3.5.2
ARG SOPS_VERSION=v3.10.2
ARG KUSTOMIZE_VERSION=v5.7.1

FROM ghcr.io/getsops/sops:${SOPS_VERSION} AS sops
FROM registry.k8s.io/kustomize/kustomize:${KUSTOMIZE_VERSION} AS kustomize

FROM quay.io/argoproj/argocd:${ARGOCD_VERSION}

USER root

COPY --from=sops /usr/local/bin/sops /usr/local/bin/sops
COPY --from=kustomize /app/kustomize /usr/local/bin/kustomize

USER 999
