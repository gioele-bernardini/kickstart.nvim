local M = {}

-- XXX: Change this variables according to the project!
local BUILD_CMD = 'make all'
local CLEAN_CMD = 'make clean'
local FLASH_CMD = 'make flash'

function M.setup()
  -- Initialize cortex-debug and dap plugins
  local cortex = require('dap-cortex-debug')
  cortex.setup({})
  local dap = require('dap')

  -- Get the path for the .elf executable
  local cur_path = vim.fn.getcwd()
  local elf_path =
      cur_path .. '/build/' ..
      vim.fn.fnamemodify(cur_path, ':t') .. '.elf'

  -- Build: Asyncronous job and quickfix list
  vim.keymap.set(
    'n', '<leader><leader>',
    function()
      local stderr_lines = {}

      local n_dots = 0
      local timer = vim.uv.new_timer()
      timer:start(0, 500, vim.schedule_wrap(function()
        vim.notify('Building' .. string.rep('.', n_dots), vim.log.levels.INFO)
        n_dots = (n_dots + 1) % 4
      end))

      vim.fn.jobstart(BUILD_CMD, {
        on_stderr = function(_, data, _)
          vim.list_extend(stderr_lines, data)
        end,

        on_exit = function(_, exit_code, _)
          vim.schedule(function()
            timer:stop()
            timer:close()
            if exit_code == 0 then
              vim.notify('Build completed!', vim.log.levels.INFO)
            else
              vim.fn.setqflist({}, 'r', { lines = stderr_lines })
              vim.cmd('copen')
              vim.notify('Build failed!', vim.log.levels.ERROR)
            end
          end)
        end,
      })
    end,
    { noremap = true, silent = true, desc = 'Build: compile (Infineon)' }
  )

  -- Clean
  vim.keymap.set(
    'n', '<leader>k',
    function()
      vim.fn.jobstart(CLEAN_CMD, {
        on_exit = function(_, exit_code, _)
          vim.schedule(function()
            if exit_code == 0 then
              vim.notify('Clean completed!', vim.log.levels.INFO)
            else
              vim.notify('Clean failed!', vim.log.levels.ERROR)
            end
          end)
        end,
      })
    end,
    { noremap = true, silent = true, desc = 'Build: clean' }
  )

  -- Flash: Asyncronous job and quickfix list
  vim.keymap.set(
    'n', '<leader>df',
    function()
      local stderr_lines = {}

      local n_dots = 0
      local timer = vim.uv.new_timer()
      timer:start(0, 500, vim.schedule_wrap(function()
        vim.notify('Flashing' .. string.rep('.', n_dots), vim.log.levels.INFO)
        n_dots = (n_dots + 1) % 4
      end))

      vim.fn.jobstart(FLASH_CMD, {
        on_stderr = function(_, data, _)
          vim.list_extend(stderr_lines, data)
        end,

        on_exit = function(_, exit_code, _)
          vim.schedule(function()
            timer:stop()
            timer:close()
            if exit_code == 0 then
              vim.notify('Flash completed!', vim.log.levels.INFO)
            else
              vim.fn.setqflist({}, 'r', { lines = stderr_lines })
              vim.cmd('copen')
              vim.cmd('wincmd p')
              vim.notify('Flash failed!', vim.log.levels.ERROR)
            end
          end)
        end,
      })
    end,
    { noremap = true, silent = true, desc = 'Flash device' }
  )
end

return M
