A helper plugin for defining consistent charwise and linewise motions and visual selection endpoints.

You can read about (neo)vim's inconsistencies this plugin aims to address
[here](https://www.reddit.com/r/neovim/comments/1d14rdy/defining_motions_correctly/).

This plugin is also designed to correctly handle multibyte and composing characters,
as well as forced motions ([except blockwise](https://www.reddit.com/r/neovim/comments/1d14rdy/comment/l6jy3rz/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button)).

# Usage

```lua
local motion = require('motion')

vim.keymap.set('o', 'my-motion', function()
    local cursor = vim.api.nvim_win_get_cursor(0)
    local end_pos = { cursor[1] - 1, vim.v.maxcol }
    motion.textobj_set_endpoints(end_pos, cursor)
end, { desc = 'selects until the end of the previous line' })

vim.keymap.set('n', 'my-visual', function()
    local p1 = vim.api.nvim_win_get_cursor(0)
    local p2 = { p1[1] + 1, vim.v.maxcol }
    if motion.range_inclusive_to_visual(p1, p2) then
        motion.util.visual_start(p1, p2)
    end
end, {
    desc = 'starts visual selection from the current position'
        .. ' to the end of the next line, including both ends',
})
```

# Testing

```lua
local plugin_path = ''

-- if not installed as a plugin
-- vim.opt.rtp:prepend(plugin_path)
vim.opt.rtp:prepend(plugin_path .. '/test')

local function run_test()
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

    print('-----textobj-calc-endpoints-----')
    package.loaded['motion-test.init_textobj_calc_endpoints_spec'] = nil
    require('motion-test.init_textobj_calc_endpoints_spec')
end

--- Warning: changes options!
local function run_options_test()
    package.loaded['motion'] = nil
    package.loaded['motion.util'] = nil
    package.loaded['motion-test.helpers'] = nil

    print('-----textobj-calc-endpoints-----')
    package.loaded['motion-test.init_textobj_spec'] = nil
    require('motion-test.init_textobj_spec')
end

vim.cmd('mes clear')
run_test()
-- run_options_test()
```
