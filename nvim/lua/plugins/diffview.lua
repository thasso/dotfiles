return {
  "sindrets/diffview.nvim",
  cmd = { "DiffviewOpen", "DiffviewFileHistory", "DiffviewClose" },
  keys = {
    { "<leader>cv", "<cmd>DiffviewOpen<cr>", desc = "Diffview changed files" },
    { "<leader>ch", "<cmd>DiffviewFileHistory %<cr>", desc = "File history (current)" },
    { "<leader>cH", "<cmd>DiffviewFileHistory<cr>", desc = "File history (repo)" },
    { "<leader>cq", "<cmd>DiffviewClose<cr>", desc = "Close diffview" },
  },
  opts = {
    file_panel = {
      listing_style = "tree",
      tree_options = {
        flatten_dirs = true,
        folder_statuses = "only_folded",
      },
      win_config = {
        position = "left",
        width = 35,
      },
    },
    view = {
      default = {
        layout = "diff2_horizontal",
        disable_diagnostics = true,
      },
      merge_tool = {
        layout = "diff3_horizontal",
        disable_diagnostics = true,
        winbar_info = true,
      },
      file_history = {
        layout = "diff2_horizontal",
        disable_diagnostics = true,
      },
    },
  },
}
