return {
  "nvim-treesitter/nvim-treesitter",
  lazy = false,
  cmd = { "TSUpdateSync", "TSUpdate", "TSInstall" },
  build = ":TSUpdate",
  config = function()
    local ts = require("nvim-treesitter")
    local parsers = {
      "html",
      "javascript",
      "typescript",
      "jsx",
      "tsx",
      "yaml",
      "dockerfile",
      "gitignore",
      "c",
      "markdown",
      "markdown_inline",
      "regex",
      "bash",
      "python",
      "lua",
      "vim",
      "vimdoc",
    }

    ts.setup({
      install_dir = vim.fn.stdpath("data") .. "/site",
    })

    -- We need this to make sure that we have treesitter enabled for the 
    -- filetypes with support. Otherwise it will default to the regexp based
    -- highlighting
    local group = vim.api.nvim_create_augroup("TreesitterStart", { clear = true })
    vim.api.nvim_create_autocmd("FileType", {
      group = group,
      callback = function(args)
        pcall(vim.treesitter.start, args.buf)
      end,
    })

    ts.install(parsers)
  end,
}
