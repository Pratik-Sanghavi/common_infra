# Local Kind registry

Run `./local-registry/setup.ps1` to start the official Docker Registry on `localhost:5000` and attach it to the Kind network. The script also configures each local cluster node to pull `kind-registry:5000` over HTTP; this is required when Docker Desktop's global registry mirror is enabled.

Push images from Windows as `localhost:5000/<image>:<tag>`. Workload manifests running in the cluster must reference `kind-registry:5000/<image>:<tag>`, which resolves to the same registry from Kind nodes.
