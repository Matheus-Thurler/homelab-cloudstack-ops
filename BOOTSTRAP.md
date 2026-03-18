# Guia de Bootstrap (Passo a Passo) 🕹️🏗️

Este guia descreve como instalar a base de orquestração no seu cluster Kubernetes recém-criado.

## 1. Gateway API CRDs (Padrão Kubernetes - via Helm)
Antes de instalar o Nginx, precisamos dos recursos padrão da Gateway API instalados no cluster:

```bash
helm install gateway-api-artifacts oci://ghcr.io/kubernetes-sigs/gateway-api/charts/gateway-api-artifacts \
  --version v1.1.0 \
  --namespace gateway-api \
  --create-namespace
```

## 2. Nginx Gateway Fabric (O Controller)
Instale o controller usando Helm para gerenciar o tráfego de entrada:

```bash
helm repo add nginx-gateway https://nginx.github.io/nginx-gateway-fabric
helm repo update

helm install ngf nginx-gateway/nginx-gateway-fabric \
  --namespace nginx-gateway \
  --create-namespace
```

## 3. Argo CD (O Motor de GitOps)
Agora instalamos quem vai vigiar este repositório:

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

### Acessando o Argo CD
Para acessar a interface visual do Argo, faça um port-forward:
```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```
- **User**: `admin`
- **Senha**: `kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d`

## 4. Conectando este Repositório ao Argo
Após logar, adicione este repositório como uma "App-of-Apps" para que ele comece a gerenciar a pasta `apps/` e `infrastructure/`.

---

## 📅 Próximos Passos
- [ ] Configurar o primeiro `Gateway` e `HTTPRoute`.
- [ ] Migrar o `dashy` para ser gerenciado pelo Argo CD.
- [ ] Instalar o Crossplane para gerenciar VMs do CloudStack.
