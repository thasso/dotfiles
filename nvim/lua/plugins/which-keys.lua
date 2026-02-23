return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  opts = {
    preset = "helix",
    spec = {
      { "<leader>c", group = "Changes" },
      { "<leader>f", group = "Find & Explore" },
      { "<leader>q", group = "Quit" },
      { "<leader>g", group = "Code", mode = { "n", "v" } },
      { "<leader>o", group = "Opencode" },
      { "<leader>v", group = "View" },
    },
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
