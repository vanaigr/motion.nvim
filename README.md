A helper plugin for setting charwise motion and visual selection endpoints.

Handles `virtualedit`, `selection`, as well as multibyte and composing characters.

# Usage

```lua
local motion = require('motion')

vim.keymap.set('o', 'my-motion', function()
    local cursor = vim.api.nvim_win_get_cursor(0)
    local end_pos = { cursor[1] - 1, vim.v.maxcol }
    motion.motion_set_endpoint(end_pos, cursor)
end, { desc = 'selects until the end of the previous line' })

vim.keymap.set('n', 'my-visual', function()
    local cursor = vim.api.nvim_win_get_cursor(0)
    local end_pos = { cursor[1] + 1, vim.v.maxcol }
    if motion.range_inclusive_to_visual(end_pos, cursor) then
        motion.util.visual_start(cursor, end_pos)
    end
end, {
    desc = 'starts visual selection from the current position'
        .. ' to the end of the next line, including both ends',
})
```

# Testing

```lua
local vim = vim

local function reload()
    vim.cmd('mes clear')

    local plugin_path = [[]]
    -- if not installed as a plugin
    -- vim.opt.rtp:prepend(plugin_path)
    vim.opt.rtp:prepend(plugin_path .. '/test')

    package.loaded['motion'] = nil
    package.loaded['motion.util'] = nil
    package.loaded['motion-test.helpers'] = nil

    print('-----util-----')
    package.loaded['motion-test.util_spec'] = nil
    require('motion-test.util_spec')

    print('-----visual-----')
    package.loaded['motion-test.init_visual_spec'] = nil
    require('motion-test.init_visual_spec')

    print('-----inclusive-visual-----')
    package.loaded['motion-test.init_visual_inclusive_spec'] = nil
    require('motion-test.init_visual_inclusive_spec')

    print('-----motion-----')
    package.loaded['motion-test.init_motion_spec'] = nil
    require('motion-test.init_motion_spec')
end

run_test()
-- vim.keymap.set('n', '<keymap>', function() run_test(); return '<cmd>mes<cr>' end, { expr = true })
```
