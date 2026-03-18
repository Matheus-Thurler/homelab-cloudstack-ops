#!/bin/bash

set -e

echo "🔴 LIMPANDO BACKSTAGE"
echo "===================="
echo ""

# 1. Deletar namespace (junto com tudo dentro)
echo "1️⃣ Deletando namespace backstage..."
kubectl delete namespace backstage --ignore-not-found=true
echo "   ✓ Namespace deletado"
echo ""

# 2. Aguardar namespace ser removido
echo "2️⃣ Aguardando remoção (30s)..."
sleep 30
echo "   ✓ Aguardado"
echo ""

# 3. Deletar aplicação Argo CD
echo "3️⃣ Deletando aplicação Argo CD..."
kubectl delete application backstage -n argocd --ignore-not-found=true
echo "   ✓ Aplicação deletada"
echo ""

# 4. Aguardar limpeza
echo "4️⃣ Aguardando finalizações (15s)..."
sleep 15
echo "   ✓ Pronto para reinstalar"
echo ""

echo "🟢 INSTALANDO BACKSTAGE"
echo "======================="
echo ""

# 5. Aplicar nova configuração
echo "5️⃣ Aplicando nova configuração..."
kubectl apply -f bootstrap/backstage-app-clean.yaml
echo "   ✓ Configuração aplicada"
echo ""

# 6. Aguardar sincronização
echo "6️⃣ Aguardando sincronização (60s)..."
sleep 60
echo "   ✓ Sincronizado"
echo ""

# 7. Verificar status
echo "7️⃣ Status Atual:"
echo "---"
kubectl get application -n argocd backstage
echo ""

echo "8️⃣ Pods Criados:"
echo "---"
kubectl get pod -n backstage
echo ""

echo "✅ Instalação concluída!"
echo ""
echo "Próximos passos:"
echo "  1. Aguarde todos os pods ficarem Running (~2-3 minutos)"
echo "  2. Execute: kubectl get pod -n backstage -w"
echo "  3. Quando todos estiverem Ready: kubectl port-forward -n backstage svc/backstage 7007:7007"
echo "  4. Acesse: http://localhost:7007"
