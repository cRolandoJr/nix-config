{
  description = "rolando NixOS config - victus";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Hooks de calidad para .nix antes de cada commit.
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

      # Checks que corren antes de cada commit (instalados en .git/hooks
      # automáticamente al entrar al devShell via direnv `use flake`).
      pre-commit-check = pre-commit-hooks.lib.${system}.run {
        src = ./.;
        hooks = {
          # nixfmt = RFC 166 (el "rfc-style" era alias, ya unificado).
          nixfmt.enable = true;

          # statix = lint de anti-patrones. Config en .statix.toml.
          statix.enable = true;

          # deadnix = detecta bindings sin uso.
          # noLambdaPatternNames: ignora { config, pkgs, lib, ... } en módulos
          # NixOS (convención del API; no es "código muerto").
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

      # devShell con shellHook que instala los pre-commit hooks en .git/hooks.
      # Cuando entrás al directorio (con direnv activo), los hooks se activan solos.
      devShells.${system}.default = pkgs.mkShell {
        inherit (pre-commit-check) shellHook;
        buildInputs = pre-commit-check.enabledPackages;
      };

      # `nix flake check` valida los hooks contra todos los .nix del flake.
      checks.${system} = { inherit pre-commit-check; };
    };
}
