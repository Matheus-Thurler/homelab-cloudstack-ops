# 📋 Guia de Validação: Backstage + Crossplane + CloudStack

## 🎯 Objetivo
Validar que o Backstage está corretamente integrado com Crossplane para gerenciar recursos CloudStack via GitOps.

---

## 1️⃣ Validar Stack do Crossplane

### ✅ **Passo 1.1: Verificar Namespace e CRDs**
```bash
# Verificar se o namespace crossplane-system foi criado
kubectl get namespace crossplane-system
kubectl get crds | grep crossplane
```

**Esperado:** Namespace `crossplane-system` deve existir.

### ✅ **Passo 1.2: Verificar Instalação do Crossplane**
```bash
# Verificar deployment do Crossplane
kubectl get deployment -n crossplane-system
kubectl get pod -n crossplane-system

# Logs do Crossplane
kubectl logs -n crossplane-system -l app=crossplane -f
```

**Esperado:** Pods do Crossplane em estado `Running`.

### ✅ **Passo 1.3: Verificar Provider CloudStack**
```bash
# Listar providers instalados
kubectl get providers
kubectl get providers provider-cloudstack

# Ver status do provider
kubectl describe provider provider-cloudstack

# Logs do provider
kubectl logs -n crossplane-system -l pkg.crossplane.io/provider=provider-cloudstack -f
```

**Esperado:** Provider em status `Healthy` e pods do provider rodando.

---

## 2️⃣ Validar Credenciais CloudStack

### ✅ **Passo 2.1: Verificar Secret das Credenciais**
```bash
# Verificar se o secret existe
kubectl get secret -n crossplane-system | grep cloudstack

# Ver conteúdo (base64 encoded)
kubectl get secret cloudstack-creds -n crossplane-system -o yaml

# Decodificar e validar
kubectl get secret cloudstack-creds -n crossplane-system -o jsonpath='{.data.credentials}' | base64 -d
```

**Esperado:** Secret `cloudstack-creds` deve existir com credenciais válidas.

### ✅ **Passo 2.2: Verificar ProviderConfig**
```bash
# Listar ProviderConfigs
kubectl get providerconfig
kubectl describe providerconfig default

# Verificar se referencia o secret corretamente
kubectl get providerconfig default -o yaml
```

**Esperado:** ProviderConfig `default` referenciando `cloudstack-creds` em `crossplane-system`.

---

## 3️⃣ Validar Recursos Crossplane

### ✅ **Passo 3.1: Verificar VPC de Teste**
```bash
# Listar VPCs gerenciadas pelo Crossplane
kubectl get vpc -n crossplane-system
kubectl describe vpc test-gitops-vpc -n crossplane-system

# Ver status de sincronização
kubectl get vpc test-gitops-vpc -n crossplane-system -o yaml | grep -A 10 "status:"

# Logs da criação
kubectl logs -n crossplane-system -l pkg.crossplane.io/provider=provider-cloudstack -f
```

**Esperado:** VPC em estado `Synced: True` ou `Ready: True`.

### ✅ **Passo 3.2: Validar Sincronização com Argo CD**
```bash
# Verificar aplicação de infra
kubectl get application -n argocd infrastructure
argocd app describe infrastructure

# Sync status
argocd app sync infrastructure
argocd app wait infrastructure

# Ver recursos aplicados
kubectl get all -n crossplane-system
```

**Esperado:** Aplicação `infrastructure` em estado `Synced`.

---

## 4️⃣ Validar Backstage + Crossplane

### ✅ **Passo 4.1: Verificar Implantação do Backstage**
```bash
# Verificar namespace e pods
kubectl get namespace backstage
kubectl get pod -n backstage
kubectl get svc -n backstage

# Logs do Backstage
kubectl logs -n backstage -l app.kubernetes.io/name=backstage -f

# Status do PostgreSQL
kubectl get pod -n backstage -l app.kubernetes.io/name=postgresql
```

**Esperado:** Todos os pods em estado `Running`.

### ✅ **Passo 4.2: Acessar Interface do Backstage**
```bash
# Port-forward para acessar
kubectl port-forward -n backstage svc/backstage 7007:7007 &

# Ou verificar a rota (se configurada)
kubectl get ingress -n backstage
kubectl get route -n backstage
```

**Esperado:** Backstage acessível em `http://localhost:7007`

### ✅ **Passo 4.3: Validar Catalog Integration**
```bash
# Verificar se o Backstage consegue ler o catalog
# Acessar via UI ou API:

curl -X GET http://backstage.matheus.me/api/catalog/entities

# Verificar entidades de exemplo do GitHub
curl -X GET http://ghcr.io/backstage/backstage/blob/master/packages/catalog-model/examples/all-components.yaml
```

**Esperado:** Entities sendo listadas no catalog do Backstage.

---

## 5️⃣ Validar Integração Backstage + Crossplane Resources

### ✅ **Passo 5.1: Verificar Tipo de Recurso no Backstage**
```bash
# Adicionar Resource de exemplo apontando para VPC Crossplane
# Acessar http://backstage.matheus.me/catalog?filters[kind]=Resource

# Se não aparecer, verificar logs do backend
kubectl logs -n backstage -l app.kubernetes.io/name=backstage -f | grep -i "catalog\|resource"
```

