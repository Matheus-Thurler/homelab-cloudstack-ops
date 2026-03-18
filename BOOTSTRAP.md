# Guia de Bootstrap (Passo a Passo) 🕹️🏗️

Este guia descreve como instalar a base de orquestração no seu cluster Kubernetes. Os comandos foram verificados e testados no seu ambiente.

## 1. Gateway API CRDs (Padrão Kubernetes)
Antes de instalar o controller, precisamos dos recursos padrão da Gateway API:

```bash
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.1.0/standard-install.yaml
```

## 2. Nginx Gateway Fabric (O Controller)
Instale os CRDs específicos do Nginx e depois o controller via Helm:

```bash
# 2a. Instalação dos CRDs do Nginx
kubectl apply -f https://raw.githubusercontent.com/nginx/nginx-gateway-fabric/v1.4.0/deploy/crds.yaml

# 2b. Instalação do Controller via Helm (OCI)
helm install ngf oci://ghcr.io/nginxinc/charts/nginx-gateway-fabric \
  --namespace nginx-gateway \
  --create-namespace \
  --version 1.4.0
```

## 3. Argo CD (O Motor de GitOps)
Utilizamos o modo `server-side apply` para evitar problemas com o tamanho dos manifestos:

```bash
kubectl create namespace argocd
kubectl apply --server-side --force-conflicts -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

### Acessando o Argo CD
Aguarde os pods ficarem prontos e faça o acesso:
```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```
- **User**: `admin`
- **Senha**: `kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d`

## 4. Iniciando o GitOps (Root App)
Uma vez logado, aplique o ponto de entrada deste repositório:

```bash
kubectl apply -f bootstrap/root-app.yaml
```

Isso fará com que o Argo CD gerencie automaticamente:
- O Gateway (homelab-gateway)
- O Gerenciador de Apps (`apps-manager.yaml`)
- O Dashy e suas rotas.

## 5. Configuração de DNS (MikroTik)
Para acessar os domínios `.me` na sua rede interna, adicione entradas estáticas no seu MikroTik apontando para o IP do Gateway (`10.0.50.106`):

```bash
/ip dns static add name=dashy.matheus.me address=10.0.50.106
/ip dns static add name=argo.matheus.me address=10.0.50.106
```

## 6. Acesso ao Argo CD sem TLS (HTTP)
Se você estiver acessando via domínio sem certificados SSL, o Argo CD precisa ser configurado para modo inseguro:

```bash
kubectl patch configmap argocd-cmd-params-cm -n argocd --type merge -p '{"data": {"server.insecure": "true"}}'
kubectl rollout restart deployment/argocd-server -n argocd
```

---
## 📅 Próximos Passos
- [x] Configurar o primeiro `Gateway` e `HTTPRoute`.
- [x] Migrar o `dashy` para ser gerenciado pelo Argo CD.
- [ ] Instalar o Crossplane para gerenciar VMs do CloudStack.
