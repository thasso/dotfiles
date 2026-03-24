return {
  "nvim-lualine/lualine.nvim",
  event = "UIEnter",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  opts = function()
    local function lsp_status()
      local clients = vim.lsp.get_clients({ bufnr = 0 })
      if #clients == 0 then
        return ""
      end

      local names = {}
      for _, client in ipairs(clients) do
        names[#names + 1] = client.name
      end

      return "LSP:" .. table.concat(names, ",")
    end

    return {
      options = {
        theme = "catppuccin-mocha",
      },
      sections = {
        lualine_x = { lsp_status, "encoding" },
      },
    }
  end,
}
