# homelab-ops ☸️🚀🎨

Este repositório é o cérebro de orquestração do seu Homelab. Ele utiliza **GitOps** para gerenciar aplicações, infraestrutura e o Portal de Desenvolvedor (IDP).

## 🏗️ Estrutura do Repositório

- `bootstrap/`: Manifestos críticos para subir o cluster do zero (Argo CD, Gateway API, Crossplane).
- `apps/`: Definições das aplicações (Dashy, Grafana, etc) organizadas por namespace.
- `infrastructure/`: Recursos de nuvem gerenciados pelo Kubernetes (VMs, Discos via Crossplane).
- `charts/`: Helm Charts customizados ou locais (Ex: `dashy`).

---

## 🛠️ Tecnologias Principais

- **Argo CD**: Motor de GitOps para sincronização contínua.
- **Nginx Gateway Fabric**: Implementação da [Kubernetes Gateway API](https://gateway-api.sigs.k8s.io/) para roteamento moderno.
- **Crossplane**: Gerenciamento de recursos CloudStack via YAML.
- **Kustomize**: Para gerenciar variações de ambiente sem duplicar código.

---

## 🚀 Como Começar (Bootstrap)

Se você acabou de criar o cluster usando o [homelab-cloudstack](../homelab-cloudstack), siga o guia de inicialização:

👉 **[Guia de Bootstrap (Argo + Gateway API)](./BOOTSTRAP.md)**

---
> [!TIP]
> Nunca use `kubectl apply` manualmente para aplicações. Faça o commit aqui e deixe o Argo CD trabalhar por você!