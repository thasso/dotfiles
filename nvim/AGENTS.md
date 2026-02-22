# Agent Guidelines for Neovim Configuration

## Build/Test Commands

This is a Neovim configuration (not a library). Test by running `nvim` and verifying plugins load correctly.

- Install/update plugins: Open nvim, lazy.nvim auto-installs on first run
- No traditional test/build commands - this is a configuration repository

## Code Style

**Language**: Lua for Neovim configuration

**Structure**:

- Core config in `lua/core/`: options, keymaps, lazy.nvim bootstrap
- Plugins in `lua/plugins/`: one file per plugin/feature area
- Main entry: `init.lua` requires core modules

**Formatting**:

- Indentation: 2 spaces (tabs expanded to spaces)
- No line wrapping in source
- Use double quotes for strings in plugin specs, single quotes acceptable in logic

**Plugin Definitions**:

- Return table from plugin files: `return { "author/plugin", opts = {} }`
- Use `config = true` for default setup, `config = function()` for custom
- Place setup logic in `init` or `config` functions, not at module level

## Keybinding Organization

**Strategy**: Hybrid approach balancing maintainability with discoverability

**Where to Define Keybindings**:

1. **Plugin-specific keymaps** → Define in plugin files (`lua/plugins/*.lua`)
   - Use lazy.nvim's `keys` spec for lazy-loaded plugins
   - Example: `keys = { { "<leader>fe", "<cmd>NvimTreeToggle<cr>", desc = "Toggle file explorer" } }`
   - Keeps plugin config self-contained and enables proper lazy-loading

2. **Built-in Neovim keymaps** → Define in `lua/core/keymaps.lua`
   - For non-plugin keymaps: buffer navigation, window management, general editing
   - NOT for plugin-specific keymaps

3. **Group labels** → Define in `lua/plugins/which-keys.lua`
   - Use which-key's `spec` to define group names only
   - Example: `{ "<leader>f", group = "Files" }`
   - Provides overview of keymap organization without duplication
   - Common groups: `<leader>f` (Files), `<leader>g` (Git), `<leader>s` (Search), `<leader>b` (Buffers)

**Important**: Do NOT duplicate keybinding definitions in which-key if already defined in plugin files

## Current Stack Conventions

- **Picker/Explorer/UI**:
  - Use `snacks.nvim` for picker, explorer, input, and notifier.
  - Do not add new Telescope or nvim-tree config unless explicitly requested.
  - Noice integrates with Snacks notifier (`folke/snacks.nvim`), not `nvim-notify`.

- **LSP**:
  - LSP navigation/actions are under `<leader>g*` (custom mappings), not `gd/gD/gr`-style defaults.
  - Prefer Snacks picker for LSP list UIs (references, definitions, diagnostics).

- **Formatting**:
  - Formatting is managed by `conform.nvim` (`lua/plugins/format.lua`).
  - `<leader>gf` is the canonical format key (normal + visual range).
  - Format-on-save defaults to enabled and is toggled with `<leader>vf`.
  - For JS/TS/CSS/HTML/etc., prefer `prettierd` then `prettier`.

- **Treesitter**:
  - Use the new `nvim-treesitter` API (`require("nvim-treesitter")` + `ts.install(...)`).
  - Keep `lazy = false` for treesitter.

- **View Group (`<leader>v`)**:
  - Keep editor-UX toggles here (wrap, spell, format-on-save, etc.).
  - Current core toggles include `<leader>vw` (wrap), `<leader>vs` (spell), `<leader>vf` (format-on-save).

- **Spell/Clipboard Environment Details**:
  - Spell language defaults to `en_us`.
  - Spell additions file is tracked in repo at `spell/en.utf-8.add`.
  - Over SSH, clipboard uses OSC52 (`vim.g.clipboard = "osc52"`).

## Important

- If we have changes to the stack, make sure that we we update AGENTS.md accordingly
