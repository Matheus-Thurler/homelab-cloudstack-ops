#!/bin/bash

echo "=========================================="
echo "🔍 VALIDAÇÃO DO BACKSTAGE"
echo "=========================================="
echo ""

echo "📋 1️⃣ Status dos Pods"
echo "---"
kubectl get pod -n backstage
echo ""

echo "📋 2️⃣ Detalhes do Deployment"
echo "---"
kubectl describe deployment backstage -n backstage | grep -E "Replicas:|Ready:|Available:|Selector:|Image:|Ports:"
echo ""

echo "📋 3️⃣ Service & Endpoints"
echo "---"
kubectl get svc -n backstage
kubectl get endpoints -n backstage
echo ""

echo "📋 4️⃣ Logs do Backstage"
echo "---"
kubectl logs -n backstage -l app.kubernetes.io/name=backstage --tail=30 2>/dev/null || echo "Logs não disponíveis (pod ainda não rodando)"
echo ""

echo "📋 5️⃣ Verificar Secret PostgreSQL"
echo "---"
kubectl get secret backstage-postgresql -n backstage -o jsonpath='{.data}' | tr ',' '\n' || echo "Secret não encontrado"
echo ""

echo "📋 6️⃣ Status do PostgreSQL"
echo "---"
kubectl get pod -n backstage -l app.kubernetes.io/name=postgresql
kubectl describe statefulset backstage-postgresql -n backstage 2>/dev/null | grep -E "Replicas:|Ready:|Selector:" || echo "StatefulSet não encontrado"
echo ""

echo "📋 7️⃣ ConfigMap da Aplicação"
echo "---"
kubectl get configmap -n backstage
echo ""

echo "📋 8️⃣ Teste via Port-Forward"
echo "---"
echo "Para testar via port-forward execute:"
echo "  kubectl port-forward -n backstage svc/backstage 7007:7007"
echo "Depois acesse: http://localhost:7007"
echo ""

echo "✅ Validação concluída!"
