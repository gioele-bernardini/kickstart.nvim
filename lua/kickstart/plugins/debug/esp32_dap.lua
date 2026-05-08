local M = {}

M.config = {
  build_cmd = 'idf.py build',

  -- NOTE: export.sh from esp32 must be exported!
  openocd_bin = 'openocd',

  openocd_cfg = 'board/esp32s3-ftdi.cfg',

  openocd_gdb_port = 3333,
  openocd_timeout_sec = 20,

  gdb = vim.fn.exepath 'xtensa-esp32s3-elf-gdb',

  elf = function()
    local cwd = vim.fn.getcwd()
    return cwd .. '/build/default/' .. vim.fn.fnamemodify(cwd, ':t') .. '.elf'
  end,
}

local _openocd_job = nil
local _openocd_ready = false
local _openocd_timer = nil

local function notify(msg, level)
  vim.schedule(function() vim.notify('[ESP32] ' .. msg, level or vim.log.levels.INFO) end)
end

local function build_openocd_cmd() return { M.config.openocd_bin, '-f', M.config.openocd_cfg } end

local function stop_openocd()
  if _openocd_timer then
    pcall(vim.uv.timer_stop, _openocd_timer)
    _openocd_timer = nil
  end
  if _openocd_job then
    vim.fn.jobstop(_openocd_job)
    _openocd_job = nil
    _openocd_ready = false
    notify 'OpenOCD fermato'
  end
end

local function start_openocd(on_ready, on_fail)
  if _openocd_job and _openocd_ready then
    notify('OpenOCD already active on:' .. M.config.openocd_gdb_port)
    vim.schedule(on_ready)
    return
  end

  if _openocd_job then
    vim.fn.jobstop(_openocd_job)
    _openocd_job = nil
    _openocd_ready = false
  end

  notify('Starting OpenOCD (' .. M.config.openocd_cfg .. ')…')

  local fired = false

  local function fire_ready()
    if fired then return end
    fired = true
    _openocd_ready = true
    if _openocd_timer then
      pcall(vim.uv.timer_stop, _openocd_timer)
      _openocd_timer = nil
    end
    notify('OpenOCD ready on:' .. M.config.openocd_gdb_port)
    vim.schedule(on_ready)
  end

  local function fire_fail(reason)
    if fired then return end
    fired = true
    stop_openocd()
    notify(reason, vim.log.levels.ERROR)
    if on_fail then vim.schedule(on_fail) end
  end

  _openocd_timer = vim.uv.new_timer()
  _openocd_timer:start(
    M.config.openocd_timeout_sec * 1000,
    0,
    function() fire_fail('Timeout (' .. M.config.openocd_timeout_sec .. 's): OpenOCD non è partito') end
  )

  local pattern = 'Listening on port ' .. M.config.openocd_gdb_port
  local line_buf = ''

  local function handle_output(_, data)
    if not data then return end
    for _, chunk in ipairs(data) do
      line_buf = line_buf .. chunk
      if line_buf:match(pattern) then
        fire_ready()
        return
      end
      -- Keep only the last partial line on the buffer
      local last = line_buf:match '.*\n()'
      if last then line_buf = line_buf:sub(last) end
    end
  end

  _openocd_job = vim.fn.jobstart(build_openocd_cmd(), {
    stdout_buffered = false,
    stderr_buffered = false,
    on_stdout = handle_output,
    on_stderr = handle_output,
    on_exit = function(_, code)
      local was_ready = _openocd_ready
      _openocd_job = nil
      _openocd_ready = false
      if not was_ready then
        fire_fail('OpenOCD uscito prima di essere pronto (exit ' .. code .. ')')
      elseif code ~= 0 then
        notify('OpenOCD terminato (exit ' .. code .. ')', vim.log.levels.WARN)
      end
    end,
  })

  if _openocd_job == 0 or _openocd_job == -1 then fire_fail('Binary non trovato: ' .. M.config.openocd_bin) end
end

function M.setup()
  local dap = require 'dap'

  local adapter_path = vim.fn.system('npm root -g'):gsub('\n', '') .. '/cdt-gdb-adapter/dist/debugTargetAdapter.js'

  dap.adapters.gdbtarget = function(callback, _config)
    start_openocd(
      function()
        callback {
          type = 'executable',
          command = 'node',
          args = { adapter_path },
        }
      end,
      function() notify('Debug annullato: OpenOCD non è partito', vim.log.levels.ERROR) end
    )
  end

  dap.configurations.c = vim.list_extend(dap.configurations.c or {}, {
    {
      name = 'ESP32-S3 Debug (ESP-Prog)',
      type = 'gdbtarget',
      request = 'attach',
      program = function()
        local proj = vim.fn.fnamemodify(vim.fn.getcwd(), ':t')
        return vim.fn.getcwd() .. '/build/default/' .. proj .. '.elf'
      end,
      gdb = vim.fn.exepath 'xtensa-esp32s3-elf-gdb',
      initCommands = {
        'set remote hardware-watchpoint-limit 2',
      },
      preRunCommands = {
        'mon reset halt',
        'flushregs',
        'thb app_main',
      },
      target = {
        connectCommands = {
          'set remotetimeout 20',
          '-target-select extended-remote localhost:3333',
        },
      },
    },
  })

  -- Auto-kill OpenOCD at the end of the session
  dap.listeners.before.event_terminated['esp32_openocd_stop'] = function(session)
    if session.config.type == 'gdbtarget' then stop_openocd() end
  end
  dap.listeners.before.event_exited['esp32_openocd_stop'] = function(session)
    if session.config.type == 'gdbtarget' then stop_openocd() end
  end
end

--- Build only. Called from <leader><leader>
function M.build()
  notify('Build: ' .. M.config.build_cmd)
  vim.fn.jobstart(M.config.build_cmd, {
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = function(_, d)
      if d and #d > 0 then notify(table.concat(d, '\n')) end
    end,
    on_stderr = function(_, d)
      if d and #d > 0 then notify(table.concat(d, '\n'), vim.log.levels.WARN) end
    end,
    on_exit = function(_, code)
      if code == 0 then
        notify 'Build OK ✓'
      else
        notify('Build FALLITA (exit ' .. code .. ')', vim.log.levels.ERROR)
      end
    end,
  })
end

function M.flash_and_debug()
  notify('Build → ' .. M.config.build_cmd)
  vim.fn.jobstart(M.config.build_cmd, {
    stdout_buffered = true,
    stderr_buffered = true,
    on_exit = function(_, code)
      vim.schedule(function()
        if code ~= 0 then
          notify('Build FALLITA (exit ' .. code .. '), debug annullato', vim.log.levels.ERROR)
          return
        end
        -- OpenOCD starts from within the function-adapter when dap.continue() is called
        notify 'Build OK → avvio debug'
        require('dap').continue()
      end)
    end,
  })
end

M.stop_openocd = stop_openocd
return M
