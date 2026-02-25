return {
  "Saghen/blink.cmp",
  event = "InsertEnter",
  version = "1.*",
  opts = {
    keymap = {
      preset = "default",
      ["<C-Space>"] = { "show", "show_documentation", "hide_documentation" },
      ["<CR>"] = { "fallback" },
      ["<Tab>"] = { "select_and_accept", "fallback" },
      ["<S-Tab>"] = { "select_prev", "fallback" },
      ["<C-e>"] = { "hide", "fallback" },
    },
    completion = {
      list = {
        selection = {
          preselect = true,
          auto_insert = false,
        },
      },
      menu = {
        auto_show = false,
      },
      documentation = {
        auto_show = true,
        auto_show_delay_ms = 150,
      },
      ghost_text = {
        enabled = true,
      },
    },
    signature = {
      enabled = true,
    },
    sources = {
      default = { "lsp", "path", "buffer" },
    },
  },
  opts_extend = { "sources.default" },
}
