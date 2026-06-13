-- keymaps

local map = vim.keymap.set
local opts = { noremap = true, silent = true }

-- better escape
map("i", "jj", "<Esc>", opts)
map("i", "jk", "<Esc>", opts)

-- save / quit
map("n", "<leader>w", "<cmd>w<CR>", { noremap = true, silent = true, desc = " Save" })
map("n", "<leader>q", "<cmd>q<CR>", { noremap = true, silent = true, desc = " Close window" })
map("n", "<leader>Q", "<cmd>qa!<CR>", { noremap = true, silent = true, desc = " Quit all (force)" })

-- general toggles
map("n", "<leader>n", "<cmd>set relativenumber!<CR>",
  { desc = " Toggle relativenumber", silent = true })

-- save from any mode
map({ "n", "v" }, "<C-s>", "<cmd>w<CR>",
  { desc = " Save", silent = true })
map("i", "<C-s>", "<C-\\><C-o>:w<CR>",
  { desc = " Save", silent = true })

-- open file / directory under cursor
map("n", "gd", "<cmd>FzfLua lsp_definitions<cr>", opts)
map("n", "gf", "<cmd>e <cfile><CR>", { desc = " Open file", silent = true })

-- open current file directory
map("n", "<leader>d", "<cmd>e %:p:h<CR>", { desc = " Open file directory", silent = true })

-- create file / directory
map("n", "<leader>fn", function()
  local name = vim.fn.input("New file: ")
  if name ~= "" then vim.cmd("e " .. name) end
end, { noremap = true, silent = true, desc = " New file" })
map("n", "<leader>fd", function()
  local name = vim.fn.input("New directory: ")
  if name ~= "" then vim.fn.mkdir(name, "p") end
end, { noremap = true, silent = true, desc = " New directory" })

-- clear search highlight
map("n", "<Esc>", "<cmd>nohlsearch<CR>", opts)

-- move lines
map("v", "J", ":m '>+1<CR>gv=gv", opts)
map("v", "K", ":m '<-2<CR>gv=gv", opts)

-- better indentation
map("v", "<", "<gv", opts)
map("v", ">", ">gv", opts)

-- system clipboard
map("v", "<C-c>", '"+y', { desc = " Copy to clipboard", silent = true })

-- keep cursor centered
map("n", "n", "nzzzv", opts)
map("n", "N", "Nzzzv", opts)
map("n", "*", "*zzzv", opts)
map("n", "#", "#zzzv", opts)
map("n", "J", "mzJ`z", opts)

-- undo break points
map("i", ",", ",<C-g>u", opts)
map("i", ".", ".<C-g>u", opts)
map("i", "!", "!<C-g>u", opts)
map("i", "?", "?<C-g>u", opts)

-- quickfix
map("n", "]q", "<cmd>cnext<CR>", opts)
map("n", "[q", "<cmd>cprev<CR>", opts)
map("n", "]l", "<cmd>lnext<CR>", opts)
map("n", "[l", "<cmd>lprev<CR>", opts)

-- buffer navigation
map("n", "<Tab>", "<cmd>bnext<CR>", opts)
map("n", "<S-Tab>", "<cmd>bprev<CR>", opts)
map("n", "<leader>bd", "<cmd>bdelete<CR>", { noremap = true, silent = true, desc = " Delete buffer" })
map("n", "<leader>x", "<cmd>bdelete<CR>",
  { desc = " Close buffer", silent = true })

-- better window navigation
map("n", "<C-h>", "<C-w>h", opts)
map("n", "<C-j>", "<C-w>j", opts)
map("n", "<C-k>", "<C-w>k", opts)
map("n", "<C-l>", "<C-w>l", opts)

-- resize windows
map("n", "<C-Up>", "<cmd>resize +2<CR>", opts)
map("n", "<C-Down>", "<cmd>resize -2<CR>", opts)
map("n", "<C-Left>", "<cmd>vertical resize -2<CR>", opts)
map("n", "<C-Right>", "<cmd>vertical resize +2<CR>", opts)

-- terminal
map("n", "<leader>th", "<cmd>split | terminal<CR>",
  { desc = " Horizontal terminal", silent = true })
map("n", "<leader>tv", "<cmd>vsplit | terminal<CR>",
  { desc = " Vertical terminal", silent = true })

-- fzf-lua (от корня проекта)
local function project_root()
  local dir = vim.fn.expand("%:p:h")
  if dir == "" then dir = vim.fn.getcwd() end
  local git_dir = vim.fn.finddir(".git", dir .. ";")
  if git_dir ~= "" then
    return vim.fn.fnamemodify(git_dir, ":h")
  end
  return dir
end

map("n", "<leader>ff", function() require("fzf-lua").files({ cwd = project_root() }) end,
  { noremap = true, silent = true, desc = " Find files" })
