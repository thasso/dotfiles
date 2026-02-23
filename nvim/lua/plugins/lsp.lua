local servers = {
	"lua_ls",
	"pyright",
	"rust_analyzer",
	"tsgo",
	"eslint",
	"kotlin_lsp",
	"cssls",
	"cmake",
	"bashls",
	"astro",
	"harper_ls",
	"clangd",
}

local function get_spellfile_path()
	local spellfile = vim.opt.spellfile:get()
	if type(spellfile) == "table" then
		return spellfile[1]
	end
	if type(spellfile) == "string" and spellfile ~= "" then
		return vim.split(spellfile, ",", { plain = true })[1]
	end
	return vim.fn.stdpath("config") .. "/spell/en.utf-8.add"
end

return {
	{
		"mason-org/mason.nvim",
		cmd = "Mason",
		build = ":MasonUpdate",
		opts = {},
	},
	{
		"mason-org/mason-lspconfig.nvim",
		event = { "BufReadPre", "BufNewFile" },
		dependencies = {
			"mason-org/mason.nvim",
			"neovim/nvim-lspconfig",
		},
		opts = {
			ensure_installed = servers,
			automatic_enable = true,
		},
	},
	{
		"neovim/nvim-lspconfig",
		event = { "BufReadPre", "BufNewFile" },
		dependencies = {
			"Saghen/blink.cmp",
		},
		init = function()
			vim.api.nvim_create_autocmd("LspAttach", {
				callback = function(args)
					local opts = { buffer = args.buf }
					local cwd = vim.fs.root(args.buf, { ".git" }) or vim.uv.cwd()

					vim.keymap.set("n", "<leader>gd", function()
						Snacks.picker.lsp_definitions({ cwd = cwd })
					end, vim.tbl_extend("force", opts, { desc = "LSP definitions" }))
					vim.keymap.set("n", "<leader>gY", function()
						Snacks.picker.lsp_declarations({ cwd = cwd })
					end, vim.tbl_extend("force", opts, { desc = "LSP declarations" }))
					vim.keymap.set("n", "<leader>gi", function()
						Snacks.picker.lsp_implementations({ cwd = cwd })
					end, vim.tbl_extend("force", opts, { desc = "LSP implementations" }))
					vim.keymap.set("n", "<leader>gt", function()
						Snacks.picker.lsp_type_definitions({ cwd = cwd })
					end, vim.tbl_extend("force", opts, { desc = "LSP type definition" }))
					vim.keymap.set("n", "<leader>gR", function()
						Snacks.picker.lsp_references({ cwd = cwd })
					end, vim.tbl_extend("force", opts, { desc = "LSP references" }))
					vim.keymap.set(
						"n",
						"<leader>gh",
						vim.lsp.buf.hover,
						vim.tbl_extend("force", opts, { desc = "LSP hover" })
					)
					vim.keymap.set(
						"n",
						"<leader>ga",
						vim.lsp.buf.code_action,
						vim.tbl_extend("force", opts, { desc = "LSP code action" })
					)
					vim.keymap.set(
						"n",
						"<leader>gr",
						vim.lsp.buf.rename,
						vim.tbl_extend("force", opts, { desc = "LSP rename" })
					)
					vim.keymap.set(
						"n",
						"<leader>ge",
						vim.diagnostic.open_float,
						vim.tbl_extend("force", opts, { desc = "Line diagnostics" })
					)
					vim.keymap.set("n", "<leader>gE", function()
						Snacks.picker.diagnostics_buffer({ cwd = cwd })
					end, vim.tbl_extend("force", opts, { desc = "File diagnostics" }))
					vim.keymap.set("n", "<leader>gW", function()
						Snacks.picker.diagnostics({ cwd = cwd })
					end, vim.tbl_extend("force", opts, { desc = "Workspace diagnostics" }))
				end,
			})

			local ok, blink = pcall(require, "blink.cmp")
			if ok then
				vim.lsp.config("*", {
					capabilities = blink.get_lsp_capabilities(),
				})
			end

			vim.lsp.config("lua_ls", {
				settings = {
					Lua = {
						diagnostics = {
							globals = { "vim" },
						},
						workspace = {
							checkThirdParty = false,
						},
					},
				},
			})

			vim.lsp.config("harper_ls", {
				settings = {
					["harper-ls"] = {
						userDictPath = get_spellfile_path(),
					},
				},
			})
		end,
	},
}
