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
  "ltex",
  "clangd",
}

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

          vim.keymap.set("n", "gd", vim.lsp.buf.definition, vim.tbl_extend("force", opts, { desc = "LSP definition" }))
          vim.keymap.set("n", "gD", vim.lsp.buf.declaration, vim.tbl_extend("force", opts, { desc = "LSP declaration" }))
          vim.keymap.set("n", "gr", function()
            local ok, telescope = pcall(require, "telescope.builtin")
            if not ok then
              vim.lsp.buf.references()
              return
            end

            telescope.lsp_references({
              cwd = vim.fs.root(args.buf, { ".git" }) or vim.uv.cwd(),
              path_display = { "smart" },
            })
          end, vim.tbl_extend("force", opts, { desc = "LSP references" }))
          vim.keymap.set("n", "gi", vim.lsp.buf.implementation, vim.tbl_extend("force", opts, { desc = "LSP implementation" }))
          vim.keymap.set("n", "K", vim.lsp.buf.hover, vim.tbl_extend("force", opts, { desc = "LSP hover" }))
          vim.keymap.set("n", "<leader>ga", vim.lsp.buf.code_action, vim.tbl_extend("force", opts, { desc = "LSP code action" }))
          vim.keymap.set("n", "<leader>gr", vim.lsp.buf.rename, vim.tbl_extend("force", opts, { desc = "LSP rename" }))
          vim.keymap.set("n", "<leader>gf", function()
            vim.lsp.buf.format({ async = true })
          end, vim.tbl_extend("force", opts, { desc = "LSP format" }))
          vim.keymap.set("n", "<leader>ge", vim.diagnostic.open_float, vim.tbl_extend("force", opts, { desc = "Line diagnostics" }))
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
    end,
  },
}