map("n", "<leader>fg", function() require("fzf-lua").live_grep({ cwd = project_root() }) end,
  { noremap = true, silent = true, desc = " Live grep" })
map("n", "<leader>fb", "<cmd>FzfLua buffers<cr>", { noremap = true, silent = true, desc = " Buffers" })
map("n", "<leader>fh", "<cmd>FzfLua help_tags<cr>", { noremap = true, silent = true, desc = " Help tags" })
map("n", "<leader>fs", function() require("fzf-lua").grep({ cwd = project_root() }) end,
  { noremap = true, silent = true, desc = " Search" })
map("n", "<leader>fw", function() require("fzf-lua").live_grep({ cwd = project_root() }) end,
  { desc = " Live grep (NvChad style)", silent = true })
map("n", "<leader>fo", function() require("fzf-lua").oldfiles() end,
  { desc = " Recent files", silent = true })
map("n", "<leader>fz", "<cmd>FzfLua grep_curbuf<CR>",
  { desc = " Search in file", silent = true })

-- lsp
map("n", "gr", "<cmd>FzfLua lsp_references<cr>", opts)
map("n", "gi", "<cmd>FzfLua lsp_implementations<cr>", opts)
map("n", "K", vim.lsp.buf.hover, opts)
map("n", "<leader>rn", vim.lsp.buf.rename, { noremap = true, silent = true, desc = " Rename symbol" })
map("n", "<leader>ca", vim.lsp.buf.code_action, { noremap = true, silent = true, desc = " Code actions" })
map("n", "<leader>D", "<cmd>FzfLua lsp_type_definitions<cr>", { noremap = true, silent = true, desc = " Type definition" })
map("n", "df", vim.diagnostic.open_float, { noremap = true, silent = true, desc = " Diagnostic float" })
map("n", "gD", "<cmd>FzfLua lsp_declarations<CR>",
  { desc = " Go to declaration", silent = true })
map("n", "<leader>ra", vim.lsp.buf.rename,
  { desc = " Rename symbol (alias)", silent = true })
map("n", "<leader>fm", function()
  vim.lsp.buf.format({ async = false })
end, { desc = " Format code", silent = true })

-- Lazygit в плавающем терминале
local function float_term(cmd, opts)
  opts = opts or {}
  local width = math.floor(vim.o.columns * (opts.width or 0.85))
  local height = math.floor(vim.o.lines * (opts.height or 0.8))
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  local buf = vim.api.nvim_create_buf(false, true)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = opts.border or "rounded",
    title = opts.title or cmd,
    title_pos = "center",
  })
  vim.fn.termopen(cmd, { cwd = opts.cwd or vim.fn.expand("%:p:h") })
  vim.cmd("startinsert")
end

map("n", "<leader>gg", function() float_term("lazygit", { title = " Lazygit " }) end,
  { noremap = true, silent = true, desc = "Lazygit" })
-- Yazi: общая функция открытия в nvim через chooser-file
local function yazi_open(dir)
  local tmpfile = vim.fn.tempname()
  local cmd = "yazi --chooser-file=" .. tmpfile

  local width = math.floor(vim.o.columns * 0.7)
  local height = math.floor(vim.o.lines * 0.8)
  local buf = vim.api.nvim_create_buf(false, true)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    style = "minimal",
    border = "rounded",
    title = " Yazi ",
    title_pos = "center",
  })

  local cwd = vim.fn.getcwd()
  if dir and dir ~= "" then
    local expanded = vim.fn.fnamemodify(vim.fn.expand(dir), ":p")
    if expanded ~= "" and vim.fn.isdirectory(expanded) == 1 then
      cwd = expanded
    end
  end

  vim.fn.termopen(cmd, {
    cwd = cwd,
    on_exit = function()
      pcall(vim.api.nvim_win_close, win, true)
      vim.defer_fn(function()
        local ok, file = pcall(vim.fn.readfile, tmpfile)
        if ok and file and #file > 0 then
          vim.cmd("edit " .. vim.fn.fnameescape(file[1]))
        end
        pcall(os.remove, tmpfile)
      end, 50)
    end,
  })
  vim.cmd("startinsert")
end

map("n", "<leader>y", function() yazi_open() end,
  { noremap = true, silent = true, desc = "Yazi (open in nvim)" })

vim.api.nvim_create_user_command("Yazi", function(opts)
  yazi_open(opts.args ~= "" and opts.args or nil)
end, { nargs = "?" })
map("n", "[d", vim.diagnostic.goto_prev, opts)
map("n", "]d", vim.diagnostic.goto_next, opts)

-- PostgreSQL / dadbod
map("n", "<leader>db", "<cmd>DBUI<CR>", { desc = " DB UI" })
map("n", "<leader>dq", "<cmd>DB<CR>",   { desc = " DB query" })