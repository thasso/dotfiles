return {
  {
    "mason-org/mason.nvim", 
    build = ":MasonUpdate",
    cmd = "Mason", 
    config = true 
  },
  { 
    "mason-org/mason-lspconfig.nvim",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = { "mason-org/mason.nvim" },
    config = function()
      -- Setup mason-lspconfig to auto-install servers
      require("mason-lspconfig").setup({
        ensure_installed = { "lua_ls", "rust_analyzer", "pyright" },
        automatic_installation = true,
      })
      
      -- Get capabilities for LSP
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      local cmp_nvim_lsp_ok, cmp_nvim_lsp = pcall(require, 'cmp_nvim_lsp')
      if cmp_nvim_lsp_ok then
        capabilities = cmp_nvim_lsp.default_capabilities(capabilities)
      end
      
      -- Use native Neovim 0.11+ LSP API
      -- Define LSP server configurations
      local servers = {
        lua_ls = {
          cmd = { vim.fn.stdpath("data") .. "/mason/bin/lua-language-server" },
          root_markers = { ".luarc.json", ".luarc.jsonc", ".luacheckrc", ".stylua.toml", "stylua.toml", "selene.toml", "selene.yml", ".git" },
        },
        pyright = {
          cmd = { vim.fn.stdpath("data") .. "/mason/bin/pyright-langserver", "--stdio" },
          root_markers = { "pyproject.toml", "setup.py", "setup.cfg", "requirements.txt", "Pipfile", ".git" },
        },
        rust_analyzer = {
          cmd = { vim.fn.stdpath("data") .. "/mason/bin/rust-analyzer" },
          root_markers = { "Cargo.toml", "rust-project.json", ".git" },
        },
      }
      
      -- Setup autocmd to start LSP on file open
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "lua", "python", "rust" },
        callback = function(args)
          local bufnr = args.buf
          local filetype = vim.bo[bufnr].filetype
          
          -- Map filetype to server
          local server_map = {
            lua = "lua_ls",
            python = "pyright",
            rust = "rust_analyzer",
          }
          
          local server_name = server_map[filetype]
          if not server_name then return end
          
          local server_config = servers[server_name]
          if not server_config then return end
          
          -- Check if server is already attached
          local clients = vim.lsp.get_clients({ bufnr = bufnr, name = server_name })
          if #clients > 0 then return end
          
          -- Find root directory
          local root_dir = vim.fs.root(bufnr, server_config.root_markers)
          if not root_dir then return end
          
          -- Start LSP client
          vim.lsp.start({
            name = server_name,
            cmd = server_config.cmd,
            root_dir = root_dir,
            capabilities = capabilities,
          })
        end,
      })
    end,
  },
  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer"
    },
    config = function()
      local auto_select = true
      local cmp = require('cmp')
      cmp.setup({
        window = {
          -- completion = cmp.config.window.bordered(),
          -- documentation = cmp.config.window.bordered(),
        },
        completion = {
          completeopt = "menu,menuone,noinsert" .. (auto_select and "" or ",noselect"),
          autocomplete = false
        },
        preselect = auto_select and cmp.PreselectMode.Item or cmp.PreselectMode.None,
        mapping = cmp.mapping({
          ['<C-Space>'] = cmp.mapping.complete(),
        }),
        sources = cmp.config.sources({
          { name = 'nvim_lsp' },
          { name = 'path' },
        }, {
          { name = 'buffer' },
        })
        -- mapping = cmp.mapping.preset.insert({
        --   ['<C-b>'] = cmp.mapping.scroll_docs(-4),
        --   ['<C-f>'] = cmp.mapping.scroll_docs(4),
        --   ['<C-Space>'] = cmp.mapping.complete(),
        --   ['<C-e>'] = cmp.mapping.abort(),
        --   ['<CR>'] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
        -- }),
      })
    end,
  }
}
