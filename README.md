---

# 🌲 Otree.nvim

**Otree.nvim** is a lightweight and customizable file tree explorer for [Neovim](https://neovim.io), built for speed, simplicity, and seamless user experience. It integrates tightly with [`oil.nvim`](https://github.com/stevearc/oil.nvim) and [`nvim-web-devicons`](https://github.com/nvim-tree/nvim-web-devicons) to provide an elegant and efficient file navigation workflow.

---

## ✨ Features

- **Fast and responsive** file tree using `fd` or `fdfind`
- **Tight integration** with [`oil.nvim`](https://github.com/stevearc/oil.nvim) for file operations
- **Highly customizable** keybindings and appearance
- **Optional Netrw hijack** for a cleaner startup experience
- **Toggle visibility** for hidden and ignored files
- **Floating window support** with adjustable dimensions
- **Simple API and commands** for ease of use

---

## ⚙️ Requirements

- [Neovim 0.8+](https://neovim.io)
- [`fd`](https://github.com/sharkdp/fd) or [`fdfind`](https://manpages.ubuntu.com/manpages/focal/man1/fdfind.1.html)
- [`nvim-web-devicons`](https://github.com/nvim-tree/nvim-web-devicons)
- [`oil.nvim`](https://github.com/stevearc/oil.nvim)

---

## 📦 Installation

Using [`lazy.nvim`](https://github.com/folke/lazy.nvim):

```lua
return {
  "Eutrius/Otree.nvim",
  lazy = false,
  dependencies = {
    "nvim-tree/nvim-web-devicons",
    "stevearc/oil.nvim",
  },
  config = function()
    require("Otree").setup()
  end
}
```

---

## ⚙️ Configuration

Here is the default configuration, which can be customized to suit your preferences:

```lua
require("Otree").setup({
  win_size = 27,
  open_on_startup = false,
  hijack_netrw = true,
  show_hidden = false,
  show_ignore = false,
  cursorline = true,

  ignore_patterns = {},

  keymaps = {
    ["<CR>"] = "actions.on_enter",
    ["l"] = "actions.on_enter",
    ["h"] = "actions.on_close_dir",
    ["q"] = "actions.close_win",
    ["<C-h>"] = "actions.goto_parent",
    ["<C-l>"] = "actions.goto_dir",
    ["<M-H>"] = "actions.goto_pwd",
    ["cd"] = "actions.change_pwd",
    ["L"] = "actions.open_dirs",
    ["H"] = "actions.close_dirs",
    ["o"] = "actions.edit_dir",
    ["st"] = "actions.open_tab",
    ["sv"] = "actions.open_vsplit",
    ["ss"] = "actions.open_split",
    ["s."] = "actions.toggle_hidden",
    ["si"] = "actions.toggle_ignore",
    ["r"] = "actions.refresh",
    ["sf"] = "actions.focus_file",
  },

  tree = {
    connector_last = "└─",
    connector_middle = "├─",
    vertical_line = "│",
    spacing = "  ",
  },

  icons = {
    title = " ",
    directory = "",
    empty_dir = "",
  },

  highlights = {
    directory = "Directory",
    file = "Normal",
    title = "TelescopeTitle",
    tree = "Comment",
    normal = "Normal",
    float_normal = "TelescopeNormal",
    float_border = "TelescopeBorder",
  },

  float = {
    width_ratio = 0.4,
    height_ratio = 0.7,
    padding = 2,
    cursorline = true,
  },
})
```

---

## 🗝️ Keybindings

| Keybinding  | Action                          |
| ----------- | ------------------------------- |
| `<CR>`, `l` | Open file or expand folder      |
| `h`         | Collapse folder                 |
| `q`         | Close file tree window          |
| `<C-h>`     | Navigate to parent directory    |
| `<C-l>`     | Enter selected directory        |
| `<M-H>`     | Go to current working directory |
| `cd`        | Change working directory        |
| `L`         | Expand all directories          |
| `H`         | Collapse all directories        |
| `o`         | Open selected directory in Oil  |
| `st`        | Open file in new tab            |
| `sv`        | Open file in vertical split     |
| `ss`        | Open file in horizontal split   |
| `s.`        | Toggle hidden files visibility  |
| `si`        | Toggle ignored files visibility |
| `r`         | Refresh tree view               |
| `sf`        | Focus on currently open file    |

---

## 🧪 User Commands

| Command       | Description                 |
| ------------- | --------------------------- |
| `:Otree`      | Toggle the file tree window |
| `:OtreeFocus` | Focus the file tree window  |

---

## 🔧 Netrw Hijack

When `hijack_netrw = true`, **Otree** automatically launches:

- When Neovim is opened without a specific file
- When opened in a directory (`nvim .`, `nvim ..`, etc.)
- As a full replacement for Netrw

---

## 🛠 Oil.nvim Integration

**Otree** utilizes `oil.nvim` for file operations. When both plugins are installed, a compatible default configuration for `oil.nvim` is applied automatically:

```lua
require("oil").setup({
  use_default_keymaps = false,
  skip_confirm_for_simple_edits = true,
  delete_to_trash = true,
  cleanup_delay_ms = 100,
  default_file_explorer = false,
  keymaps = {
    ["st"] = { "actions.toggle_trash", mode = "n" },
  },
  confirmation = {
    max_width = 0.9,
    min_width = { 30 },
  },
})
```

---

## 🧰 Troubleshooting

- **Missing icons?**
  Ensure `nvim-web-devicons` is installed and properly configured.

- **Tree doesn't open on startup?**
  Set `open_on_startup = true` in your setup.

- **Tree not showing for directories?**
  Enable `hijack_netrw = true`.

- **Command not found: `fd`?**
  Install [`fd`](https://github.com/sharkdp/fd) or its Debian/Ubuntu alias `fdfind`, and ensure it's in your system `$PATH`.

---
