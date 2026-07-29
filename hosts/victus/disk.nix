# CUIDADO: correr disko FORMATEA el disco. Instalación: ver el README.
{
  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/nvme0n1";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          # label explícito: sin él disko genera "gpt-main-ESP" y el path
          # by-partlabel no existe en este disco → no bootea.
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
