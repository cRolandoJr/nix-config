{
  config,
  pkgs,
  lib,
  ...
}:

# k3s single-node: control plane + worker en un binario.
# API server en 127.0.0.1:6443 (no expuesto). kubeconfig en /etc/rancher/k3s/k3s.yaml (mode 644).
# Tools CLI (kubectl, k9s, helm) declarados en home/rolando.nix.

{
  services.k3s = {
    enable = true;

    role = "server";
    # --write-kubeconfig-mode=644: k3s por default escribe 0600 root:root;
    # con 644 el user puede leerlo sin sudo. Cluster local → aceptable.
    extraFlags = [
      "--write-kubeconfig-mode=644"
    ];
  };

  # 6443 no expuesto. Para acceso externo: networking.firewall.allowedTCPPorts = [ 6443 ];
}
