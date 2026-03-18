#!/bin/bash

echo "Criando secret PostgreSQL com chaves corretas..."

# Decodificar para base64
USERNAME=$(echo -n "backstage" | base64)
PASSWORD=$(echo -n "backstage123" | base64)

# Criar secret com as chaves esperadas pela Helm chart
kubectl create secret generic backstage-postgresql \
  -n backstage \
  --from-literal=username=backstage \
  --from-literal=password=backstage123 \
  --from-literal=postgres-password=backstage123 \
  --dry-run=client -o yaml | kubectl apply -f -

echo "Secret criado/atualizado!"
sleep 3

echo ""
echo "Aguardando pod..."
sleep 30

echo ""
kubectl get pod -n backstage
