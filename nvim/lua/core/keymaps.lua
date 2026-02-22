vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Wrap toggle (80 chars on word boundaries)
local function toggle_wrap()
  if vim.opt.wrap:get() then
    vim.opt.wrap = false
    vim.opt.textwidth = 0
    vim.opt.linebreak = false
  else
    vim.opt.wrap = true
    vim.opt.textwidth = 80
    vim.opt.linebreak = true
    vim.opt.breakindent = true
  end
end

vim.keymap.set("n", "<leader>vw", toggle_wrap, { desc = "Toggle wrap at 80 chars" })
vim.keymap.set("n", "<leader>vs", function()
  vim.opt.spell = not vim.opt.spell:get()
  vim.notify("Spell check: " .. (vim.opt.spell:get() and "ON" or "OFF"))
end, { desc = "Toggle spell check" })
vim.keymap.set("x", "p", '"_dP', { desc = "Paste without yanking replaced text" })

if vim.g.format_on_save == nil then
  vim.g.format_on_save = true
end

vim.keymap.set("n", "<leader>vf", function()
  vim.g.format_on_save = not vim.g.format_on_save
  vim.notify("Format on save: " .. (vim.g.format_on_save and "ON" or "OFF"))
end, { desc = "Toggle format on save" })

-- Avoid which-key overlap warning with built-in comment maps.
-- Keep `gc` operator map and provide line toggle on <leader>/.
pcall(vim.keymap.del, "n", "gcc")
vim.keymap.set("n", "<leader>/", function()
  return require("vim._comment").operator() .. "_"
end, { expr = true, desc = "Toggle comment line" })

-- Quit commands
vim.keymap.set("n", "<leader>qq", "<cmd>quit<cr>", { desc = "Quit" })
vim.keymap.set("n", "<leader>qQ", "<cmd>quit!<cr>", { desc = "Force quit without save" })
