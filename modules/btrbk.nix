{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Mount adicional de la RAÍZ del btrfs (subvolid=5) en /btrfs.
  # Esto le da a btrbk la "vista plana" del filesystem donde todos los
  # subvolúmenes (@ , @home, @nix, @snapshots, …) son hermanos con sus
  # nombres reales. No interfiere con los mounts existentes — es solo otra
  # vista del mismo disco /dev/mapper/cryptroot.
  fileSystems."/btrfs" = {
    device = "/dev/mapper/cryptroot";
    fsType = "btrfs";
    options = [
      "subvolid=5"
      "noatime"
      "compress=zstd:3"
      "ssd"
      "space_cache=v2"
      "discard=async"
    ];
  };

  # Directorio donde btrbk dejará los snapshots de @home dentro de @snapshots.
  systemd.tmpfiles.rules = [
    "d /btrfs/@snapshots/home 0755 root root -"
  ];

  # btrbk: snapshots automáticos de @home cada hora.
  # Retención escalonada 24h / 7d / 4w / 6m.
  # Solo snapshotea cuando hubo cambios (snapshot_create=onchange).
  services.btrbk = {
    instances.home = {
      onCalendar = "hourly";
      settings = {
        timestamp_format = "long";
        snapshot_preserve_min = "latest";
        snapshot_preserve = "24h 7d 4w 6m";

        volume."/btrfs" = {
          snapshot_dir = "@snapshots/home";
          subvolume."@home" = {
            snapshot_create = "onchange";
          };
        };
      };
    };
  };
}
