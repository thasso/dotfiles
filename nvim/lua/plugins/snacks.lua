return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  opts = {
    notifier = { enabled = true },
    input = { enabled = true },
    picker = {
      enabled = true,
      sources = {
        explorer = {
          layout = {
            hidden = { "input" },
            auto_hide = { "input" },
          },
        },
      },
    },
    explorer = { enabled = true },
    quickfile = { enabled = true },
    zen = {
      enabled = true,
      win = {
        width = 90,
        backdrop = { transparent = false, blend = 90 },
      },
    },
  },
  keys = {
    {
      "<leader>ff",
      function()
        Snacks.picker.files()
      end,
      desc = "Find files",
    },
    {
      "<leader>fg",
      function()
        Snacks.picker.grep()
      end,
      desc = "Live grep",
    },
    {
      "<leader>fb",
      function()
        Snacks.picker.buffers()
      end,
      desc = "Find buffers",
    },
    {
      "<leader>fh",
      function()
        Snacks.picker.help()
      end,
      desc = "Help",
    },
    {
      "<leader>fr",
      function()
        Snacks.picker.recent()
      end,
      desc = "Recent files",
    },
    {
      "<leader>fs",
      function()
        Snacks.picker.git_status()
      end,
      desc = "Find changes",
    },
    {
      "<leader>fe",
      function()
        Snacks.explorer()
      end,
      desc = "Toggle file explorer",
    },
    {
      "<leader>vz",
      function()
        Snacks.zen()
      end,
      desc = "Toggle zen mode",
    },
  },
}
