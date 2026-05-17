#!/usr/bin/env bash
# Recover Nix/nix-darwin after a macOS update.
#
# This script checks the Nix LaunchDaemons, makes sure they are enabled and
# loaded, verifies that the Nix daemon responds, and then runs a nix-darwin
# switch. If darwin-rebuild is not on PATH, it rebuilds the flake system output
# first and uses ./result/sw/bin/darwin-rebuild, which is the manual recovery
# path that tends to work after macOS updates.

set -u
set -o pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
FLAKE_DIR="${FLAKE_DIR:-$SCRIPT_DIR}"
HOST="${HOST:-macbox}"
DO_SWITCH=1
OFFLINE=0

NIX_DAEMON_LABEL="org.nixos.nix-daemon"
NIX_STORE_LABEL="org.nixos.darwin-store"
NIX_DAEMON_PLIST="/Library/LaunchDaemons/${NIX_DAEMON_LABEL}.plist"
NIX_STORE_PLIST="/Library/LaunchDaemons/${NIX_STORE_LABEL}.plist"
NIX_SOCKET="/nix/var/nix/daemon-socket/socket"

usage() {
  cat <<EOF
Usage: $0 [--host HOST] [--flake DIR] [--no-switch] [--offline]

Defaults:
  --host   $HOST
  --flake  $FLAKE_DIR

Environment overrides are also supported: HOST=macbox FLAKE_DIR=/path/to/nix $0
EOF
}

log() { printf '\033[1;34m==>\033[0m %s\n' "$*" >&2; }
ok() { printf '\033[1;32mOK:\033[0m %s\n' "$*" >&2; }
warn() { printf '\033[1;33mWARN:\033[0m %s\n' "$*" >&2; }
fail() { printf '\033[1;31mERROR:\033[0m %s\n' "$*" >&2; }

run() {
  printf '+ %s\n' "$*" >&2
  "$@"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --host)
      HOST="${2:-}"
      shift 2
      ;;
    --flake)
      FLAKE_DIR="${2:-}"
      shift 2
      ;;
    --no-switch)
      DO_SWITCH=0
      shift
      ;;
    --offline)
      OFFLINE=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      fail "Unknown argument: $1"
      usage
      exit 2
      ;;
  esac
done

if [[ "$(uname -s)" != "Darwin" ]]; then
  fail "This recovery script is for macOS/nix-darwin only."
  exit 1
fi

if [[ ! -d "$FLAKE_DIR" || ! -f "$FLAKE_DIR/flake.nix" ]]; then
  fail "Flake directory does not contain flake.nix: $FLAKE_DIR"
  exit 1
fi

log "Requesting sudo credentials up front"
if ! sudo -v; then
  fail "sudo authentication failed"
  exit 1
fi

# Keep sudo alive while the script runs.
while true; do sudo -n true; sleep 60; kill -0 "$$" 2>/dev/null || exit; done 2>/dev/null &
SUDO_KEEPALIVE_PID=$!
trap 'kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true' EXIT

check_plist() {
  local label="$1"
  local plist="$2"

  log "Checking $label plist"
  if [[ ! -f "$plist" ]]; then
    fail "Missing $plist"
    return 1
  fi

  if ! plutil -lint "$plist" >/dev/null; then
    fail "Invalid plist: $plist"
    return 1
  fi
  ok "$plist is valid"

  # launchd is picky about LaunchDaemon ownership/permissions. macOS updates or
  # manual repairs can leave these wrong, so normalize them.
  run sudo chown root:wheel "$plist" || return 1
  run sudo chmod 0644 "$plist" || return 1
}

is_disabled() {
  local label="$1"
  sudo launchctl print-disabled system 2>/dev/null | grep -Eq '"'"$label"'"[[:space:]]*=>[[:space:]]*true'
}

is_loaded() {
  local label="$1"
  sudo launchctl print "system/$label" >/dev/null 2>&1
}

bootstrap_service() {
  local label="$1"
  local plist="$2"
  local require_kickstart_success="${3:-1}"

  log "Ensuring $label is enabled and loaded"
  if is_disabled "$label"; then
    warn "$label is disabled; enabling it so it can start after reboot"
    run sudo launchctl enable "system/$label" || return 1
  else
    ok "$label is not disabled"
  fi

  if is_loaded "$label"; then
    ok "$label is already loaded"
  else
    warn "$label is not loaded; bootstrapping $plist"
    if ! run sudo launchctl bootstrap system "$plist"; then
      warn "bootstrap failed; trying bootout then bootstrap"
      sudo launchctl bootout system "$plist" >/dev/null 2>&1 || true
      run sudo launchctl bootstrap system "$plist" || return 1
    fi
  fi

  if ! run sudo launchctl kickstart -k "system/$label"; then
    if [[ "$require_kickstart_success" -eq 1 ]]; then
      return 1
    fi
    warn "$label kickstart failed; continuing because this can be normal for one-shot services that already did their work"
  fi

  if is_loaded "$label"; then
    ok "$label is loaded"
  elif [[ "$require_kickstart_success" -eq 1 ]]; then
    fail "$label is still not loaded after kickstart"
    return 1
  else
    warn "$label is not listed as loaded after kickstart; continuing and verifying /nix directly"
  fi
}

