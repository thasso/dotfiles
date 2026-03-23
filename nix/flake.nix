{
  description = "Devbox & Macbox";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    claudeCode.url = "github:sadjow/claude-code-nix";
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, claudeCode, nix-darwin, home-manager, ... }:
    let
      claudeCodeOverlay = { nixpkgs.overlays = [ claudeCode.overlays.default ]; };
      homeManagerConfig = {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.users.thasso = import ./home/thasso.nix;
      };
    in {
      # ── NixOS (Linux) ──────────────────────────────────────────
      nixosConfigurations.devbox = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          claudeCodeOverlay
          ./hosts/devbox/configuration.nix
          home-manager.nixosModules.home-manager
          homeManagerConfig
        ];
      };

      # ── nix-darwin (macOS) ─────────────────────────────────────
      darwinConfigurations.macbox = nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        modules = [
          claudeCodeOverlay
          ./hosts/macbox/configuration.nix
          home-manager.darwinModules.home-manager
          homeManagerConfig
        ];
      };
    };
}
