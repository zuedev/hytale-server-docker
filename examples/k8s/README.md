A Kubernetes example configuration for deploying the Hytale server.

## Files

- `namespace.yaml` - Creates a dedicated namespace for the Hytale server
- `deployment.yaml` - Deploys the Hytale server container
- `service.yaml` - Exposes the server via a NodePort service (UDP)
- `pvc.yaml` - Persistent Volume Claim for server data

## Quick Start

1. Apply all manifests:

```bash
kubectl apply -f examples/k8s/
```

2. Or apply individually in order:

```bash
kubectl apply -f examples/k8s/namespace.yaml
kubectl apply -f examples/k8s/pvc.yaml
kubectl apply -f examples/k8s/deployment.yaml
kubectl apply -f examples/k8s/service.yaml
```

## Accessing the Server

By default, the server is exposed via NodePort on port `30520`. Connect to your Hytale server using:

```
<node-ip>:30520
```

## Customization

- Modify the `pvc.yaml` to adjust storage size or use a different StorageClass
- Update the `service.yaml` to use LoadBalancer type if your cluster supports it
- Adjust resource limits in `deployment.yaml` based on your server requirements
