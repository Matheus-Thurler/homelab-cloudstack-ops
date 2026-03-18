# Bootstrap Guide (Step-by-Step) 🕹️🏗️

This guide describes how to install the orchestration base in your Kubernetes cluster. These commands have been verified and tested in your environment.

## 1. Gateway API CRDs (Kubernetes Standard)
Before installing the controller, we need the standard Gateway API resources:

```bash
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.1.0/standard-install.yaml
```

## 2. Nginx Gateway Fabric (The Controller)
Install the Nginx-specific CRDs first, then the controller via Helm:

```bash
# 2a. Nginx CRDs Installation
kubectl apply -f https://raw.githubusercontent.com/nginx/nginx-gateway-fabric/v1.4.0/deploy/crds.yaml

# 2b. Controller Installation via Helm (OCI)
helm install ngf oci://ghcr.io/nginxinc/charts/nginx-gateway-fabric \
  --namespace nginx-gateway \
  --create-namespace \
  --version 1.4.0
```

## 3. Argo CD (The GitOps Engine)
We use `server-side apply` mode to avoid issues with manifest size (annotation limit):

```bash
kubectl create namespace argocd
kubectl apply --server-side --force-conflicts -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

### Accessing Argo CD
Wait for the pods to be ready and then access:
```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```
- **User**: `admin`
- **Password**: `kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d`

## 4. Starting GitOps (Root App)
Once logged in, apply the entry point of this repository:

```bash
kubectl apply -f bootstrap/root-app.yaml
```

This will make Argo CD automatically manage:
- The Gateway (homelab-gateway)
- The Apps Manager (`apps-manager.yaml`)
- Dashy and its routes.

## 5. DNS Configuration (MikroTik)
To access `.me` domains on your internal network, add static entries to your MikroTik pointing to the Gateway IP (`10.0.50.106`):

```bash
/ip dns static add name=dashy.matheus.me address=10.0.50.106
/ip dns static add name=argo.matheus.me address=10.0.50.106
```

## 6. Accessing Argo CD without TLS (HTTP)
If you are accessing via domain without SSL certificates, Argo CD needs to be configured for insecure mode:

```bash
kubectl patch configmap argocd-cmd-params-cm -n argocd --type merge -p '{"data": {"server.insecure": "true"}}'
kubectl rollout restart deployment/argocd-server -n argocd
```

## 7. Crossplane (Infrastructure via YAML)
Crossplane allows you to create CloudStack resources using Kubernetes files:

```bash
# 7a. Apply Crossplane (via Argo CD)
kubectl apply -f bootstrap/crossplane-app.yaml

# 7b. Configure Provider and ProviderConfig (v1beta1)
kubectl apply -f infrastructure/crossplane/provider-cloudstack.yaml
kubectl apply -f infrastructure/crossplane/provider-config.yaml
```

### Secret Management (IMPORTANT)
**DO NOT push API keys to GitHub.** Use the `k8s/ccm/crossplane-creds.yaml` file (already in `.gitignore`) and apply it manually:
```bash
kubectl apply -f k8s/ccm/crossplane-creds.yaml
```

---
## 📅 Next Steps
- [x] Configure `Gateway` and `HTTPRoute`.
- [x] Install Crossplane.
- [ ] Test VPC/VM creation via GitOps.
