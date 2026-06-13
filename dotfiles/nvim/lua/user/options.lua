-- options

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.signcolumn = "yes"
vim.opt.cursorline = true

vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.wrap = false

vim.opt.background = "dark"

vim.opt.undofile = true
vim.opt.backup = false
vim.opt.writebackup = false
vim.opt.swapfile = false
vim.opt.hidden = true

vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.hlsearch = true
vim.opt.incsearch = true

vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.timeoutlen = 300
vim.opt.updatetime = 200
vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 8

vim.opt.completeopt = "menuone,noselect"

vim.opt.shortmess:append("c")
vim.opt.list = true
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- визуальный комфорт
vim.opt.winbar = "%{v:lua.vim.fn.expand('%:p')}"

-- отключаем treesitter/LSP на больших файлах (>1MB)
vim.api.nvim_create_autocmd("BufReadPre", {
  callback = function()
    if vim.fn.getfsize(vim.fn.expand("%")) > 1048576 then
      vim.b.ts_highlight = false
      vim.b.lsp_attach_disable = true
      vim.b.miniindentscope_disable = true
      vim.opt_local.syntax = "sync minlines=1"
    end
  end,
})

-- простая обёртка vim.notify — цветной echo вместо плагина
vim.notify = function(msg, level, _)
  local hl = (level == vim.log.levels.ERROR and "ErrorMsg")
    or (level == vim.log.levels.WARN and "WarningMsg")
    or "Title"
  vim.api.nvim_echo({ { msg, hl } }, true, {})
end
