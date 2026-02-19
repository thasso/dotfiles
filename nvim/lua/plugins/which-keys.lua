return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  opts = {
    preset = "helix",
    spec = {
      { "<leader>f", group = "Files" },
      { "<leader>q", group = "Quit" },
      { "<leader>c", group = "Changes" },
      { "<leader>g", group = "Code", mode = { "n", "v" } },
      { "<leader>z", group = "Zen" }
    }
  },
  keys = {
    {
      "<leader>?",
      function()
        require("which-key").show({ global = false })
      end,
      desc = "Buffer Local Keymaps",
    },
    {
      "<leader>!",
      function()
        require("which-key").show({ global = true })
      end,
      desc = "Global Keymaps",
    },
  },
}
