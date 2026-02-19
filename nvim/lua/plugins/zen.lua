return {
  "folke/zen-mode.nvim",
  cmd = "ZenMode",
  keys = {
    { "<leader>z", "<cmd>ZenMode<cr>", desc = "Toggle zen mode" }
  },
  opts = {
    window = {
      width = 120,
      height = 0.9,
      options = {
        signcolumn = "no",
        number = false,
        relativenumber = false,
        cursorline = false,
        cursorcolumn = false,
        foldcolumn = "0",
        list = false,
      },
    },
    plugins = {
      options = {
        enabled = true,
        ruler = false,
        showcmd = false,
        laststatus = 0,
      },
      twilight = { enabled = false },
      gitsigns = { enabled = false },
      tmux = { enabled = false },
      kitty = {
        enabled = false,
        font = "+2",
      },
    },
    on_open = function(_)
      vim.wo.wrap = false
    end,
    on_close = function()
      vim.wo.wrap = vim.opt.wrap:get()
    end,
  },
}