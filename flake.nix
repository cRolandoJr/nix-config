# ╔════════════════════════════════════════════════════════════════╗
# ║   N  I  X  O  S  ·  victus                                     ║
# ║   cRolandoJr · github.com/cRolandoJr                           ║
# ╚════════════════════════════════════════════════════════════════╝
{
  description = "rolando NixOS config - victus";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Bot de Telegram (Pedco). follows nixpkgs evita duplicar nixpkgs en el lock.
    pedco-bot = {
      url = "github:cRolandoJr/scraper-pedco";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprcapture = {
      url = "github:gfhdhytghd/HyprCapture/7ebc3f36f782d7b62ad7f20906f7c921aa27231f";
      flake = false;
    };

    hymission = {
      url = "github:gfhdhytghd/hymission/4fe476c29203b25b891e22198a330d8acab76d8f";
      flake = false;
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
      personal = import ./personal.nix;
      inherit (personal) username hostname;

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
      nixosConfigurations.${hostname} = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs username hostname; };
        modules = [
          ./hosts/${hostname}
          inputs.disko.nixosModules.disko
          ./hosts/${hostname}/disk.nix
          # Se lee DESDE la generación booteada: `nixos-version --configuration-revision`.
          { system.configurationRevision = self.rev or self.dirtyRev or "dirty"; }
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "backup";
            home-manager.extraSpecialArgs = {
              inherit inputs username;
              ryogamiPackage = self.packages.${system}.ryogami;
            };
            home-manager.users.${username} = import ./home/user.nix;
          }
        ];
      };

      devShells.${system}.default = pkgs.mkShell {
        inherit (pre-commit-check) shellHook;
        buildInputs = pre-commit-check.enabledPackages;
      };

      # Mismo paquete que el hook de pre-commit, para que no formateen distinto.
      formatter.${system} = pkgs.nixfmt;

      # La misma derivación se instala con Home Manager y se valida en CI.
      packages.${system}.ryogami = pkgs.callPackage ./pkgs/ryogami { };

      checks.${system} = {
        inherit pre-commit-check;
        ryogami = self.packages.${system}.ryogami;
      };
    };
}
