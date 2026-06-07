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
            # noLambdaPatternNames: ignora { config, pkgs, lib, ... } en módulos
            # (convención del API, no es código muerto).
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

      checks.${system} = { inherit pre-commit-check; };
    };
}
