# Nix Configuration

## Hosts

| Host      | System         | Type                |
| --------- | -------------- | ------------------- |
| `devbox`  | x86_64-linux   | NixOS               |
| `limabox` | aarch64-linux  | NixOS (Lima VM)     |
| `immobox` | aarch64-linux  | NixOS (Hetzner VPS) |
| `macbox`  | aarch64-darwin | nix-darwin          |

## Rebuilding

From the repo root:

```bash
make switch
```

Or manually per host:

```bash
# macOS
sudo darwin-rebuild switch --flake nix#macbox

# NixOS
sudo nixos-rebuild switch --flake nix#devbox
sudo nixos-rebuild switch --flake nix#limabox
sudo nixos-rebuild switch --flake nix#immobox --no-reexec
```

## Updating flake inputs

```bash
make update          # update all inputs
make dry-update      # preview what would change

nix flake update nixpkgs --flake nix        # update a single input
```

Then rebuild as above.

## First-time setup (macOS)

1. Install nix: `curl -L https://nixos.org/nix/install | sh`
2. Bootstrap nix-darwin:
   ```bash
   sudo nix run --extra-experimental-features "nix-command flakes" nix-darwin -- switch --flake nix#macbox
   ```
3. After the initial bootstrap, use `make switch`.

## Secrets (sops-nix)

