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

local prose_filetypes = {
	bib = true,
	gitcommit = true,
	mail = true,
	markdown = true,
	org = true,
	pandoc = true,
	plaintex = true,
	quarto = true,
	rmd = true,
	rnoweb = true,
	rst = true,
	tex = true,
	text = true,
}

local function stop_spell_clients(bufnr)
	for _, server in ipairs({ "ltex_plus", "cspell_ls" }) do
		for _, client in ipairs(vim.lsp.get_clients({ bufnr = bufnr, name = server })) do
			vim.lsp.buf_detach_client(bufnr, client.id)
			if client.attached_buffers and vim.tbl_isempty(client.attached_buffers) then
				vim.lsp.stop_client(client.id)
			end
		end
	end
end

local function has_spell_client(bufnr, server)
	return #vim.lsp.get_clients({ bufnr = bufnr, name = server }) > 0
end

vim.keymap.set("n", "<leader>vs", function()
	local bufnr = vim.api.nvim_get_current_buf()
	local ft = vim.bo[bufnr].filetype
	local target = prose_filetypes[ft] and "ltex_plus" or "cspell_ls"
	local target_label = target == "ltex_plus" and "LTeX+" or "cspell"

	if has_spell_client(bufnr, "ltex_plus") or has_spell_client(bufnr, "cspell_ls") or vim.opt_local.spell:get() then
		stop_spell_clients(bufnr)
		vim.opt_local.spell = false
		vim.notify("Spell check: OFF")
		return
	end

	vim.opt_local.spell = false
	local ok = pcall(vim.cmd, "LspStart " .. target)
	if not ok then
		vim.notify("Spell check: failed to start " .. target_label, vim.log.levels.ERROR)
		return
	end
	vim.notify("Spell check: ON (" .. target_label .. ")")
end, { desc = "Toggle spell check (LSP)" })
vim.keymap.set("n", "<leader>vh", function()
	vim.opt.hlsearch = not vim.opt.hlsearch:get()
	vim.notify("Search highlight: " .. (vim.opt.hlsearch:get() and "ON" or "OFF"))
end, { desc = "Toggle search highlight" })
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
vim.keymap.set("n", "<leader>qa", "<cmd>qall<cr>", { desc = "Quit all" })
vim.keymap.set("n", "<leader>qA", "<cmd>qall!<cr>", { desc = "Force quit all without save" })

-- simpler window navigation
vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Move to left window" })
vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Move to bottom window" })
vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Move to top window" })
vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Move to right window" })

-- Move lines up/down
vim.keymap.set("n", "<A-j>", ":m .+1<CR>==", { desc = "Move line down" })
vim.keymap.set("n", "<A-k>", ":m .-2<CR>==", { desc = "Move line up" })
vim.keymap.set("v", "<A-j>", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
vim.keymap.set("v", "<A-k>", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

-- Better indenting in visual mode
vim.keymap.set("v", "<", "<gv", { desc = "Indent left and reselect" })
vim.keymap.set("v", ">", ">gv", { desc = "Indent right and reselect" })
