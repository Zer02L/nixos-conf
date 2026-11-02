# Neovim Cheatsheet

## Режимы и Esc

| Key | Action |
|---|---|
| `jj` / `jk` | Esc (insert mode) |
| `<Esc>` | Clear search highlight |
| `<leader>n` | Toggle relativenumber |

## Файловые операции

| Key | Action |
|---|---|
| `<leader>w` | Save |
| `<C-s>` | Save (Normal / Insert / Visual) |
| `<leader>q` | Close window (`:q`) |
| `<leader>x` | Close buffer (`:bdelete`, alias) |
| `<leader>bd` | Delete buffer |
| `<leader>Q` | Quit all (force) |
| `<leader>fn` | New file (prompt filename) |
| `<leader>fd` | New directory (prompt dirname) |
| `<leader>fm` | Format code (LSP format) |

## Навигация

| Key | Action |
|---|---|
| `gf` | Open file под курсором |
| `<leader>d` | Открыть папку текущего файла |

## Буферы / Окна

| Key | Action |
|---|---|
| `<Tab>` | Next buffer |
| `<S-Tab>` | Previous buffer |
| `<C-h/j/k/l>` | Navigate windows |
| `<C-Up/Down>` | Resize horizontal (±2) |
| `<C-Left/Right>` | Resize vertical (±2) |

## FzfLua (поиск)

| Key | Action |
|---|---|
| `<leader>ff` | Find files |
| `<leader>fg` | Live grep (по тексту) |
| `<leader>fw` | Live grep (алиас NvChad-стиль) |
| `<leader>fs` | Grep (сначала ввести паттерн) |
| `<leader>fz` | Поиск слова в текущем файле |
| `<leader>fb` | Buffers |
| `<leader>fh` | Help tags |
| `<leader>fo` | Recent files (oldfiles) |

## LSP

| Key | Action |
|---|---|
| `gd` | Go to definition |
| `gD` | Go to declaration |
| `gr` | Find references |
| `gi` | Go to implementation |
| `K` | Hover (документация / тип) |
| `<leader>rn` | Rename symbol |
| `<leader>ra` | Rename symbol (алиас) |
| `<leader>ca` | Code actions |
| `<leader>D` | Go to type definition |
| `df` | Diagnostic float |
| `[d` | Previous diagnostic |
| `]d` | Next diagnostic |

## Редактирование

| Key | Action |
|---|---|
| `J` / `K` (visual) | Move line up/down |
| `<` / `>` (visual) | Indent / dedent |
| `n` / `N` | Next/prev search (центрирует) |
| `*` / `#` | Search word under cursor |
| `,` / `.` / `!` / `?` | Undo break point (insert) |
| `<C-c>` (visual) | Копировать в системный буфер (`"+y`) |
| `gcc` | Закомментировать / раскомментировать строку |
| `gc` (visual) | Комментировать выделенный блок |

### Quickfix / Location

| Key | Action |
|---|---|
| `]q` / `[q` | Quickfix next/prev |
| `]l` / `[l` | Location list next/prev |

## Терминал

| Key | Action |
|---|---|
| `<leader>th` | Новый терминал (горизонтальный сплит) |
| `<leader>tv` | Новый терминал (вертикальный сплит) |

## Lazygit

| Key | Action |
|---|---|
| `<leader>gg` | Lazygit (плавающее окно) |

## Yazi (файловый менеджер)

| Key | Action |
|---|---|
| `<leader>y` | Yazi (открыть в nvim через chooser-file) |

## mini.starter (Dashboard)

Появляется при `nvim` без аргументов.

| Key | Action |
|---|---|
| `j` / `k` | Move between items |
| `Enter` | Open selected item |
| `Ctrl-c` / `q` | Close starter |

Секции: **Recent files** (последние 10), **Actions** (Find File, Find Text, Buffers), **Builtin actions**.
Навигация по первой букве секции (например `r` → Recent files).

## Форматирование (conform.nvim)

Автоматически при сохранении:

- Lua → `stylua`
- JS/TS → `biome` / `prettier`
- Python → `ruff`
- Go → `gofmt`
- Nix → `nixfmt`
- Rust → `rustfmt`

Ручной вызов: `<leader>fm`

## Oil (файловый браузер)

Открыть директорию: `nvim .` или `:Oil`.

| Key | Action |
|---|---|
| `a` | Create file/dir (с `/` в конце — папка) |
| `r` | Rename |
| `d` | Delete |
| `~` | Home dir |
| `q` | Close Oil |

---

Собрано из `~/.config/nvim/lua/user/keymaps.lua`
