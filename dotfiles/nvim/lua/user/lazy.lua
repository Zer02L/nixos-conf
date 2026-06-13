-- lazy.nvim plugin manager

local PluginSpec = {
  -- colorscheme
  { "ellisonleao/gruvbox.nvim", version = false, opts = { terminal_colors = true } },

  -- essential
  { "folke/which-key.nvim",     opts = { icons = { mappings = false } }, event = "UiEnter" },
  { "folke/lazy.nvim",          version = false },

  -- completion (blink.cmp вместо nvim-cmp + LuaSnip)
  {
    "saghen/blink.cmp",
    dependencies = "rafamadriz/friendly-snippets",
    version = "*",
    event = "InsertEnter",
    opts = {
      keymap = { preset = "default" },
      appearance = {
        use_nvim_cmp_as_default = true,
        nerd_font_variant = "mono",
      },
      sources = {
        default = { "lsp", "path", "snippets", "buffer" },
      },
    },
  },

  -- fuzzy finder (fzf-lua вместо telescope) — ищет от корня проекта
  {
    "ibhagwan/fzf-lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {},
  },

  -- treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.config").setup({
        ensure_installed = {
          "lua", "vim", "vimdoc", "query",
          "nix", "python", "rust", "go", "zig",
          "javascript", "typescript", "html", "css", "vue",
          "json", "yaml", "toml",
          "bash", "fish", "c", "cpp",
          "markdown", "markdown_inline",
        },
        auto_install = true,
        highlight = { enable = true },
        indent = { enable = true },
      })
    end,
  },

  -- LSP
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "saghen/blink.cmp",
    },
    config = function()
      local capabilities = require("blink.cmp").get_lsp_capabilities()
      vim.lsp.config["*"] = { capabilities = capabilities }

      -- Серверы установлены через Nix (systemPackages) — просто включаем
      vim.lsp.enable("lua_ls")
      vim.lsp.config.nil_ls = {
        settings = {
          ["nil"] = {
            autoArchive = true,
          },
        },
      }
      vim.lsp.enable("nil_ls")
      vim.lsp.enable("pyright")
      vim.lsp.enable("ruff")
      vim.lsp.enable("rust_analyzer")
      vim.lsp.enable("gopls")
      vim.lsp.enable("ts_ls")
      vim.lsp.enable("volar")          -- Vue 3 LSP
      vim.lsp.enable("tailwindcss")    -- автодополнение CSS-классов (Tailwind/UnoCSS)
      vim.lsp.enable("yamlls")
    end,
  },

  -- mini.nvim — замена autopairs
  {
    "echasnovski/mini.pairs",
    version = false,
    config = function()
      require("mini.pairs").setup()
    end,
  },

  -- mini.nvim — замена Comment.nvim
  {
    "echasnovski/mini.comment",
    version = false,
    config = function()
      require("mini.comment").setup()
    end,
  },

  -- mini.nvim — замена nvim-surround
  {
    "echasnovski/mini.surround",
    version = false,
    config = function()
      require("mini.surround").setup()
    end,
  },

  -- mini.nvim — замена indent-blankline
  {
    "echasnovski/mini.indentscope",
    version = false,
    config = function()
      require("mini.indentscope").setup()
    end,
  },

  -- mini.nvim — замена nvim-web-devicons (для плагинов без явной поддержки)
  {
    "echasnovski/mini.icons",
    version = false,
    config = function()
      require("mini.icons").setup()
    end,
  },

  -- mini.nvim — новый (подсветка хвостовых пробелов)
  {
    "echasnovski/mini.trailspace",
    version = false,
    config = function()
      require("mini.trailspace").setup()
    end,
  },

  -- statusline
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      options = {
        theme = "gruvbox",
        component_separators = "|",
        section_separators = "",
      },
    },
  },

  -- автоформатирование при сохранении
  {
    "stevearc/conform.nvim",
    event = "BufWritePre",
    opts = {
      formatters_by_ft = {
        lua = { "stylua" },
        vue = { "prettier" },
        javascript = { "oxfmt", "prettier", stop_after_first = true },
        typescript = { "oxfmt", "prettier", stop_after_first = true },
        typescriptreact = { "oxfmt", "prettier", stop_after_first = true },
        python = { "ruff_fix", "ruff_format" },
        go = { "gofmt" },
        nix = { "nixfmt" },
        rust = { "rustfmt", lsp_format = "fallback" },
      },
      format_on_save = { timeout_ms = 500, lsp_fallback = true },
    },
  },


  -- dashboard: mini.starter
  {
    "echasnovski/mini.starter",
    version = false,
    config = function()
      local starter = require("mini.starter")
      starter.setup({
        autoopen = true,
        evaluate_single = true,
        header = table.concat({
          "",
          "╻ ╻┏━┓╻  ┏━┓┏━┓┏━╸╻  ╻",
          "┃ ┃┣━┫┃  ┃ ┃┣━┫┣╸ ┃  ┃",
          "┗━┛╹ ╹┗━╸┗━┛╹ ╹╹  ┗━╸╹",
          "",
        }, "\n"),
        items = {
          starter.sections.recent_files(10, false),
          {
            { name = "Find File", action = function() require("fzf-lua").files() end,        section = "Actions" },
            { name = "Find Text", action = function() require("fzf-lua").live_grep() end,    section = "Actions" },
            { name = "Buffers",   action = function() require("fzf-lua").buffers() end,      section = "Actions" },
          },
          starter.sections.builtin_actions(),
        },
        content_hooks = {
          starter.gen_hook.adding_bullet(nil, false),
          function(content)
            local icon = { Actions = "", ["Builtin actions"] = "", ["Recent files"] = "" }
            for _, line in ipairs(content) do
              for _, unit in ipairs(line) do
                if unit.type == "item_bullet" and unit._item then
                  unit.string = (icon[unit._item.section] or "·") .. " "
                end
              end
            end
            return content
          end,
          starter.gen_hook.aligning("center", "center"),
        },
      })
    end,
  },

}

-- gitsigns (оставляем — mini.git поверхностный)
local ft_plugins = {
  { "lewis6991/gitsigns.nvim", opts = {} },
}

vim.list_extend(PluginSpec, ft_plugins)

require("lazy").setup(PluginSpec, {
  install = { colorscheme = { "gruvbox" } },
  checker = { enabled = true, notify = false },
  change_detection = { notify = false },
})

vim.cmd("colorscheme gruvbox")