### ✅ **Passo 5.2: Criar Entidade de Recurso Crossplane**
```bash
# Exemplo de Resource entity que representa uma VPC do Crossplane

cat <<'EOF' | kubectl apply -f -
---
apiVersion: backstage.io/v1alpha1
kind: Resource
metadata:
  name: gitops-test-vpc
  namespace: crossplane-system
spec:
  owner: platform-team
  type: vpc
  system: cloudstack-infrastructure
  dependsOn:
    - resource:default/crossplane-provider-cloudstack
---
apiVersion: backstage.io/v1alpha1
kind: Component
metadata:
  name: crossplane-provider-cloudstack
  namespace: crossplane-system
spec:
  type: service
  owner: platform-team
  lifecycle: production
  providesApis: []
  consumesApis: []
EOF
```

---

## 6️⃣ Troubleshooting Comum

### 🔴 Provider CloudStack não ativa
```bash
# Verificar status detalhado
kubectl describe provider provider-cloudstack

# Ver eventos
kubectl get events -n crossplane-system | grep provider-cloudstack

# Verificar se a imagem está accessible
kubectl get pod -n crossplane-system -l pkg.crossplane.io/provider=provider-cloudstack -o yaml
```

### 🔴 VPC não sincroniza
```bash
# Ver status completo
kubectl get vpc test-gitops-vpc -n crossplane-system -o yaml

# Verificar condições
kubectl get vpc test-gitops-vpc -n crossplane-system -o json | jq '.status.conditions'

# Logs do provider
kubectl logs -n crossplane-system -l pkg.crossplane.io/provider=provider-cloudstack -f
```

### 🔴 Backstage não vê catalog
```bash
# Verificar arquivo de configuração
kubectl get configmap -n backstage

# Validar URL do catalog
kubectl exec -it -n backstage deployment/backstage -- curl -X GET http://localhost:7007/api/catalog/entities

# Ver logs de erro
kubectl logs -n backstage deployment/backstage | grep -i error
```

---

## 7️⃣ Configurar URL do Backstage no MikroTik

### ✅ **Passo 7.1: Via Winbox (GUI)**
```
1. Abrir Winbox e conectar ao MikroTik
2. Ir para IP > DNS
3. Clicar em "+"
4. Configurar:
   - Name: backstage.matheus.me
   - Address: <IP_DO_CLUSTER_K8S>
   (ou usar a URL do Ingress se configurado)
5. Clicar OK
```

### ✅ **Passo 7.2: Via CLI (SSH/Terminal)**

**Adicionar entrada DNS estática:**
```bash
ssh admin@<IP_MIKROTIK>

# Adicionar domínio DNS estático apontando para o Backstage
/ip dns static add name=backstage.matheus.me address=<IP_DO_INGRESS>

# Verificar se foi criado
/ip dns static print

# Testar resolução
/tool dns query name=backstage.matheus.me
```

**Exemplo pronto para usar:**
```bash
# Adicionar Backstage
/ip dns static add name=backstage.matheus.me address=10.0.50.106

# Adicionar Argo CD também (referência)
/ip dns static add name=argo.matheus.me address=10.0.50.106

# Listar todas entradas DNS
/ip dns static print

# Deletar se necessário
/ip dns static remove [find name=backstage.matheus.me]
```

### ✅ **Passo 7.3: Via Firewall Rule (NAT Forward)**

Se o Backstage está em uma subnet privada do cluster:

```bash
# Adicionar NAT forward
/ip firewall nat add chain=dstnat dst-address=<IP_PUBLICO> dst-port=80 \
  protocol=tcp to-addresses=<IP_BACKSTAGE_INTERNO> to-ports=7007 comment="Backstage HTTP"

/ip firewall nat add chain=dstnat dst-address=<IP_PUBLICO> dst-port=443 \
  protocol=tcp to-addresses=<IP_BACKSTAGE_INTERNO> to-ports=7007 comment="Backstage HTTPS"

# Adicionar filter rule (permitir tráfego)
/ip firewall filter add chain=forward in-interface=ether1 \
  dst-address=<IP_BACKSTAGE_INTERNO> dst-port=7007 protocol=tcp \
  action=accept comment="Allow Backstage"

# Listar regras
/ip firewall nat print
/ip firewall filter print
```

### ✅ **Passo 7.4: Verificar Comunicação**

```bash
# Do MikroTik:
ssh admin@<IP_MIKROTIK>
ping backstage.matheus.me

# Verificar rota
traceroute backstage.matheus.me

# Testar conectividade na porta
/tool dns query name=backstage.matheus.me
```

### ✅ **Passo 7.5: Configurar DDNS (Opcional - para DNS Dinâmico)**

Se o IP publico muda:

```bash
/ip cloud ddns update

# Configurar DDNS address para atualizar automaticamente
/ip cloud set update-time=no ddns-enabled=yes
```

---

## 8️⃣ Checklist Final

- [ ] Namespace `crossplane-system` existe
- [ ] Crossplane deployment rodando
- [ ] Provider CloudStack em status `Healthy`
- [ ] Secret `cloudstack-creds` existe em `crossplane-system`
- [ ] ProviderConfig `default` configurado
- [ ] VPC `test-gitops-vpc` sincronizada
- [ ] Aplicação Argo CD `infrastructure` sincronizada
- [ ] Namespace `backstage` existe
- [ ] Backstage pods rodando
- [ ] PostgreSQL conectado
- [ ] Catalog do Backstage acessível
- [ ] Resource types aparecem no Backstage
- [ ] URL Backstage configurada no MikroTik
- [ ] DNS resolvendo para o Backstage
- [ ] Firewall permitindo tráfego até Backstage

---

## 📚 Referências
- [Crossplane Docs](https://docs.crossplane.io)
- [Backstage Catalog Model](https://backstage.io/docs/features/software-catalog/)
- [Provider CloudStack](https://github.com/terasky-oss/provider-cloudstack)