Secrets are encrypted with [sops-nix](https://github.com/Mic92/sops-nix) using age encryption. Encrypted YAML files live in `nix/secrets/` and are decrypted at activation time on each host.

### Prerequisites

You need `sops` available. Either install it or run via nix:

```bash
nix shell nixpkgs#sops
```

On machines where you edit secrets, you need the 1Password CLI (`op`) installed and configured. The age private key is stored in 1Password and fetched on demand via `SOPS_AGE_KEY_CMD` — no key files on disk.

The env var is set automatically via Home Manager (`thasso.nix`) on darwin hosts:

```sh
SOPS_AGE_KEY_CMD="op read 'op://Private/sops-age-key/private_key'"
```

Each `sops` decrypt triggers a Touch ID / biometric prompt via 1Password.

### Key architecture

- **Personal key** (`thasso`): Used for editing secrets. The private key lives only in 1Password (item `sops-age-key` in the `Private` vault). It is never stored on disk.
- **Host keys**: Derived from each host's SSH host key (`/etc/ssh/ssh_host_ed25519_key`). Each host can decrypt secrets assigned to it at activation time. No manual key distribution needed.

### `.sops.yaml` configuration

The `.sops.yaml` file at the repo root controls which age keys can decrypt which secrets files. It contains `creation_rules` — each rule matches a file path regex and lists the age public keys (recipients) that should be able to decrypt it.

```yaml
creation_rules:
  - path_regex: nix/secrets/common\.yaml$ # matched against file path
    key_groups:
      - age:
          - age160hzd... # thasso (personal key)
          - age1teff... # macbox (host key)
          - age1gtfh... # immobox (host key)
          - ...
```

When you encrypt a file, sops looks up the matching rule and encrypts for all listed recipients. When you add or remove a host, you update the recipient lists here and then run `sops updatekeys` on the affected files (see section 4 below).

### 1. Accessing a secret on a host

After `make switch`, secrets declared in a host's configuration are decrypted to:

- **NixOS:** `/run/secrets/<secret_name>`
- **macOS:** via the sops darwin module

To declare a secret in a host config:

```nix
# In hosts/<hostname>/configuration.nix
sops.defaultSopsFile = ../../secrets/common.yaml;
sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

sops.secrets.example_token = {};
# Now available at /run/secrets/example_token after activation
```

To read a secret at runtime:

```bash
sudo cat /run/secrets/example_token
```

### 2. Updating a secret

```bash
sops nix/secrets/common.yaml
```

This opens your `$EDITOR` with the decrypted YAML. Edit the values, save, and close. sops re-encrypts automatically on save.

Then rebuild the affected hosts:

```bash
make switch
```

### 3. Adding or removing a secret

**Adding a secret:**

1. Edit the secrets file and add a new key:

   ```bash
   sops nix/secrets/common.yaml
   ```

   ```yaml
   example_token: the-existing-value
   new_api_key: my-new-secret-value # add this line
   ```

2. Declare it in the host configuration:

   ```nix
   sops.secrets.new_api_key = {};
   ```

3. Rebuild: `make switch`

**To add a new secrets file** (e.g., for a new host):

1. Add a creation rule to `.sops.yaml` with the path regex and recipient keys
2. Create the file and encrypt it:
   ```bash
   echo 'my_secret: value' > nix/secrets/newhost.yaml
   sops --encrypt --in-place nix/secrets/newhost.yaml
   ```

**Removing a secret:**

1. Remove the `sops.secrets.<name>` declaration from the host config
2. Optionally remove the key from the YAML: `sops nix/secrets/common.yaml`
3. Rebuild: `make switch`

### 4. Adding or removing a machine

**Adding a new machine:**

1. Get the new host's SSH host public key:

   ```bash
   cat /etc/ssh/ssh_host_ed25519_key.pub
   ```

2. Convert it to an age public key:

   ```bash
   nix shell nixpkgs#ssh-to-age -c ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub
   ```

3. Add the age key to `.sops.yaml` — add it to the relevant creation rules (e.g., `common.yaml` and/or a host-specific file)

4. Rekey all secrets files that the new host needs access to:

   ```bash
   sops updatekeys nix/secrets/common.yaml
   ```

5. Add the host configuration in `nix/hosts/<hostname>/` and wire it in `flake.nix` with `sops-nix.nixosModules.sops` (or `darwinModules.sops` for macOS)

6. Commit and deploy

**Removing a machine:**

1. Remove its age key from all creation rules in `.sops.yaml`

2. Rekey all affected secrets files to revoke access:

   ```bash
   sops updatekeys nix/secrets/common.yaml
   sops updatekeys nix/secrets/<other-file>.yaml
   ```

3. Remove the host configuration from `flake.nix` and `nix/hosts/<hostname>/`

4. Commit and deploy remaining hosts

**Replacing a machine (new installation, same role):**

The new installation gets a new SSH host key, so the age key changes.

1. Get the new host's SSH host public key and convert to age (steps 1-2 from "Adding")
2. Replace the old age key with the new one in `.sops.yaml`
3. Rekey all affected secrets files:
   ```bash
   sops updatekeys nix/secrets/common.yaml
   sops updatekeys nix/secrets/<hostname>.yaml
   ```
4. Deploy: `make switch`

### Current age keys

| Identity  | Age public key                                                   |
| --------- | ---------------------------------------------------------------- |
| `thasso`  | `age160hzd3cahej40u6226t6c24hurcg8skg8l3l058jz4gvj24x23jshem5zg` |
| `macbox`  | `age1teffze36axkjcz2pzcgzs2hawufxj77mmqvn3h3g9hskfyrmhqqqzv6cn8` |
| `immobox` | `age1gtfh442v4e9ju4gczxjmgdg9n76fngaqr8cxep4lzrxlqwaay3zqv2994s` |
| `limabox` | `age1xae0pw26hmspa8h529zyhpg0c5pppef6327uemfc7djfxmtvqu8sgscz5g` |
| `devbox`  | `age1hkdekhv37pgnrj9vptg35y84mpaupqgawprx4y6q2psaz62y8flqp6hu85` |

### Secrets files

| File                       | Recipients       | Purpose                |
| -------------------------- | ---------------- | ---------------------- |
| `nix/secrets/common.yaml`  | all hosts        | Shared secrets         |
| `nix/secrets/immobox.yaml` | thasso + immobox | Hetzner/server secrets |
| `nix/secrets/macbox.yaml`  | thasso + macbox  | macOS-only secrets     |
