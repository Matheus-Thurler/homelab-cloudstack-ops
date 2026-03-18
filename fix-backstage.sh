#!/bin/bash

set -e

echo "🔧 CORRIGINDO BACKSTAGE"
echo "======================="
echo ""

# 1. Deletar secret e deixar o Helm recriar
echo "1️⃣ Deletando secret para recriação..."
kubectl delete secret backstage-postgresql -n backstage --ignore-not-found=true
sleep 2

# 2. Deletar deployment para forçar recriação
echo "2️⃣ Deletando deployment do Backstage..."
kubectl delete deployment backstage -n backstage --grace-period=5 --ignore-not-found=true
sleep 5

# 3. Aguardar recriação pelo Argo CD
echo "3️⃣ Aguardando recriação dos recursos (60s)..."
sleep 60

# 4. Verificar status
echo ""
echo "4️⃣ Status Atual:"
echo "---"
kubectl get pod -n backstage
echo ""

echo "5️⃣ Verificar secret"
echo "---"
kubectl get secret -n backstage | grep postgresql || echo "Secret ainda não criado"
echo ""

echo "6️⃣ Logs do Backstage (últimas 20 linhas)"
echo "---"
kubectl logs -n backstage -l app.kubernetes.io/name=backstage --tail=20 2>/dev/null || echo "Logs não disponíveis ainda"
echo ""

echo "✅ Correção concluída!"
echo ""
echo "Próximo passo: aguarde ~2 minutos e execute:"
echo "  kubectl get pod -n backstage -w"
