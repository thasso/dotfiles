#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTANCE="default"

# Delete existing VM if present
if limactl list --json 2>/dev/null | grep -q "\"$INSTANCE\""; then
  echo "Deleting existing '$INSTANCE' VM..."
  limactl stop "$INSTANCE" 2>/dev/null || true
  limactl delete "$INSTANCE"
fi

echo "Creating '$INSTANCE' VM..."
limactl start --name "$INSTANCE" "$SCRIPT_DIR/default.yaml"

echo ""
echo "VM is ready. To apply NixOS config:"
echo "  lima git clone git@github.com:thasso/dotfiles.git ~/dotfiles"
echo "  lima sudo nixos-rebuild switch --flake ~/dotfiles/nix#limabox"
