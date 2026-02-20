return {
  "MeanderingProgrammer/render-markdown.nvim",
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "nvim-tree/nvim-web-devicons",
  },
  ft = { "markdown" },
  opts = {
    enabled = true,
    latex = { enabled = false }
  },
  keys = {
    { "<leader>vr", "<cmd>RenderMarkdown toggle<cr>", desc = "Toggle rendering" }
  },
}
