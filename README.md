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
