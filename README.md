# nix-config

NixOS flake configuration for my HP Victus laptop.

## Hosts

- **victus**: HP Victus 16, AMD Ryzen 7 6800H + Radeon RX 6500M, KDE Plasma 6 on Wayland.

## Structure

- `flake.nix` — flake inputs and outputs
- `hosts/victus/` — per-host config (hardware, system options)
- `modules/` — reusable modules (boot, network, audio, desktop, gpu, gaming, virt)
- `home/` — home-manager config per user

## Apply

```bash
sudo nixos-rebuild switch --flake .#victus
```
