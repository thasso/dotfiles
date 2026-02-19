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

vim.keymap.set("n", "<leader>w", toggle_wrap, { desc = "Toggle wrap at 80 chars" })

-- Quit commands
vim.keymap.set("n", "<leader>qq", "<cmd>quit<cr>", { desc = "Quit" })
vim.keymap.set("n", "<leader>qQ", "<cmd>quit!<cr>", { desc = "Force quit without save" })
