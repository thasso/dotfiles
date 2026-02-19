local function format_current_buffer(extra_opts)
  local conform = require("conform")
  local opts = {
    lsp_fallback = true,
    async = false,
    timeout_ms = 1000,
  }

  if extra_opts then
    for key, value in pairs(extra_opts) do
      opts[key] = value
    end
  end

  conform.format(opts)
end

local function get_visual_range()
  local buf = vim.api.nvim_get_current_buf()
  local start_mark = vim.api.nvim_buf_get_mark(buf, "<")
  local end_mark = vim.api.nvim_buf_get_mark(buf, ">")

  local start_row, start_col = start_mark[1], start_mark[2]
  local end_row, end_col = end_mark[1], end_mark[2]

  if start_row == 0 or end_row == 0 then
    return nil
  end

  if end_row < start_row or (end_row == start_row and end_col < start_col) then
    start_row, end_row = end_row, start_row
    start_col, end_col = end_col, start_col
  end

  local visual_mode = vim.fn.visualmode()
  local current_mode = vim.api.nvim_get_mode().mode
  local is_linewise = visual_mode == "V" or current_mode == "V"
  local range_end_col = end_col + 1

  if is_linewise then
    start_col = 0
    local line = vim.api.nvim_buf_get_lines(buf, end_row - 1, end_row, true)[1] or ""
    range_end_col = #line
  end

  return {
    start = { start_row, start_col },
    ["end"] = { end_row, range_end_col },
  }
end

local function format_visual_selection()
  local range = get_visual_range()
  if range then
    -- Use the last visual selection to limit formatting to the highlighted region.
    format_current_buffer({ range = range })
    return
  end

  format_current_buffer()
end

return {
  "stevearc/conform.nvim",
  event = { "BufReadPre", "BufNewFile" },
  keys = {
    {
      "<leader>gf",
      function()
        format_current_buffer()
      end,
      mode = "n",
      desc = "Format buffer",
    },
    {
      "<leader>gf",
      function()
        format_visual_selection()
      end,
      mode = "v",
      desc = "Format selection",
    },
  },
  opts = {
    formatters_by_ft = {
      javascript = { "prettier" },
      typescript = { "prettier" },
      javascriptreact = { "prettier" },
      typescriptreact = { "prettier" },
      json = { "prettier" },
      jsonc = { "prettier" },
      css = { "prettier" },
      scss = { "prettier" },
      html = { "prettier" },
      markdown = { "prettier" },
      yaml = { "prettier" },
      lua = { "stylua" },
    },
    -- Format on save with conditional logic
    format_on_save = function(bufnr)
      -- Get the file path
      local bufname = vim.api.nvim_buf_get_name(bufnr)
      local root = vim.fs.dirname(bufname)
      
      -- Look for prettier config files
      local prettier_configs = {
        ".prettierrc",
        ".prettierrc.json",
        ".prettierrc.yml",
        ".prettierrc.yaml",
        ".prettierrc.json5",
        ".prettierrc.js",
        ".prettierrc.cjs",
        ".prettierrc.mjs",
        ".prettierrc.toml",
        "prettier.config.js",
        "prettier.config.cjs",
        "prettier.config.mjs",
      }
      
      -- Search up the directory tree for a prettier config
      local has_prettier_config = false
      local search_root = vim.fs.find(prettier_configs, {
        upward = true,
        path = root,
      })
      
      if #search_root > 0 then
        has_prettier_config = true
      end
      
      -- Also check package.json for prettier field
      local package_json = vim.fs.find("package.json", {
        upward = true,
        path = root,
      })
      
      if #package_json > 0 then
        local ok, content = pcall(vim.fn.readfile, package_json[1])
        if ok then
          local json_str = table.concat(content, "\n")
          if json_str:match('"prettier"') then
            has_prettier_config = true
          end
        end
      end
      
      -- Only format on save if prettier config exists
      if has_prettier_config then
        return {
          timeout_ms = 500,
          lsp_fallback = true,
        }
      end
    end,
  },
}
