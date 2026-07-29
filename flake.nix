# ╔════════════════════════════════════════════════════════════════╗
# ║   N  I  X  O  S  ·  victus                                     ║
# ║   cRolandoJr · github.com/cRolandoJr                           ║
# ╚════════════════════════════════════════════════════════════════╝
{
  description = "rolando NixOS config - victus";

  inputs = {
    # PIN 27-jul-2026: unstable del 25-jul subió libdisplay-info a 0.4.0 y lact 0.9.1 exige
    # < 0.4.0, así que no compila. Este rev del 23-jul ya trae Hyprland 0.56 sin esa rotura.
    # Volver a "nixos-unstable" cuando lact buildee de nuevo.
    nixpkgs.url = "github:NixOS/nixpkgs/e220185ff6e66544862579018f33012372bb708f";

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Particionado declarativo. El layout vive en hosts/victus/disk.nix.
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Bot de Telegram (Pedco). follows nixpkgs evita duplicar nixpkgs en el lock.
    pedco-bot = {
      url = "github:cRolandoJr/scraper-pedco";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      pre-commit-hooks,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      # Hooks instalados en .git/hooks al entrar al devShell (direnv `use flake`).
      pre-commit-check = pre-commit-hooks.lib.${system}.run {
        src = ./.;
        hooks = {
          nixfmt.enable = true; # formateador RFC 166
          statix.enable = true; # lint anti-patrones (.statix.toml)
          deadnix = {
            enable = true;
            settings.noLambdaPatternNames = true;
          };
        };
      };
    in
    {
      nixosConfigurations.victus = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/victus
          inputs.disko.nixosModules.disko
          ./hosts/victus/disk.nix
          # Ata cada generación a su commit. Se lee DESDE la generación booteada con
          # `nixos-version --configuration-revision`, que es cuando hace falta:
          # booteaste algo viejo del menú y querés saber qué config es.
          { system.configurationRevision = self.rev or self.dirtyRev or "dirty"; }
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "backup";
            home-manager.extraSpecialArgs = { inherit inputs; };
            home-manager.users.rolando = import ./home/rolando.nix;
          }
        ];
      };

      devShells.${system}.default = pkgs.mkShell {
        inherit (pre-commit-check) shellHook;
        buildInputs = pre-commit-check.enabledPackages;
      };

      # `nix fmt`. Mismo paquete que usa el hook nixfmt de pre-commit, así que los
      # dos caminos formatean idéntico y no pueden pelearse.
      formatter.${system} = pkgs.nixfmt;

      checks.${system} = { inherit pre-commit-check; };
    };
}