plist_has_key_true() {
  local plist="$1"
  local key="$2"
  /usr/libexec/PlistBuddy -c "Print :$key" "$plist" 2>/dev/null | grep -qi '^true$'
}

check_reboot_readiness() {
  log "Checking whether services should come up after reboot"

  local ready=1
  for item in "$NIX_STORE_LABEL:$NIX_STORE_PLIST" "$NIX_DAEMON_LABEL:$NIX_DAEMON_PLIST"; do
    local label="${item%%:*}"
    local plist="${item#*:}"

    if [[ ! -f "$plist" ]]; then
      fail "$label will not start after reboot because $plist is missing"
      ready=0
      continue
    fi

    if is_disabled "$label"; then
      fail "$label is disabled in launchd and will not start after reboot"
      ready=0
    else
      ok "$label is enabled for the system launchd domain"
    fi
  done

  if plist_has_key_true "$NIX_STORE_PLIST" RunAtLoad; then
    ok "$NIX_STORE_LABEL has RunAtLoad=true"
  else
    warn "$NIX_STORE_LABEL does not have RunAtLoad=true; /nix may not be mounted automatically"
    ready=0
  fi

  if plist_has_key_true "$NIX_DAEMON_PLIST" KeepAlive || plist_has_key_true "$NIX_DAEMON_PLIST" RunAtLoad; then
    ok "$NIX_DAEMON_LABEL has KeepAlive=true or RunAtLoad=true"
  else
    warn "$NIX_DAEMON_LABEL has neither KeepAlive=true nor RunAtLoad=true"
    ready=0
  fi

  if [[ "$ready" -eq 1 ]]; then
    ok "LaunchDaemon checks look reboot-ready"
  else
    warn "One or more reboot-readiness checks failed; inspect the warnings above"
  fi
}

check_nix_daemon() {
  log "Checking /nix and Nix daemon connectivity"

  if [[ ! -d /nix ]]; then
    fail "/nix does not exist. The darwin-store service did not mount or create it."
    return 1
  fi
  ok "/nix exists"

  if [[ ! -d /nix/store ]]; then
    fail "/nix/store does not exist. Try rebooting, then rerun this script."
    return 1
  fi
  ok "/nix/store exists"

  if [[ ! -S "$NIX_SOCKET" ]]; then
    warn "Nix daemon socket is not present at $NIX_SOCKET yet"
  else
    ok "Nix daemon socket exists"
  fi

  if ! command -v nix >/dev/null 2>&1; then
    fail "nix is not on PATH in this shell. Open a new terminal or source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
    return 1
  fi
  ok "Found nix: $(command -v nix)"
  nix --version

  if nix store ping >/dev/null 2>&1; then
    ok "nix store ping succeeded"
  else
    fail "nix store ping failed; daemon is still not reachable"
    return 1
  fi
}

find_or_build_darwin_rebuild() {
  log "Finding darwin-rebuild"

  if [[ -x /run/current-system/sw/bin/darwin-rebuild ]]; then
    printf '%s\n' /run/current-system/sw/bin/darwin-rebuild
    return 0
  fi

  if command -v darwin-rebuild >/dev/null 2>&1; then
    command -v darwin-rebuild
    return 0
  fi

  warn "darwin-rebuild is not installed/on PATH; building darwinConfigurations.$HOST.system"
  (
    cd "$FLAKE_DIR" || exit 1
    run nix build ".#darwinConfigurations.${HOST}.system"
  ) || return 1

  if [[ -x "$FLAKE_DIR/result/sw/bin/darwin-rebuild" ]]; then
    printf '%s\n' "$FLAKE_DIR/result/sw/bin/darwin-rebuild"
    return 0
  fi

  fail "Build finished, but $FLAKE_DIR/result/sw/bin/darwin-rebuild does not exist"
  return 1
}

run_switch() {
  local darwin_rebuild="$1"
  local args=(switch --flake "$FLAKE_DIR#$HOST")
  if [[ "$OFFLINE" -eq 1 ]]; then
    args+=(--offline)
  fi

  log "Running nix-darwin switch for $HOST"
  run sudo "$darwin_rebuild" "${args[@]}"
}

check_plist "$NIX_STORE_LABEL" "$NIX_STORE_PLIST" || exit 1
check_plist "$NIX_DAEMON_LABEL" "$NIX_DAEMON_PLIST" || exit 1

# The store mount needs to exist before nix-daemon can exec from /nix/store.
bootstrap_service "$NIX_STORE_LABEL" "$NIX_STORE_PLIST" 0 || exit 1
bootstrap_service "$NIX_DAEMON_LABEL" "$NIX_DAEMON_PLIST" 1 || exit 1
check_reboot_readiness
check_nix_daemon || exit 1

if [[ "$DO_SWITCH" -eq 1 ]]; then
  darwin_rebuild_path="$(find_or_build_darwin_rebuild)" || exit 1
  run_switch "$darwin_rebuild_path" || exit 1
else
  ok "Skipping nix-darwin switch because --no-switch was passed"
fi

ok "macOS Nix/nix-darwin recovery checks completed"
