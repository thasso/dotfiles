return {
  "folke/noice.nvim",
  event = "UIEnter",
  opts = {
    lsp = {
      override = {
        ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
        ["vim.lsp.util.stylize_markdown"] = true,
      },
    },
  },
  dependencies = {
    "MunifTanjim/nui.nvim",
    "folke/snacks.nvim",
  }
}
