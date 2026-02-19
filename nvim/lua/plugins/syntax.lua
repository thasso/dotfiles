return {
  'nvim-treesitter/nvim-treesitter',
  event = { "BufReadPre", "BufNewFile" },
  cmd = { "TSUpdateSync", "TSUpdate", "TSInstall" },
  build = ':TSUpdate',
  config = function()
    require("nvim-treesitter.configs").setup({
      ensure_installed = {
        "html",
        "javascript",
        "typescript",
        "yaml",
        "dockerfile",
        "gitignore",
        "c",
        "markdown",
        "markdown_inline",
        "python",
        "lua",
        "vim",
        "vimdoc"
      },
      auto_install = true,
      highlight = { 
        enable = true,
        additional_vim_regex_highlighting = false,
        -- Disable for python due to Neovim 0.11.3 query incompatibility
        disable = function(lang, buf)
          if lang == "python" then
            return true
          end
          return false
        end,
      },
      indent = { 
        enable = true,
        -- Also disable indent for python
        disable = { "python" },
      },
    })
  end,
}
