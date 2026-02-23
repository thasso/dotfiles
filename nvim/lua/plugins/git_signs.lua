return {
  "lewis6991/gitsigns.nvim",
  event = { "BufReadPre", "BufNewFile" },
  opts = {
    on_attach = function(bufnr)
      local gs = package.loaded.gitsigns

      local function toggle_diffthis()
        if vim.wo.diff then
          vim.cmd("diffoff!")
        else
          gs.diffthis()
        end
      end

      vim.keymap.set("n", "]c", function()
        if vim.wo.diff then
          vim.cmd.normal({ "]c", bang = true })
        else
          gs.nav_hunk("next")
        end
      end, { buffer = bufnr, desc = "Next hunk" })

      vim.keymap.set("n", "[c", function()
        if vim.wo.diff then
          vim.cmd.normal({ "[c", bang = true })
        else
          gs.nav_hunk("prev")
        end
      end, { buffer = bufnr, desc = "Previous hunk" })

      vim.keymap.set("n", "<leader>cp", gs.preview_hunk, { buffer = bufnr, desc = "Preview hunk" })
      vim.keymap.set("n", "<leader>cw", gs.toggle_word_diff, { buffer = bufnr, desc = "Toggle word diff" })
      vim.keymap.set("n", "<leader>cd", toggle_diffthis, { buffer = bufnr, desc = "Toggle file diff" })
      vim.keymap.set("n", "<leader>gD", function()
        Snacks.picker.git_diff({
          previewers = {
            diff = { style = "terminal" },
            git = { args = { "--word-diff=color" } },
          },
        })
      end, { buffer = bufnr, desc = "Git diff (word changes)" })
    end,
  },
}
