return {
  "MeanderingProgrammer/render-markdown.nvim",
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "nvim-tree/nvim-web-devicons",
  },
  ft = { "markdown" },
  opts = {
    enabled = true,
    render_modes = { "n", "c", "t" },
    anti_conceal = { enabled = false },
    latex = { enabled = false }
  },
  keys = {
    { "<leader>vr", "<cmd>RenderMarkdown toggle<cr>", desc = "Toggle rendering" }
  },
}
