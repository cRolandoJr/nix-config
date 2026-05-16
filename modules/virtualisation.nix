{ config, pkgs, lib, ... }:

{
  # libvirt + QEMU/KVM
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = true;
      swtpm.enable = true;        # TPM emulado para VMs (Windows 11)
    };
  };

  # Frontend gráfico
  programs.virt-manager.enable = true;

  # USB passthrough a VMs
  virtualisation.spiceUSBRedirection.enable = true;

  # Paquetes útiles
  environment.systemPackages = with pkgs; [
    virt-viewer
    spice
    spice-gtk
    spice-protocol
    virtio-win          # drivers virtio para Windows guests
    win-spice
  ];
}
