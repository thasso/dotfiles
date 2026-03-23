{
  description = "Devbox";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    claudeCode.url = "github:sadjow/claude-code-nix";
  };

  outputs = { self, nixpkgs, claudeCode, ... }:
    let
      system = "x86_64-linux";
    in {
      nixosConfigurations.devbox = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          ({ ... }: {
            nixpkgs.overlays = [
              claudeCode.overlays.default
            ];
          })

          ./hosts/devbox/configuration.nix
        ];
      };
    };
}
