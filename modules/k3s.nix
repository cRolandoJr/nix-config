{
  config,
  pkgs,
  lib,
  ...
}:

# Cluster Kubernetes local single-node usando k3s.
#
# k3s = distribución ligera de Kubernetes (Rancher). Un solo binario que incluye
# control plane + worker + addons (traefik, servicelb, local-path-provisioner,
# coredns, metrics-server). Ideal para aprender K8s sin la complejidad de un
# cluster multi-nodo.
#
# Acceso:
#   - API server: 127.0.0.1:6443 (NO expuesto al exterior; el firewall queda cerrado)
#   - kubeconfig: /etc/rancher/k3s/k3s.yaml (mode 644 → legible por user `rolando`)
#
# Tools CLI (kubectl, k9s, helm) se declaran en home/rolando.nix porque son
# user-level — el daemon es system-level pero las herramientas las usa el user.

{
  services.k3s = {
    enable = true;

    # single-node: server con agent embebido (corre control plane + workloads
    # en el mismo host). Si más adelante sumamos workers remotos, ahí cambia.
    role = "server";

    # Flags CLI que el módulo no expone como opciones tipadas:
    #   --write-kubeconfig-mode=644
    #     Por default k3s deja /etc/rancher/k3s/k3s.yaml con 0600 root:root.
    #     Con 644 el user `rolando` puede leerlo sin sudo y kubectl funciona
    #     out-of-the-box. Cluster local sin secrets sensibles → aceptable.
    #
    # Addons (traefik, servicelb, local-path-provisioner, coredns,
    # metrics-server) quedan TODOS activos por default. Si más adelante querés
    # reemplazar traefik por nginx-ingress, agregás "--disable=traefik" acá.
    extraFlags = [
      "--write-kubeconfig-mode=644"
    ];
  };

  # Firewall: cluster local-only. NO abrimos 6443 al exterior.
  # Si en el futuro conectamos un agent remoto o queremos acceder al API server
  # desde otra máquina, agregar acá:
  #   networking.firewall.allowedTCPPorts = [ 6443 ];
}
