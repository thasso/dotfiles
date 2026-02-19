return {
  'MeanderingProgrammer/render-markdown.nvim',
  dependencies = {
    'nvim-treesitter/nvim-treesitter',
    'nvim-tree/nvim-web-devicons'
  },
  opts = {
    enabled = true,
    latex = { enabled = false }
  },
  keys = {
    { "<leader>mn", "<cmd>RenderMarkdown toggle<cr>", desc = "Toggle markdown rendering" }
  },
}
