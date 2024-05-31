local motion = require('motion')
local vim = vim

local m = setmetatable({}, { __index = function(t, k) return '<Plug>motion-nvim-mapping-'..k end })

vim.keymap.set('o', m[1], function()
    local cursor = vim.api.nvim_win_get_cursor(0)
    local end_pos = { cursor[1] + 1, cursor[2] + 1 }
    motion.textobj_set_endpoints(end_pos, cursor)
end)

vim.keymap.set('o', m[2], function()
    local cursor = vim.api.nvim_win_get_cursor(0)
    local end_pos = { cursor[1] + 1, cursor[2] + 1 }
    motion.textobj_set_endpoints(end_pos, cursor, { inclusive = true })
end)

vim.keymap.set('o', m[3], function()
    local cursor = vim.api.nvim_win_get_cursor(0)
    local end_pos = { cursor[1] + 1, cursor[2] + 1 }
    motion.textobj_set_endpoints(end_pos, cursor, { inclusive = true, mode = 'V' })
end)

vim.keymap.set('o', m[4], function()
    local cursor = vim.api.nvim_win_get_cursor(0)
    local end_pos = { cursor[1] + 1, cursor[2] + 1 }
    motion.textobj_set_endpoints(end_pos, cursor, { mode = '' })
end)


local lines = { '12', 'abc', 'defg', '!@#$%' }
local exclusive = { '12', 'afg', '!@#$%' }
local inclusive = { '12', 'ag', '!@#$%' }
local linewise = { '12', '!@#$%' }
local blockwise_exclusive = { '12', 'ac', 'dfg', '!@#$%' }
local blockwise_inclusive = { '12', 'a', 'dg', '!@#$%' }

local function check(cmd, expected)
    vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
    vim.api.nvim_win_set_cursor(0, { 2, 1 })
    vim.api.nvim_feedkeys(
        'd'..vim.api.nvim_replace_termcodes(cmd, true, true, true),
        'nx',
        false
    )
    local actual = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local actual_s = vim.inspect(actual)
    local expected_s = vim.inspect(expected)
    if actual_s ~= expected_s then
        print('    expected='..expected_s)
        print('    actual  ='..actual_s)
    else
        print('    Ok')
    end
end

local function test()
    print('  exclusive')
    check(m[1], exclusive)
    print('  inclusive')
    check(m[2], inclusive)
    print('  linewise')
    check(m[3], linewise)

    print(' ')
    print('  forced inclusive')
    check('v'..m[1], inclusive)
    print('  forced exclusive')
    check('v'..m[2], exclusive)
    print('  forced charwise')
    check('v'..m[3], inclusive)

    print(' ')
    print('  forced linewise')
    check('V'..m[1], linewise)
    print('  forced linewise (inclusive)')
    check('V'..m[2], linewise)
    print('  forced charwise')
    check('V'..m[3], linewise)
end

vim.cmd('tabe')


print('selection exclusive')
vim.cmd('set selection=exclusive')
test()

print(' ')
print('  forced blockwise')
check('<C-V>'..m[1], blockwise_exclusive)
print('  forced blockwise (inclusive) -- doesnt work')
check('<C-V>'..m[2], lines)
print('  forced blockwise (linewise) -- doesnt work')
check('<C-V>'..m[3], lines)
print(' ')
print('  blockwise')
check(''..m[4], blockwise_exclusive)

print('selection inclusive')
vim.cmd('set selection=inclusive')
print(' ')
print('  forced blockwise -- doesnt work')
check('<C-V>'..m[1], lines)
print('  forced blockwise (inclusive)')
check('<C-V>'..m[2], blockwise_inclusive)
print('  forced blockwise (linewise)')
check('<C-V>'..m[3], blockwise_inclusive)
print(' ')
print('  blockwise -- doesnt work')
check(''..m[4], lines)

print('selection old + no virtualedit')
vim.cmd('set selection=old virtualedit=')
print(' ')
print('  forced blockwise -- doesnt work')
check('<C-V>'..m[1], lines)
print('  forced blockwise (inclusive)')
check('<C-V>'..m[2], blockwise_inclusive)
print('  forced blockwise (linewise)')
check('<C-V>'..m[3], blockwise_inclusive)

vim.cmd('q!')
