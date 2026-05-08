local M = {}

function M.detect_profile()
    -- TODO: Implement detections for the other profiles!
    local cwd = vim.fn.getcwd()

    local stm32_file = vim.fs.find(function(name)
        return name:lower():find('stm32', 1, true) ~= nil
    end, {
        path  = cwd,
        limit = 1,
        type  = 'file',
    })

    if #stm32_file > 0 then
        return 'stm32'
    end

    if vim.fn.glob(cwd .. '/*.uvprojx') ~= '' then
        return 'infineon'
    end

    if vim.fn.filereadable(cwd .. '/pyrightconfig.json') == 1 then
        return 'python'
    end
end

return M
