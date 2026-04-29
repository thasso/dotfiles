{
  description = "Devbox, Macbox & Immobox";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    claudeCode = {
      url = "github:sadjow/claude-code-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    codexCli = {
      url = "github:sadjow/codex-cli-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    piMono = {
      url = "github:lukasl-dev/pi-mono.nix";
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
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, claudeCode, codexCli, piMono, nix-darwin, home-manager, nixos-lima, sops-nix, disko, ... }:
    let
      overlays = { nixpkgs.overlays = [
        claudeCode.overlays.default
        codexCli.overlays.default
        piMono.overlays.default
        # Workaround: upstream pi-mono's tsconfig.base.json targets ES2022
        # but pi-tui uses regex /v flag (requires ES2024). tsgo rejects this.
        (final: prev: {
          pi-coding-agent = prev.pi-coding-agent.overrideAttrs (old: {
            preBuild = (old.preBuild or "") + ''
              substituteInPlace tsconfig.base.json \
                --replace-fail '"target": "ES2022"' '"target": "ES2024"' \
                --replace-fail '"lib": ["ES2022"]' '"lib": ["ES2024"]'
            '';
          });
        })
        (final: prev: { gogcli = final.callPackage ./pkgs/gogcli.nix {}; })
        (final: prev: { tempomat = final.callPackage ./pkgs/tempomat.nix {}; })
        # direnv's test suite hangs on Darwin (special chars in test dir names)
        (final: prev: {
          direnv = prev.direnv.overrideAttrs (_old:
            prev.lib.optionalAttrs prev.stdenv.hostPlatform.isDarwin {
              doCheck = false;
            });
        })
      ]; };
      homeManagerConfig = {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.users.thasso = import ./home/thasso.nix;
      };
      serverHomeManagerConfig = {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.users.thasso = import ./home/base.nix;
      };
    in {
      # ── NixOS (Linux) ──────────────────────────────────────────
      nixosConfigurations.devbox = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          overlays
          sops-nix.nixosModules.sops
          ./hosts/devbox/configuration.nix
          home-manager.nixosModules.home-manager
          homeManagerConfig
        ];
      };

      # ── NixOS (Lima VM) ────────────────────────────────────────
      nixosConfigurations.limabox = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        specialArgs = { inherit nixos-lima; };
        modules = [
          overlays
          sops-nix.nixosModules.sops
          ./hosts/limabox/configuration.nix
          home-manager.nixosModules.home-manager
          homeManagerConfig
        ];
      };

      # ── NixOS (Hetzner VPS) ────────────────────────────────────
      nixosConfigurations.immobox = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        modules = [
          overlays
          sops-nix.nixosModules.sops
          disko.nixosModules.disko
          ./hosts/immobox/configuration.nix
          home-manager.nixosModules.home-manager
          serverHomeManagerConfig
        ];
      };

      # ── nix-darwin (macOS) ─────────────────────────────────────
      darwinConfigurations.macbox = nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        modules = [
          overlays
          sops-nix.darwinModules.sops
          ./hosts/macbox/configuration.nix
          home-manager.darwinModules.home-manager
          homeManagerConfig
        ];
      };
    };
}
