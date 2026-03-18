# Deployment: Keycloak + Port.io

## Overview

Este deployment remove o Backstage e instala:

- **Keycloak**: Identity Provider (IDP) com OpenID Connect
- **Port.io**: Internal Developer Portal para gerenciar recursos Crossplane

## Arquitetura

```
┌─────────────────────────────────────────┐
│      API Gateway (Gateway API)          │
│  (gateway-api/api-gateway)              │
└──────┬────────────────────────┬─────────┘
       │                        │
   HTTPRoute              HTTPRoute
keycloak.matheus.me    port.matheus.me
   ┌────────────┐      ┌─────────────┐
   │  Keycloak  │      │  Port.io    │
   ├────────────┤      ├─────────────┤
   │ PostgreSQL │      │ PostgreSQL  │
   │ PVC        │      │ PVC         │
   └────────────┘      └─────────────┘
       (KeyCloak)        (Port.io)
```

## Deploy Status

### Verificar se Argo CD detecta os novos apps:

```bash
kubectl get applications -n argocd | grep -E "keycloak|port-io"
```

Você deve ver:
```
keycloak       Synced    Healthy
port-io        Synced    Healthy
```

### Se não aparecerem, sincronizar manualmente:

```bash
# Keycloak
kubectl create -f bootstrap/keycloak-app.yaml

# Port.io
kubectl create -f bootstrap/port-io-app.yaml
```

## Esperado durante Deploy

### 1. Criação de Namespaces
```bash
kubectl get ns | grep -E "keycloak|port-io"
# keycloak  Active
# port-io   Active
```

### 2. PostgreSQL StatefulSets iniciando
```bash
# Keycloak PostgreSQL
kubectl get statefulset -n keycloak
kubectl get pvc -n keycloak

# Port.io PostgreSQL
kubectl get statefulset -n port-io
kubectl get pvc -n port-io
```

⏳ **Aguarde 2-3 minutos** para Crossplane provisionar os volumes CloudStack.

### 3. Aplicações Coming Up
```bash
kubectl get pods -n keycloak
kubectl get pods -n port-io

# Monitorar logs
kubectl logs -n keycloak deployment/keycloak -f
kubectl logs -n port-io deployment/port-io -f
```

## Configuração Keycloak

Quando Keycloak estiver Ready:

1. Acesse: **https://keycloak.matheus.me**
2. Login: `admin` / `admin123`
3. Crie Realm `port-io` (ou use `master`)
4. Crie Client OIDC:
   - **Client ID**: `port-io`
   - **Client Secret**: `port-io-secret-12345`
   - **Valid Redirect URIs**: 
     - https://port.matheus.me/auth/callback
     - http://localhost:3000/auth/callback
   - **Valid Post Logout Redirect URIs**:
     - https://port.matheus.me

## Configuração Port.io

Port.io está configurado para usar Keycloak como IDP.

**Credenciais padrão** (existem? verificar documentação oficial Port.io):
- Geralmente é `admin` / contraseña do primeiro setup

### Primeiros passos em Port.io:

1. Acesse: **https://port.matheus.me**
2. Login com credenciais Keycloak
3. Crie primeiro Blueprint (exemplo: "Criar VPC")
   - Campos: `vpcName`, `cidr`, `zone`, `displayText`
   - Action: Commit YAML → Argo CD sincroniza

## Exemplo: Blueprint para VPC

No Port.io, criar blueprint:

```yaml
identifier: create-vpc
title: Create VPC
icon: layer
description: Provision new VPC via Crossplane

schema:
  properties:
    vpcName:
      type: string
      title: VPC Name
    cidr:
      type: string
      title: CIDR Block
      pattern: ^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/\d{1,2}$
    zone:
      type: string
      title: CloudStack Zone
      enum: [Homelab-Zone]

uiSchema:
  - vpcName
  - cidr
  - zone

actions:
  - id: create-vpc
    title: Create VPC
    trigger: webhook
    webhook:
      method: POST
      url: https://webhook.example.com/vpc
```

## DNS Setup (Mikrotik)

```bash
# Se não tiver feito, adicione:
/ip dns static add name=keycloak.matheus.me address=10.0.50.106
/ip dns static add name=port.matheus.me address=10.0.50.106
/ip dns static add name=api.port.matheus.me address=10.0.50.106
```

## Troubleshooting

### Pods não startam
```bash
kubectl describe pod <pod-name> -n <namespace>
kubectl logs <pod-name> -n <namespace>
```

### PVCs Pending
```bash
kubectl get pvc -n keycloak -o wide
kubectl get pvc -n port-io -o wide

# Verificar Crossplane
kubectl get volumeclaim -A
kubectl describe volumeclaim <name> -n <ns>
```

### HTTPRoute não roteando
```bash
kubectl get httproute -A
kubectl describe httproute <name> -n <namespace>

# Testar com port-forward
kubectl port-forward svc/keycloak 8080:80 -n keycloak
# Acesse: http://localhost:8080
```

### Keycloak login não funciona
- Verificar `/health/ready` endpoint
- Verificar variáveis `KC_HOSTNAME`, `KC_PROXY`
- Logs: `kubectl logs deployment/keycloak -n keycloak`

### Port.io conexão com Keycloak
- Verificar secret `port-io-secret` tem OIDC client secret
- Logs: `kubectl logs deployment/port-io -n port-io`
- Verificar conectividade: `kubectl exec -it <pod> -n port-io -- curl https://keycloak:80/health`

## Rollback (se necessário)

```bash
# Remover aplicações Argo CD
kubectl delete application keycloak port-io -n argocd

# Remover namespaces (deleta tudo)
kubectl delete ns keycloak port-io

# Fazer reset em git se quiser
git revert HEAD
```

## Próximos Passos

1. ✅ Argo CD detecta novos apps (automático em ~1 minuto)
2. ⏳ Aguardar PostgreSQL + volumes Crossplane (~2-3 min)
3. 🔧 Configurar Keycloak IDP e Client Port.io
4. 📋 Configurar Blueprints em Port.io para criar recursos
5. 🚀 Start usando Port.io para provisionar infraestrutura!

## Monitoramento Contínuo

```bash
# Watch all resources in both namespaces
kubectl get all -n keycloak -w
kubectl get all -n port-io -w

# See Argo CD sync status
argocd app get keycloak
argocd app get port-io
```

---

**Última atualização**: 2026-03-18
**Criado por**: GitHub Copilot
