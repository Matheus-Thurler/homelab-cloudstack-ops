# Solução Final: Argo CD + Crossplane Portal

## ❌ Removido:
- Weave GitOps (problemas de repositório OCI)
- Backstage
- Keycloak (incompatibilidade de CPU)

## ✅ Solução: Argo CD + Dashboard Customizado

### Opção 1: Use Argo CD UI nativa
**Já está funcionando!**
- Acesse: `https://argo.matheus.me`
- Crie Applications para Crossplane resources
- Sincronize automaticamente

**Fluxo:**
```
Usuário criar VPC:
1. Escrever YAML em infrastructure/cloudstack/vpc-xxx.yaml
2. Commit no GitHub
3. Argo CD detecta e sincroniza
4. Crossplane provisiona no CloudStack
```

### Opção 2: Portal Web Simples (Recomendado)
Criar um dashboard customizado Node.js/React:

```bash
# Exemplo de aplicação web minimalista
kubectl create namespace portal
kubectl run -n portal web --image=node:18-alpine -- sleep 1000000

# Montar Crossplane resources como formulários
# Escrever YAML e fazer commit no GitHub
```

**Recursos necessários:**
- Node.js ou Python SimpleHTTP
- Conectar ao GitHub para fazer commits
- Listar recursos Crossplane via `kubectl get`
- HTTPRoute para expor via `portal.matheus.me`

---

## 🎯 Próximos Passos

### 1. CloudStack CSI StorageClass Fix (IMPORTANTE)
```bash
kubectl apply -f infrastructure/cloudstack/storageclass-cloudstack.yaml
```

### 2. Testar PVC
```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-pvc
spec:
  accessModes: [ "ReadWriteOnce" ]
  storageClassName: cloudstack-custom
  resources:
    requests:
      storage: 10Gi
EOF

kubectl get pvc test-pvc -w
```

### 3. Criar Crossplane Resources via Argo CD
```bash
cat > infrastructure/cloudstack/my-vpc.yaml <<EOF
apiVersion: cloudstack.terasky.com/v1alpha1
kind: VPC
metadata:
  name: my-vpc
spec:
  forProvider:
    name: "My VPC"
    displayText: "VPC criada via Argo CD"
    cidr: "10.20.0.0/16"
    zone: "Homelab-Zone"
    vpcOffering: "Default VPC offering"
  providerConfigRef:
    name: default
EOF

git add infrastructure/cloudstack/my-vpc.yaml
git commit -m "Add my-vpc"
git push origin master

# Argo CD sincroniza automaticamente
```

---

## 📊 Arquitetura Final

```
┌──────────────────────────────────────────┐
│    GitHub Repository                     │
├──────────────────────────────────────────┤
│ - bootstrap/                             │
│ - apps/                                  │
│ - infrastructure/cloudstack/             │
│   └─ Crossplane Resources (VPC, etc)     │
└──────────────────────────────────────────┘
           ↓
      (webhook auto)
           ↓
┌──────────────────────────────────────────┐
│    Argo CD (argo.matheus.me)             │
│    - Monitor Sync Status                 │
│    - Manual Sync if needed               │
│    - Trigger deployments                 │
└──────────────────────────────────────────┘
           ↓
┌──────────────────────────────────────────┐
│  Crossplane                              │
│  - Monitor resources                     │
│  - Provision VPCs, Volumes               │
│  - CloudStack Integration                │
└──────────────────────────────────────────┘
           ↓
┌──────────────────────────────────────────┐
│  CloudStack                              │
│  - Actual Infrastructure                 │
│  - VPCs, Volumes, etc                    │
└──────────────────────────────────────────┘
```

---

## 💡 Por que esta solução?

✅ **Simples**: Tudo via Git + Argo CD  
✅ **GitOps**: Infrastructure as Code  
✅ **Confiável**: Sem dependent complexos  
✅ **Escalável**: Adicione mais resources conforme necessário  
✅ **Monitorável**: Argo CD UI mostra tudo  

---

## 🔧 Se quiser um Portal Web depois

Posso criar um painel customizado:
- **Framework**: Node.js + Express + React
- **Funcionalidades**:
  - Listar Crossplane resources
  - Formulário para criar VPC/Volume
  - Fazer commit no GitHub automaticamente
  - Monitorar status via Argo CD API

Quer que eu crie isso? 🚀
