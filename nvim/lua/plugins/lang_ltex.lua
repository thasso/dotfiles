local function get_default_spelllang()
  local spelllangs = vim.opt.spelllang:get()
  return spelllangs[1] or "en_us"
end

local function spelllang_to_ltex_language(spelllang)
  local parts = vim.split(spelllang, "[-_]")
  if #parts == 2 then
    return string.lower(parts[1]) .. "-" .. string.upper(parts[2])
  end
  return spelllang
end

local function get_spellfile_path()
  local spellfile = vim.opt.spellfile:get()
  if type(spellfile) == "table" then
    return spellfile[1]
  end
  if type(spellfile) == "string" and spellfile ~= "" then
    return vim.split(spellfile, ",", { plain = true })[1]
  end
  return vim.fn.stdpath("config") .. "/spell/en.utf-8.add"
end

local function ensure_spellfile(spellfile)
  if vim.uv.fs_stat(spellfile) then
    return
  end
  vim.fn.mkdir(vim.fs.dirname(spellfile), "p")
  vim.fn.writefile({}, spellfile)
end

local function get_ltex_client(bufnr)
  local clients = vim.lsp.get_clients({ bufnr = bufnr, name = "ltex_plus" })
  if #clients == 0 then
    clients = vim.lsp.get_clients({ bufnr = bufnr, name = "ltex" })
  end
  return clients[1]
end

local function append_unique_words(spellfile, words)
  local existing = {}
  for _, line in ipairs(vim.fn.readfile(spellfile)) do
    if line ~= "" then
      existing[line] = true
    end
  end

  local appended = {}
  for _, word in ipairs(words) do
    if not existing[word] then
      appended[#appended + 1] = word
      existing[word] = true
    end
  end

  if #appended > 0 then
    vim.fn.writefile(appended, spellfile, "a")
  end

  return appended
end

local function register_ltex_dictionary_handler(default_lang)
  vim.lsp.commands["_ltex.addToDictionary"] = function(command)
    local arg = command.arguments and command.arguments[1] or {}
    local words_by_lang = type(arg.words) == "table" and arg.words or {}
    local lang = next(words_by_lang) or default_lang
    local words = words_by_lang[lang] or {}

    if #words == 0 and type(arg.word) == "string" and arg.word ~= "" then
      words = { arg.word }
    end

    if #words == 0 then
      vim.notify("LTEX: could not extract dictionary word", vim.log.levels.WARN)
      return
    end

    table.sort(words)

    local spellfile = get_spellfile_path()
    ensure_spellfile(spellfile)
    local appended = append_unique_words(spellfile, words)

    local client = get_ltex_client(vim.api.nvim_get_current_buf())
    if client then
      local settings = client.config.settings or {}
      settings.ltex = settings.ltex or {}
      settings.ltex.dictionary = settings.ltex.dictionary or {}
      settings.ltex.dictionary[lang] = vim.list_extend(settings.ltex.dictionary[lang] or {}, words)
      client.config.settings = settings
      client:notify("workspace/didChangeConfiguration", settings)
    end

    vim.notify(string.format("LTEX: added %d word(s) to %s", #appended, vim.fn.fnamemodify(spellfile, ":~")))
  end
end

return {
  "barreiroleo/ltex_extra.nvim",
  ft = { "markdown", "text", "gitcommit", "org", "norg", "rst", "tex" },
  dependencies = { "neovim/nvim-lspconfig" },
  config = function()
    local ltex_language = spelllang_to_ltex_language(get_default_spelllang())
    local spellfile = get_spellfile_path()

    require("ltex_extra").setup({
      load_langs = { ltex_language },
      init_check = false,
      path = vim.fs.dirname(spellfile),
      log_level = "none",
    })

    register_ltex_dictionary_handler(ltex_language)

    vim.api.nvim_create_autocmd("LspAttach", {
      group = vim.api.nvim_create_augroup("ltex-extra-attach", { clear = true }),
      callback = function(args)
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        if not client or (client.name ~= "ltex_plus" and client.name ~= "ltex") then
          return
        end
        require("ltex_extra").reload({ ltex_language })
      end,
    })
  end,
}
