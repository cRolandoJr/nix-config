{
  config,
  pkgs,
  lib,
  ...
}:

{
  virtualisation.libvirtd = {
    enable = true;
    # Default "start": libvirt-guests revivía la VM suspendida a los 13s del boot
    # (leer ~1,5 GB de imagen de RAM vía LUKS). Las VMs son lab, se levantan a mano.
    onBoot = "ignore";
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = true;
      swtpm.enable = true; # TPM emulado (requerido por Windows 11)
    };
  };

  programs.virt-manager.enable = true;
  virtualisation.spiceUSBRedirection.enable = true;

  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    defaultNetwork.settings.dns_enabled = true;
  };

  environment.systemPackages = with pkgs; [
    virt-viewer
    spice
    spice-gtk
    spice-protocol
    virtio-win # drivers virtio para Windows guests
    win-spice
  ];
}
