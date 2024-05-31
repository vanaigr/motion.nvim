local it = require('motion')
local util = require('motion.util')

local h = require('motion-test.helpers')

local function test(context_opts, opts, p1, p2, mode, e1, e2)
    local context = setmetatable({}, {
        __index = function(t, k)
            if k == 'lines_count' then
                return #t.lines
            end
            local v = context_opts[k]
            assert(v ~= nil, k)
            return v
        end
    })
    opts.context = context

    local a1 = h.pos_clone(p1)
    local a2 = h.pos_clone(p2)

    h.print_err('    ', function()
        local actual_mode = it.textobj_calc_endpoints(a1, a2, opts)
        if actual_mode then
            if actual_mode == mode and util.pos_eq(a1, e1) and util.pos_eq(a2, e2) then return true end
        elseif not mode then
            return true
        end

        local function f(c, a, b)
            return vim.inspect(c) .. ':'..h.pos_to_string(a)..'-'..h.pos_to_string(b)
        end
        print('    expected='..f(mode, e1, e2)..', actual='..f(actual_mode, a1, a2))
    end)
end

print('charwise')
print('  selection options')
test(
    { selection = 'exclusive', lines = { 'abc' } }, { mode ='v' },
    { 1, 0 }, { 1, 3 }, 'v', { 1, 0 }, { 1, 3 }
)
test(
    { selection = 'inclusive', lines = { 'abc' } }, { mode ='v' },
    { 1, 0 }, { 1, 3 }, 'v', { 1, 0 }, { 1, 2 }
)
test(
    { selection = 'old', virtualedit = false, lines = { 'abc' } }, { mode ='v', inclusive = false },
    { 1, 0 }, { 1, 3 }, 'v', { 1, 0 }, { 1, 2 }
)

print('  inclusive')
test(
    { selection = 'exclusive', lines = { 'abc' } }, { mode ='v', inclusive = true },
    { 1, 0 }, { 1, 2 }, 'v', { 1, 0 }, { 1, 3 }
)

print('  empty')
test({ selection = 'exclusive', lines = { 'abc' } }, { mode ='v' }, { 1, 1 }, { 1, 1 }, nil)


print('linewise')
test({ lines = { 'abc' } }, { mode = 'V', }, { 1, 0 }, { 1, 3 }, 'V', { 1, 0 }, { 1, 3 })
test({ lines = { 'abc' } }, { mode = 'V', }, { 1, 1 }, { 1, 1 }, 'V', { 1, 1 }, { 1, 1 })


print('blockwise')
test(
    { selection = 'exclusive', lines = { 'abc' } }, { mode = '', },
    { 1, 0 }, { 1, 3 }, '', { 1, 0 }, { 1, 3 }
)
test(
    { selection = 'exclusive', lines = { 'abc', '' } }, { mode = '', },
    { 1, 0 }, { 2, 0 }, '', { 1, 0 }, { 2, 0 } -- end point is not moved
)
test(
    { selection = 'inclusive', lines = { 'abc' } }, { mode = '', inclusive = true },
    { 1, 0 }, { 1, 2 }, '', { 1, 0 }, { 1, 2 }
)
test(
    { selection = 'old', blockwise_virtualedit = true, lines = { 'abc' } },
    { mode = '', inclusive = true }, { 1, 0 }, { 1, 2 }, '', { 1, 0 }, { 1, 2 }
)
test(
    { selection = 'old', blockwise_virtualedit = false, lines = { 'abc' } },
    { mode = '', inclusive = true }, { 1, 0 }, { 1, 2 }, '', { 1, 0 }, { 1, 2 }
)

print('  not supported')
test(
    { selection = 'exclusive', lines = { 'abc' } }, { mode = '', inclusive = true },
    { 1, 0 }, { 1, 1 }, nil
)
test({ selection = 'inclusive', lines = { 'abc' } }, { mode = '', }, { 1, 0 }, { 1, 1 }, nil)
test({ selection = 'old', lines = { 'abc' } }, { mode = '', }, { 1, 0 }, { 1, 3 }, nil)
test(
    { selection = 'old', blockwise_virtualedit = false, lines = { 'abc' } },
    { mode = '', inclusive = true }, { 1, 0 }, { 1, 3 }, nil
)

print('  empty')
test({ selection = 'exclusive', lines = { 'abc' } }, { mode = '' }, { 1, 1 }, { 1, 1 }, nil)
