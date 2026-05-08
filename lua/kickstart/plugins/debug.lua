local M = {}

function M.setup()
    -- Tables acquired from the plugins
    local dap     = require('dap')
    local dapview = require('dap-view')
    local pb_api  = require('persistent-breakpoints.api')

    -- XXX:
    -- dap.defaults.fallback.terminal_win_cmd = function() end
    -- Listener for auto/close
    dapview.setup()

    local function set_debug_keymaps()
        vim.keymap.set('n', '<Right>', function() dap.step_over() end, { desc = 'DAP: step over' })
        vim.keymap.set('n', '<Down>', function() dap.step_into() end, { desc = 'DAP: step into' })
        vim.keymap.set('n', '<Up>', function() dap.step_out() end, { desc = 'DAP: step out' })
        vim.keymap.set('n', '<Left>', function() dap.restart_frame() end, { desc = 'DAP: restart frame' })
        vim.keymap.set('n', '<Enter>', function() dap.continue() end, { desc = 'DAP: continue' })
    end

    dap.listeners.after.event_initialized.dapview_config = function()
        dapview.open()
        set_debug_keymaps()
    end

    dap.listeners.before.event_terminated.dapview_config = function()
        dapview.close()
        vim.notify("Debug session ended.", vim.log.levels.INFO)
    end
    dap.listeners.before.event_exited.dapview_config = function(_, body)
        dapview.close()
        local code = body and body.exitCode or "?"
        vim.notify("Process exited with code " .. code .. ".", vim.log.levels.INFO)
    end

    -- Breakpoint signs
    vim.fn.sign_define('DapBreakpoint', { text = '●', texthl = 'DiagnosticError' })
    vim.fn.sign_define('DapBreakpointCondition', { text = '◆', texthl = 'DiagnosticError' })
    vim.fn.sign_define('DapBreakpointRejected', { text = '✗', texthl = 'DiagnosticHint' })

    -- Highlight the line of the breakpoint currently active
    vim.api.nvim_set_hl(0, 'DapStoppedLine', { link = 'CursorLine' })
    vim.api.nvim_set_hl(0, 'DapStoppedLineNr', {
        fg = vim.api.nvim_get_hl(0, { name = 'DiagnosticOk' }).fg,
        bg = vim.api.nvim_get_hl(0, { name = 'CursorLine' }).bg,
    })
    vim.fn.sign_define('DapStopped',
        { text = '●', texthl = 'DiagnosticOk', linehl = 'DapStoppedLine', numhl = 'DapStoppedLineNr' })

    -- Persistent breakpoints, save them on disk
    vim.keymap.set('n', '<leader>db', pb_api.toggle_breakpoint, { desc = 'DAP: toggle breakpoint' })
    vim.keymap.set('n', '<leader>dB', pb_api.set_conditional_breakpoint, { desc = 'DAP: conditional breakpoint' })
    vim.keymap.set('n', '<leader>dC', pb_api.clear_all_breakpoints, { desc = 'DAP: clear all breakpoints' })
    vim.keymap.set('n', '<leader>du', function() dapview.toggle() end, { desc = 'DAP: toggle UI' })
    vim.keymap.set('n', '<leader>dc', function() dap.continue() end, { desc = 'DAP: continue' })
    vim.keymap.set('n', '<leader>dd', function() dap.run_to_cursor() end, { desc = 'DAP: run to cursor' })
    vim.keymap.set('n', '<leader>dx', function() dap.restart_frame() end, { desc = 'DAP: restart frame' })
    vim.keymap.set('n', '<leader>ds', function()
        -- TODO: Verify "false" is the appropriate value
        dap.disconnect({ terminateDebuggee = false })
        dapview.close()
    end, { desc = 'DAP: disconnect' })
    vim.keymap.set('n', '<leader>dr', function() dap.restart() end, { desc = 'DAP: Restart' })
    vim.keymap.set('n', '<leader>do', function() dap.step_over() end, { desc = 'DAP: step over' })
    vim.keymap.set('n', '<leader>di', function() dap.step_into() end, { desc = 'DAP: step into' })
    vim.keymap.set('n', '<leader>dt', function() dap.step_out() end, { desc = 'DAP: step out' })

    -- Built-in for easy evaluation
    local widgets = require('dap.ui.widgets')
    vim.keymap.set('n', '<leader>de', function()
        widgets.hover()
    end, { desc = 'DAP: eval word under cursor' })
    vim.keymap.set('v', '<leader>de', function()
        widgets.hover()
    end, { desc = 'DAP: eval selection' })

    -- Dispatch table — profile loader
    local loaders = {
        stm32 = function() return require('kickstart.plugins.debug.debug_stm32') end,
        esp32 = function() return require('kickstart.plugins.debug.dap_esp32') end,
        python = function() return require('kickstart.plugins.debug.debug_python') end,
        infineon = function() return require('kickstart.plugins.debug.debug_infineon') end,
        -- local_c = function() return require('dap.dap_local_c') end,
    }

    local profile = require("custom.profile").detect_profile()
    local loader = loaders[profile]

    if loader then
        local ok, mod = pcall(loader)
        if ok and mod then
            pcall(mod.setup)
        end
    end
end

return {
    'mfussenegger/nvim-dap',
    dependencies = {
        'nvim-neotest/nvim-nio',
        {
            'igorlfs/nvim-dap-view',
            dependencies = { 'mfussenegger/nvim-dap' },
            opts = {
                winbar = {
                    sections = { 'watches', 'scopes', 'exceptions', 'breakpoints', 'threads', 'repl', 'console', },
                },
            },
            windows = {
                terminal = {
                    start_hidden = true,
                },
            },
        },
        {
            'Weissle/persistent-breakpoints.nvim',
            dependencies = { 'mfussenegger/nvim-dap' },
            config = function()
                require('persistent-breakpoints').setup({
                    save_dir = vim.fn.stdpath('data') .. '/nvim_checkpoints',
                    load_breakpoints_event = { 'BufReadPost' },
                })
            end,
        },
        {
            "rcarriga/nvim-dap-ui",
            dependencies = { "mfussenegger/nvim-dap",
                "nvim-neotest/nvim-nio" }
        },
        'jedrzejboczar/nvim-dap-cortex-debug',
    },
    config = function()
        M.setup()
    end,
}
