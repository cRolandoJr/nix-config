{
  config,
  lib,
  pkgs,
  ...
}:

{
  # /btrfs: raíz btrfs (subvolid=5) montada plana para que btrbk vea todos los subvols como hermanos.
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

  systemd.tmpfiles.rules = [
    "d /btrfs/@snapshots/home 0755 root root -"
  ];

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
