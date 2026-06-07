{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Raíz btrfs (subvolid=5) montada en /btrfs para dar a btrbk la vista plana
  # donde todos los subvolúmenes son hermanos. No interfiere con los mounts normales.
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

  # Snapshots de @home cada hora; retención 24h / 7d / 4w / 6m.
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
