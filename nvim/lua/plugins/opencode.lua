return {
  "nickjvandyke/opencode.nvim",
  version = "*",
  keys = {
    {
      "<leader>oa",
      function()
        require("opencode").ask("@this: ", { submit = true })
      end,
      mode = { "n", "x" },
      desc = "Ask opencode",
    },
    {
      "<leader>oo",
      function()
        require("opencode").select()
      end,
      mode = { "n", "x" },
      desc = "Open opencode actions",
    },
    {
      "<leader>ot",
      function()
        require("opencode").toggle()
      end,
      mode = { "n", "t" },
      desc = "Toggle opencode",
    },
    {
      "<leader>oc",
      function()
        vim.ui.input({ prompt = "Opencode command: " }, function(input)
          if not input or input == "" then
            return
          end
          require("opencode").command(input)
        end)
      end,
      mode = "n",
      desc = "Run opencode command",
    },
  },
  init = function()
    vim.o.autoread = true
    vim.g.opencode_opts = vim.tbl_deep_extend("force", vim.g.opencode_opts or {}, {
      provider = {
        enabled = "snacks",
      },
      lsp = {
        enabled = true,
        handlers = {
          hover = {
            enabled = false,
          },
          code_action = {
            enabled = true,
          },
        },
      },
    })

    vim.api.nvim_create_user_command("Opencode", function(args)
      require("opencode").command(args.args)
    end, {
      nargs = 1,
      complete = function()
        return {
          "session.list",
          "session.new",
          "session.select",
          "session.share",
          "session.interrupt",
          "session.compact",
          "session.page.up",
          "session.page.down",
          "session.half.page.up",
          "session.half.page.down",
          "session.first",
          "session.last",
          "session.undo",
          "session.redo",
          "prompt.submit",
          "prompt.clear",
          "agent.cycle",
        }
      end,
      desc = "Run an opencode command",
    })
  end,
  dependencies = {
    {
      "folke/snacks.nvim",
      optional = true,
      opts = function(_, opts)
        opts.input = opts.input or {}
        opts.terminal = opts.terminal or {}
        opts.picker = opts.picker or {}
        opts.picker.actions = opts.picker.actions or {}
        opts.picker.actions.opencode_send = function(...)
          return require("opencode").snacks_picker_send(...)
        end
        opts.picker.win = opts.picker.win or {}
        opts.picker.win.input = opts.picker.win.input or {}
        opts.picker.win.input.keys = vim.tbl_deep_extend("force", opts.picker.win.input.keys or {}, {
          ["<a-a>"] = { "opencode_send", mode = { "n", "i" } },
        })
      end,
    },
  },
}
