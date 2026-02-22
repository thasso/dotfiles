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
    routes = {
      {
        filter = {
          any = {
            { event = "lsp", kind = "progress", find = "ltex_plus" },
            { event = "lsp", kind = "progress", find = "ltex" },
          },
        },
        opts = { skip = true },
      },
    },
  },
  dependencies = {
    "MunifTanjim/nui.nvim",
    "folke/snacks.nvim",
  }
}
