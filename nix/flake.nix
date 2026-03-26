{
  description = "Devbox & Macbox";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    claudeCode = {
      url = "github:sadjow/claude-code-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-lima = {
      url = "github:nixos-lima/nixos-lima/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, claudeCode, nix-darwin, home-manager, nixos-lima, ... }:
    let
      overlays = { nixpkgs.overlays = [
        claudeCode.overlays.default
        (final: prev: { meridian = final.callPackage ./pkgs/meridian.nix {}; })
        (final: prev: { gogcli = final.callPackage ./pkgs/gogcli.nix {}; })
      ]; };
      homeManagerConfig = { meridianPort }: {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.extraSpecialArgs = { inherit meridianPort; };
        home-manager.users.thasso = import ./home/thasso.nix;
      };
    in {
      # ── NixOS (Linux) ──────────────────────────────────────────
      nixosConfigurations.devbox = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          overlays
          ./hosts/devbox/configuration.nix
          home-manager.nixosModules.home-manager
          (homeManagerConfig { meridianPort = 4141; })
        ];
      };

      # ── NixOS (Lima VM) ────────────────────────────────────────
      nixosConfigurations.limabox = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        specialArgs = { inherit nixos-lima; };
        modules = [
          overlays
          ./hosts/limabox/configuration.nix
          home-manager.nixosModules.home-manager
          (homeManagerConfig { meridianPort = 4142; })
        ];
      };

      # ── nix-darwin (macOS) ─────────────────────────────────────
      darwinConfigurations.macbox = nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        modules = [
          overlays
          ./hosts/macbox/configuration.nix
          home-manager.darwinModules.home-manager
          (homeManagerConfig { meridianPort = 4143; })
        ];
      };
    };
}
