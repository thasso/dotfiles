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
