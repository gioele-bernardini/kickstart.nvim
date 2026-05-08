return {
  {
    'stevearc/oil.nvim',
    lazy = false,
    cmd = { 'Oil' },
    dependencies = { 'nvim-tree/nvim-web-devicons' },

    keys = {
      { '-',          '<cmd>Oil --float<cr>', desc = 'Open Oil (float)' },
      { '<leader>so', '<cmd>Oil --float<cr>', desc = 'Open Oil (float)' },
    },
    opts = {
      default_file_explorer = true,
      -- delete_to_trash = true,
      skip_confirm_for_simple_edits = true,
      prompt_save_on_select_new_entry = true,
      cleanup_delay_ms = 2000,
      constrain_cursor = 'editable',

      columns = {
        'icon',
        -- 'permissions',
        -- 'size',
        -- 'mtime',
      },

      win_options = {
        wrap = false,
        signcolumn = 'no',
        cursorcolumn = false,
        foldcolumn = '0',
        spell = false,
        list = false,
        conceallevel = 3,
        concealcursor = 'nvic',
      },

      view_options = {
        show_hidden = true,
        natural_order = 'fast',
        case_insensitive = false,

        sort = {
          { 'type', 'asc' },
          { 'name', 'asc' },
        },

        is_hidden_file = function(name, _)
          return vim.startswith(name, '.')
        end,

        is_always_hidden = function(name, _)
          local always = {
            ['.git'] = true,
          }
          return always[name] or false
        end,
      },

      float = {
        padding = 1,
        max_width = 0.75,
        max_height = 0.80,
        border = 'rounded',
        preview_split = 'right',
        win_options = {
          winblend = 0,
        },
        get_win_title = function()
          return ''
        end,
        override = function(conf)
          conf.title = nil
          conf.title_pos = nil
          return conf
        end,
      },

      preview_win = {
        update_on_cursor_moved = true,
        preview_method = 'fast_scratch',
        border = 'rounded',
        win_options = {
          winblend = 0,
        },
      },

      confirmation = {
        border = 'rounded',
        win_options = {
          winblend = 0,
          winbar = ""
        },
      },

      progress = {
        border = 'rounded',
        minimized_border = 'rounded',
        win_options = {
          winblend = 0,
        },
      },

      ssh = {
        border = 'rounded',
      },

      keymaps_help = {
        border = 'rounded',
      },

      keymaps = {
        ['<CR>'] = 'actions.select',
        ['<C-v>'] = { 'actions.select', opts = { vertical = true }, desc = 'Open in vertical split' },
        ['<C-s>'] = { 'actions.select', opts = { horizontal = true }, desc = 'Open in horizontal split' },
        ['<C-t>'] = { 'actions.select', opts = { tab = true }, desc = 'Open in new tab' },

        ['<C-p>'] = 'actions.preview',
        ['<C-d>'] = 'actions.preview_scroll_down',
        ['<C-u>'] = 'actions.preview_scroll_up',

        ['<Esc>'] = { 'actions.close', mode = 'n', desc = 'Close Oil' },
        ['q'] = { 'actions.close', mode = 'n', desc = 'Close Oil' },

        ['g.'] = { 'actions.toggle_hidden', mode = 'n', desc = 'Toggle hidden files' },
        ['gs'] = { 'actions.change_sort', mode = 'n', desc = 'Change sort' },
        ['gx'] = 'actions.open_external',

        ['-'] = { 'actions.parent', mode = 'n' },
        ['_'] = { 'actions.open_cwd', mode = 'n' },
        ['`'] = { 'actions.cd', mode = 'n' },
        ['~'] = { 'actions.cd', opts = { scope = 'tab' }, mode = 'n' },
      }
    },

    config = function(_, opts)
      local oil = require('oil')
      oil.setup(opts)

      vim.opt.winborder = 'rounded'

      vim.keymap.set('n', 'K', function()
        vim.lsp.buf.hover({ border = 'rounded' })
      end, { desc = 'LSP Hover' })

      vim.keymap.set('n', '<leader>vd', function()
        vim.diagnostic.open_float({ border = 'rounded' })
      end, { desc = 'Line diagnostics' })
    end,
  },
  {
    'rmagatti/auto-session',
    lazy = false,
    opts = {
      auto_save = false,
      auto_restore = false,
      suppressed_dirs = { '~/', '~/Downloads', '~/Desktop' },
    },
    keys = {
      { '<leader>ws', '<cmd>AutoSession save<cr>',    desc = 'Save session' },
      { '<leader>wd', '<cmd>AutoSession delete<cr>',  desc = 'Discard session' },
      { '<leader>wl', '<cmd>AutoSession restore<cr>', desc = 'Restore session' },
    },
  },
  {
    'Weissle/persistent-breakpoints.nvim',
    opts = {
      load_breakpoints_event = { 'BufReadPost' },
    },
  },
}
