{
  config,
  pkgs,
  lib,
  ...
}:

# k3s single-node. kubeconfig: /etc/rancher/k3s/k3s.yaml (mode 644). CLI tools en home/rolando.nix.

{
  services.k3s = {
    enable = true;

    role = "server";
    # 644: k3s escribe 0600 root:root por default; el user necesita leerlo sin sudo.
    extraFlags = [
      "--write-kubeconfig-mode=644"
    ];
  };

  # Arranque manual: al boot costaba 30s de CPU (el mayor de todos los servicios) y
  # después idlea a 8% de un core + 934 MiB. Prender con `sudo systemctl start k3s.service`.
  systemd.services.k3s.wantedBy = lib.mkForce [ ];

  # 6443 no expuesto. Para acceso externo: networking.firewall.allowedTCPPorts = [ 6443 ];
}
