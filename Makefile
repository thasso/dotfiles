NIX_DIR := $(CURDIR)/nix

# ── Nix targets ────────────────────────────────────────────
.PHONY: switch update dry-update

HOSTNAME := $(shell hostname)

switch:
ifeq ($(shell uname), Darwin)
	sudo darwin-rebuild switch --flake $(NIX_DIR)#macbox
else ifeq ($(HOSTNAME), limabox)
	sudo nixos-rebuild switch --flake $(NIX_DIR)#limabox
else
	sudo nixos-rebuild switch --flake $(NIX_DIR)#devbox
endif

update:
	nix flake update --flake $(NIX_DIR)

dry-update:
	@echo "Checking for flake input updates..."
	@cp $(NIX_DIR)/flake.lock $(NIX_DIR)/flake.lock.bak
	@nix flake update --flake $(NIX_DIR)
	@diff --color $(NIX_DIR)/flake.lock.bak $(NIX_DIR)/flake.lock || true
	@mv $(NIX_DIR)/flake.lock.bak $(NIX_DIR)/flake.lock
	@echo ""
	@echo "Lock file restored. Run 'make update' to apply."

