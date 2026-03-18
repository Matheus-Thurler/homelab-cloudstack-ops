# 📚 Catalog Crossplane-CloudStack para Backstage

Este diretório contém as entidades do Backstage que representam os recursos gerenciados por Crossplane no CloudStack.

## 📋 Estrutura

### Entidades Definidas:

- **System:** `crossplane-cloudstack` - Sistema de infraestrutura
- **Components:**
  - `crossplane-provider` - O próprio Crossplane
  - `cloudstack-provider` - Provider CloudStack
- **Resources:**
  - `gitops-test-vpc` - VPC de teste sincronizada via GitOps
  - `cloudstack-credentials` - Secret de credenciais
- **APIs:**
  - `crossplane-infrastructure-api` - API para provisionar infraestrutura
  - `cloudstack-api` - API nativa do CloudStack

## 🔄 Como Funciona a Integração

1. **Discovery Automático:**
   - Backstage lê este arquivo via Location URL
   - Descobre todas as entidades definidas
   - Mapeia recursos Crossplane para visualização

2. **Relacionamentos:**
   - VPC depende do Provider CloudStack
   - Provider CloudStack fornece APIs
   - Tudo conecta dentro do System

3. **Visualização:**
   - Acesse Backstage em `http://backstage.matheus.me`
   - Vá para "Catalog"
   - Filtre por tipo: Systems, Components, Resources, APIs

## 🚀 Como Adicionar Novos Recursos

### Exemplo: Adicionar uma Nova VPC

```yaml
---
apiVersion: backstage.io/v1alpha1
kind: Resource
metadata:
  name: production-vpc
  namespace: default
spec:
  type: vpc
  owner: platform-team
  system: crossplane-cloudstack
  description: VPC de produção
  dependsOn:
    - resource:default/cloudstack-provider
```

Depois, crie o recurso Crossplane em `infrastructure/cloudstack/`:

```yaml
apiVersion: cloudstack.terasky.com/v1alpha1
kind: VPC
metadata:
  name: production-vpc
  namespace: crossplane-system
spec:
  forProvider:
    name: "Production-VPC"
    displayText: "VPC de Produção"
    cidr: "10.20.0.0/16"
    zone: "Homelab-Zone"
    vpcOffering: "Default VPC offering"
  providerConfigRef:
    name: default
```

## ✅ Validação

### Ver entidades no Backstage:

```bash
# 1. Acessar Backstage
kubectl port-forward -n backstage svc/backstage 7007:7007 &

# 2. Ir para http://localhost:7007/catalog

# 3. Filtrar por type=Resource para ver as VPCs
```

### Verificar no Kubernetes:

```bash
# Ver recursos Crossplane sincronizados
kubectl get vpc -n crossplane-system

# Ver status
kubectl describe vpc test-gitops-vpc -n crossplane-system
```

### Via API do Backstage:

```bash
# Listar entities
curl -X GET http://backstage.matheus.me/api/catalog/entities

# Buscar por tipo
curl -X GET 'http://backstage.matheus.me/api/catalog/entities?filter=kind=Resource'

# Buscar por system
curl -X GET 'http://backstage.matheus.me/api/catalog/entities?filter=spec.system=crossplane-cloudstack'
```

## 📝 Notas

- Este arquivo é sincronizado automaticamente pelo Backstage
- Mudanças aqui refletem imediatamente no Backstage (sem restart necessário)
- Os recursos listados aqui devem ter correspondentes em `infrastructure/cloudstack/`

## 🔗 Links de Referência

- [Backstage Catalog Models](https://backstage.io/docs/features/software-catalog/system-model/)
- [Crossplane Docs](https://docs.crossplane.io/)
- [CloudStack Provider](https://github.com/terasky-oss/provider-cloudstack)
