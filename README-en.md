# homelab-ops ☸️🚀🎨

This repository is the orchestration brain of your Homelab. It uses **GitOps** to manage applications, infrastructure, and the Internal Developer Platform (IDP).

## 🏗️ Repository Structure

- `bootstrap/`: Critical manifests to bring up the cluster from scratch (Argo CD, Gateway API, Crossplane).
- `apps/`: Application definitions (Dashy, Grafana, etc.) organized by namespace.
- `infrastructure/`: Cloud resources managed by Kubernetes (VMs, Disks via Crossplane).
- `charts/`: Custom or local Helm Charts (e.g., `dashy`).

---

## 🛠️ Main Technologies

- **Argo CD**: GitOps engine for continuous synchronization.
- **Nginx Gateway Fabric**: Implementation of the [Kubernetes Gateway API](https://gateway-api.sigs.k8s.io/) for modern routing.
- **Crossplane**: CloudStack resource management via YAML.
- **Kustomize**: To manage environment variations without duplicating code.

---

## 🚀 How to Start (Bootstrap)

If you have just created the cluster using [homelab-cloudstack](../homelab-cloudstack), follow the initialization guide:

👉 **[Bootstrap Guide (Argo + Gateway API)](./BOOTSTRAP.md)**

---
> [!TIP]
> Never use `kubectl apply` manually for applications. Commit here and let Argo CD work for you!
