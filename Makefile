NIX_DIR := $(CURDIR)/nix

# ── Nix targets ────────────────────────────────────────────
.PHONY: switch switch-offline update dry-update deploy-all

HOSTNAME := $(shell hostname)

switch:
ifeq ($(shell uname), Darwin)
	sudo darwin-rebuild switch --flake $(NIX_DIR)#macbox
else
	sudo nixos-rebuild switch --flake $(NIX_DIR)#$(HOSTNAME)
endif

switch-offline:
ifeq ($(shell uname), Darwin)
	sudo darwin-rebuild switch --flake $(NIX_DIR)#macbox --offline
else
	sudo nixos-rebuild switch --flake $(NIX_DIR)#$(HOSTNAME) --offline
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
# Pulls latest and rebuilds on remote host (requires repo cloned in ~/dotfiles)
deploy-%:
	@. $(NIX_DIR)/hosts/deploy-targets.env && \
	echo "==> Deploying $*..." && \
	ssh -A thasso@$${$*} "cd ~/dotfiles && git pull && make switch"

deploy-all:
	@. $(NIX_DIR)/hosts/deploy-targets.env && \
	for host in $$(grep -v '^\#' $(NIX_DIR)/hosts/deploy-targets.env | grep -v '^\s*$$' | cut -d= -f1); do \
		echo "==> Deploying $$host"; \
		$(MAKE) deploy-$$host; \
	done

