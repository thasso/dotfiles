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
    # Personal assistant app (server + web UI). No nixpkgs.follows: the package
    # is built against its own pinned nixpkgs (exactly what its native Nix CI
    # validates), keeping the npmDepsHash stable.
    #
    # Pinned to a published RELEASE TAG, never to main: this line together with
    # flake.lock IS the record of which assistant devbox runs, so a plain
    # `make switch` reproduces production instead of rolling it back. The app's
    # Release workflow moves the pin (pa-release, via
    # personal-assistant-release@<tag>.service) and commits the bump here, which
    # makes the dotfiles history the deploy history — roll back by reverting that
    # commit and switching. Because the ref names a tag rather than a branch,
    # `make update` re-locks the same revision and cannot drag the assistant
    # forward on its own.
    personalAssistant = {
      url = "git+https://git.codecluster.net/thasso/personal-assistant.git?ref=refs/tags/v0.18.0";
    };
  };

  outputs = { self, nixpkgs, claudeCode, codexCli, piMono, nix-darwin, home-manager, nixos-lima, sops-nix, disko, personalAssistant, ... }:
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
        # Speech-to-text weights for the assistant's dictation. A host package
        # because the app owns no weights — see the file's own header for why it
        # is a fetchzip (fixed-output ⇒ its path cannot churn on `make update`).
        (final: prev: {
          stt-model-parakeet-tdt-600m-v2-int8 =
            final.callPackage ./pkgs/stt-model-parakeet-tdt-600m-v2-int8.nix {};
        })
        # direnv's test suite hangs on Darwin (special chars in test dir names)
        (final: prev: {
          direnv = prev.direnv.overrideAttrs (_old:
            prev.lib.optionalAttrs prev.stdenv.hostPlatform.isDarwin {
              doCheck = false;
            });
        })
        # weasyprint has a flaky pixel-rendering test (test_unicode_range) that
        # fails on a 1-pixel color diff; skip its test suite.
        (final: prev: {
          python3Packages = prev.python3Packages // {
            weasyprint = prev.python3Packages.weasyprint.overridePythonAttrs (_old: {
              doCheck = false;
            });
          };
        })
        # worktrunk has Darwin sandbox/process-table-sensitive tests that can
        # fail even though the package builds successfully.
        (final: prev: {
          worktrunk = prev.worktrunk.overrideAttrs (_old:
            prev.lib.optionalAttrs prev.stdenv.hostPlatform.isDarwin {
              doCheck = false;
            });
        })
        # herdr vendors libghostty-vt, whose zig build shells out to
        # xcrun/xcode-select (SDK detection) and Apple's libtool (fat archive),
        # and needs the macOS SDK headers — none of which the nixpkgs build
        # wires up on Darwin, so it fails with DarwinSdkNotFound. Provide the
        # SDK and cctools/xcbuild toolchain so the aarch64-darwin build works.
        (final: prev: prev.lib.optionalAttrs prev.stdenv.hostPlatform.isDarwin {
          herdr = prev.herdr.overrideAttrs (old: {
            nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ prev.xcbuild prev.cctools ];
            buildInputs = (old.buildInputs or [ ]) ++ [ prev.apple-sdk ];
            SDKROOT = "${prev.apple-sdk.sdkroot}";
            DEVELOPER_DIR = "${prev.apple-sdk}";
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
          personalAssistant.nixosModules.default
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
