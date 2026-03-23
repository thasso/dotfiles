# Nix Configuration

## Hosts

| Host     | System         | Type       |
| -------- | -------------- | ---------- |
| `devbox` | x86_64-linux   | NixOS      |
| `macbox` | aarch64-darwin | nix-darwin |

## Rebuilding

### macOS (macbox)

```bash
sudo darwin-rebuild switch --flake .#macbox
```

### NixOS (devbox)

```bash
sudo nixos-rebuild switch --flake .#devbox
```

## Updating flake inputs

To pull the latest versions of nixpkgs, home-manager, nix-darwin, etc:

```bash
nix flake update
```

Then rebuild as above.

## First-time setup (macOS)

1. Install nix: `curl -L https://nixos.org/nix/install | sh`
2. Bootstrap nix-darwin:
   ```bash
   sudo nix run --extra-experimental-features "nix-command flakes" nix-darwin -- switch --flake .#macbox
   ```
3. After the initial bootstrap, use `darwin-rebuild switch` as above.
