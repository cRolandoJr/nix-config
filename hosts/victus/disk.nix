# Layout de disco declarativo (disko): btrfs sobre LUKS, 5 subvolúmenes.
#
# Lo único a cambiar en otra máquina es `device`. Los `label` están fijados a
# "ESP" y "primary" a propósito: son las etiquetas que ya tiene este disco, así
# que la config resuelve acá sin repartir, y en una instalación nueva disko las
# crea con esos mismos nombres. Sin el label explícito, disko generaría
# "gpt-main-ESP" y los paths no existirían en este disco.
#
# CUIDADO: correr disko FORMATEA. Para instalar en una máquina nueva:
#   sudo nix run github:nix-community/disko/latest -- \
#     --mode destroy,format,mount hosts/victus/disk.nix
#
# Los subvolúmenes anidados de churn pesado (steamapps, .cache) NO van acá:
# viven dentro de @home y se crean después de que exista el home del usuario.
# Ver docs/2026-07-14-steam-subvolumen-migracion.md.
{
  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/nvme0n1";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          label = "ESP";
          size = "1G";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [
              "fmask=0022"
              "dmask=0022"
            ];
          };
        };

        primary = {
          label = "primary";
          size = "100%";
          content = {
            type = "luks";
            name = "cryptroot";
            # tpm2-device=auto: el initrd intenta liberar la clave sellada al TPM
            # y cae al prompt de passphrase si falla (firmware update, PCR 7, etc.).
            settings.crypttabExtraOpts = [ "tpm2-device=auto" ];
            content = {
              type = "btrfs";
              subvolumes =
                let
                  opts = [
                    "noatime"
                    "compress=zstd:3"
                    "ssd"
                    "space_cache=v2"
                    "discard=async"
                  ];
                in
                {
                  "@" = {
                    mountpoint = "/";
                    mountOptions = opts;
                  };
                  "@home" = {
                    mountpoint = "/home";
                    mountOptions = opts;
                  };
                  "@nix" = {
                    mountpoint = "/nix";
                    mountOptions = opts;
                  };
                  "@log" = {
                    mountpoint = "/var/log";
                    mountOptions = opts;
                  };
                  "@snapshots" = {
                    mountpoint = "/.snapshots";
                    mountOptions = opts;
                  };
                };
            };
          };
        };
      };
    };
  };
}
