{
  description = "Devbox";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, ... }:
    let
      system = "x86_64-linux";
    in {
      nixosConfigurations.devbox = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          ./hosts/devbox/configuration.nix
        ];
      };
    };
}
