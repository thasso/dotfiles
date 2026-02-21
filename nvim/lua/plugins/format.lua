return {
  "stevearc/conform.nvim",
  event = { "BufReadPre", "BufNewFile" },
  init = function()
    vim.api.nvim_create_user_command("Format", function(args)
      local range = nil
      if args.count ~= -1 then
        local end_line = vim.api.nvim_buf_get_lines(0, args.line2 - 1, args.line2, true)[1] or ""
        range = {
          start = { args.line1, 0 },
          ["end"] = { args.line2, #end_line },
        }
      end

      require("conform").format({
        async = true,
        lsp_format = "fallback",
        range = range,
      })
    end, { range = true, desc = "Format buffer or selection" })
  end,
  keys = {
    {
      "<leader>gf",
      "<cmd>Format<cr>",
      mode = "n",
      desc = "Format",
    },
    {
      "<leader>gf",
      "<cmd>'<,'>Format<cr>",
      mode = "x",
      desc = "Format",
    },
  },
  opts = {
    formatters_by_ft = {
      javascript = { "prettierd", "prettier" },
      javascriptreact = { "prettierd", "prettier" },
      typescript = { "prettierd", "prettier" },
      typescriptreact = { "prettierd", "prettier" },
      json = { "prettierd", "prettier" },
      jsonc = { "prettierd", "prettier" },
      css = { "prettierd", "prettier" },
      scss = { "prettierd", "prettier" },
      html = { "prettierd", "prettier" },
      markdown = { "prettierd", "prettier" },
      yaml = { "prettierd", "prettier" },
      graphql = { "prettierd", "prettier" },
    },
    format_on_save = function(bufnr)
      if vim.g.format_on_save == false then
        return nil
      end
      if vim.bo[bufnr].buftype ~= "" then
        return nil
      end
      return { timeout_ms = 1500, lsp_format = "fallback" }
    end,
  },
}
