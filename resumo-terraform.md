# Documentação de Rede VPC e Acesso SSH

Este documento detalha a arquitetura de rede implementada via Terraform neste repositório, focando na estrutura de VPC, alocação de IPs e o método de acesso às instâncias.

## 1. Arquitetura da Rede VPC

A infraestrutura utiliza o modelo de **VPC (Virtual Private Cloud)** do CloudStack para garantir isolamento e controle granular de tráfego.

### Componentes Principais:
- **VPC**: Um domínio de rede isolado (padrão: `10.50.0.0/16`).
- **Network Tier (Subnet)**: Uma sub-rede dentro da VPC onde as instâncias residem (padrão: `10.50.1.0/24`).
- **ACL (Access Control List)**: Funciona como um firewall na borda da sub-rede, controlando o tráfego de entrada e saída.

## 2. Alocação de IPs

### IP Privado
Cada instância criada dentro de um Tier recebe automaticamente um IP privado dentro do CIDR daquele Tier (ex: `10.50.1.x`). Este IP é usado para comunicação interna entre os nós do cluster.

### IP Público
A VPC aloca um **IP Público único** (Source NAT IP). Este IP é compartilhado por todas as instâncias da VPC para acesso à internet (egress) e para receber conexões externas (ingress) via regras de redirecionamento.

## 3. Acesso SSH via Port Forwarding

Como as instâncias não possuem IPs públicos diretos, o acesso SSH é feito através de **Port Forwarding** (NAT Estático).

### Como funciona:
Para cada nó do cluster, o Terraform mapeia uma porta pública única no IP da VPC para a porta 22 (privada) da VM.

- **Exemplo de mapeamento:**
  - `master-0`: IP_PUBLICO:22000 -> 10.50.1.10:22
  - `worker-0`: IP_PUBLICO:22001 -> 10.50.1.11:22
  - `worker-1`: IP_PUBLICO:22002 -> 10.50.1.12:22

### Configuração no Terraform (`variables.tf`):
O mapeamento é controlado pela variável `ssh_base_port` definida no mapa de `nodes`:
```hcl
nodes = {
  master = {
    role          = "control"
    count         = 1
    ssh_base_port = 22000 # Porta inicial
    ...
  }
}
```

## 4. Requisitos para Criar uma Instância

Para provisionar uma nova instância nesta arquitetura, os seguintes requisitos devem ser atendidos:

1.  **Chave SSH (Keypair)**: Deve existir uma chave SSH registrada no CloudStack para permitir o login, já que senhas são desabilitadas por padrão.
2.  **Network ID**: A instância deve estar associada ao ID do Network Tier criado dentro da VPC.
3.  **Service Offering**: Definição de recursos (CPU/RAM).
4.  **Template**: Uma imagem de SO compatível (ex: Ubuntu 22.04).
5.  **Regras de ACL**: A ACL associada ao Tier deve permitir tráfego na porta 22 (TCP).

## 5. Segurança e Firewal (ACL)

As regras de ACL configuradas no módulo `vpc-network` garantem que:
- **Portas 22000-23999**: Abertas para permitir o Port Forwarding do SSH externo.
- **Porta 6443**: Aberta para acesso à API do Kubernetes (via Load Balancer).
- **Tráfego Interno**: Liberado para comunicação entre os nós dentro da VPC.

---

### Como conectar:
Após o `terraform apply`, você pode obter o IP público e conectar usando a porta mapeada:
```bash
ssh -i ~/.ssh/sua_chave -p 22000 root@IP_PUBLICO_VPC
```
