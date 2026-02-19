return { 
  "catppuccin/nvim", 
  name = "catppuccin", 
  priority = 1000, 
  config = true,
  opts = {
    flavour = "mocha",
  },
  init = function()
    vim.cmd.colorscheme "catppuccin"
  end,
}
