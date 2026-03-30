NIX_DIR := $(CURDIR)/nix

# ── Nix targets ────────────────────────────────────────────
.PHONY: switch switch-offline update dry-update deploy-all

HOSTNAME := $(shell hostname)

switch:
ifeq ($(shell uname), Darwin)
	sudo darwin-rebuild switch --flake $(NIX_DIR)#macbox
else ifeq ($(HOSTNAME), limabox)
	sudo nixos-rebuild switch --flake $(NIX_DIR)#limabox --no-reexec
else ifeq ($(HOSTNAME), immobox)
	sudo nixos-rebuild switch --flake $(NIX_DIR)#immobox --no-reexec
else
	sudo nixos-rebuild switch --flake $(NIX_DIR)#devbox --no-reexec
endif

switch-offline:
ifeq ($(shell uname), Darwin)
	sudo darwin-rebuild switch --flake $(NIX_DIR)#macbox --offline
else ifeq ($(HOSTNAME), limabox)
	sudo nixos-rebuild switch --flake $(NIX_DIR)#limabox --no-reexec --offline
else ifeq ($(HOSTNAME), immobox)
	sudo nixos-rebuild switch --flake $(NIX_DIR)#immobox --no-reexec --offline
else
	sudo nixos-rebuild switch --flake $(NIX_DIR)#devbox --no-reexec --offline
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

# ── Remote deployment ─────────────────────────────────────
# Syncs repo to remote host and rebuilds there (works from macOS)
deploy-%:
	@. $(NIX_DIR)/hosts/deploy-targets.env && \
	echo "==> Syncing to $$($*)..." && \
	rsync -az --delete --exclude='.git' --exclude='result' \
		$(CURDIR)/ root@$${$*}:/etc/dotfiles/ && \
	ssh root@$${$*} "cd /etc/dotfiles && nix run nixpkgs\#git -- config --global --add safe.directory /etc/dotfiles && nix run nixpkgs\#git -- init -q && nix run nixpkgs\#git -- add -A && nix run nixpkgs\#git -- -c user.name=deploy -c user.email=deploy@localhost commit -q -m deploy --allow-empty && cd nix && nixos-rebuild switch --flake .\#$*"

deploy-all:
	@. $(NIX_DIR)/hosts/deploy-targets.env && \
	for host in $$(grep -v '^\#' $(NIX_DIR)/hosts/deploy-targets.env | grep -v '^\s*$$' | cut -d= -f1); do \
		echo "==> Deploying $$host"; \
		$(MAKE) deploy-$$host; \
	done

