return {
  "stevearc/conform.nvim",
  event = { "BufReadPre", "BufNewFile" },
  keys = {
    {
      "<leader>gf",
      function()
        require("conform").format({ async = true, lsp_format = "fallback" })
      end,
      mode = "n",
      desc = "Format",
    },
    {
      "<leader>gf",
      function()
        local bufnr = vim.api.nvim_get_current_buf()
        local start_pos = vim.api.nvim_buf_get_mark(bufnr, "<")
        local end_pos = vim.api.nvim_buf_get_mark(bufnr, ">")

        if start_pos[1] == 0 or end_pos[1] == 0 then
          require("conform").format({ async = true, lsp_format = "fallback" })
          return
        end

        local start_row = start_pos[1]
        local start_col = start_pos[2]
        local end_row = end_pos[1]
        local end_col = end_pos[2]

        if start_row > end_row or (start_row == end_row and start_col > end_col) then
          start_row, end_row = end_row, start_row
          start_col, end_col = end_col, start_col
        end

        local line_count = vim.api.nvim_buf_line_count(bufnr)
        start_row = math.min(math.max(start_row, 1), line_count)
        end_row = math.min(math.max(end_row, 1), line_count)

        local start_line = vim.api.nvim_buf_get_lines(bufnr, start_row - 1, start_row, true)[1] or ""
        local end_line = vim.api.nvim_buf_get_lines(bufnr, end_row - 1, end_row, true)[1] or ""
        start_col = math.min(math.max(start_col, 0), #start_line)
        end_col = math.min(math.max(end_col, 0), #end_line)

        require("conform").format({
          async = true,
          lsp_format = "fallback",
          range = {
            start = { start_row, start_col },
            ["end"] = { end_row, end_col },
          },
        })
      end,
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
