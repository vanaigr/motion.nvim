local util = require('motion.util')
local h = require('motion.test.helpers')

local it = require('motion')

local function test_visual0(p1, p2, e1, e2, context)
    local a1 = h.pos_clone(p1)
    local a2 = h.pos_clone(p2)
    local can = it.range_to_visual(a2, a1, context)
    local should = e1 and e2

    if can and should then
        if util.pos_eq(a1, e1) and util.pos_eq(a2, e2) then
            return true
        end
    elseif not can and not should then
        return true
    end

    local function f(c, a, b)
        if c then
            return h.pos_to_string(a)..'-'..h.pos_to_string(b)
        else
            return 'empty'
        end
    end

    return false, 'expected='..f(should, e1, e2) ..', actual='..f(can, a1, a2)
end

local function test_visual(opts, lines, p1, p2, e1, e2)
    local context = setmetatable({ lines = lines, lines_count = #lines }, {
        __index = function(_, k)
            local k_ = k
            if k == 'selection' then k_ = 1
            elseif k == 'virtualedit' then k_ = 2
            end

            local v = opts[k_]
            if v == nil then
                error('option '..k..' not supplied')
            end
            return v
        end
    })

    local m1, o1 = h.get_msg(test_visual0, p1, p2, e1, e2, context)
    local m2, o2 = h.get_msg(test_visual0, p2, p1, e2, e1, context)
    if o1 and o2 then return m1 .. '  ' .. m2
    else return '\n    ' .. m1 .. '\n    ' .. m2 end
end

local tests
local function test(name, opts, exp)
    print(name..':')
    for i, data in ipairs(tests) do
        local e1, e2 = exp[1 + (i-1)*2], exp[2 + (i-1)*2]
        print(
            '  '..data[1]..':',
            test_visual(opts,
                data[2],
                data[3], data[4],
                e1, e2
            )
        )
    end
    print(' ')
end

tests = {
    { 'normal', { 'abc' }, { 1, 0 }, { 1, 3 } },
    { 'OOB', { 'abc', 'defg' }, { 0, 100 }, { 3, -1 } },
    { 'multibyte', { 'a\xC2\xB5\xCC\x81\xCC\x83b', '\xC2\xB5\xCC\x81\xCC\x83' }, { 1, 4 }, { 2, 3 } },

    { 'EOL first char', { 'abc', 'defg' }, { 1, 3 }, { 2, 1 } },
    { 'EOL last char', { 'abc', 'defg' }, { 1, 2 }, { 2, 0 } },
    { 'EOL only char', { 'abc', 'defg' }, { 1, 3 }, { 2, 0 } },
    { 'EOL empty line', { 'abc', '' }, { 1, 2 }, { 2, 0 } },

    { 'past the end', { 'abc' }, { 1, 3 }, { 1, 3 } },
}

test('Selection exclusive', { 'exclusive' }, {
    { 1, 0 }, { 1, 3 },
    { 1, 0 }, { 2, 4 },
    { 1, 4 }, { 2, 3 }, -- native exclusive selection, no adj. needed

    { 1, 3 }, { 2, 1 },
    { 1, 2 }, { 2, 0 },
    { 1, 3 }, { 2, 0 },
    { 1, 2 }, { 2, 0 },
    nil, nil,
})

test('Selection inclusive', { 'inclusive' }, {
    { 1, 0 }, { 1, 2 },
    { 1, 0 }, { 2, 3 }, -- last EOL not selectable, has no effect
    { 1, 1 }, { 1, 8 },

    { 1, 3 }, { 2, 0 },
    { 1, 2 }, { 1, 3 },
    { 1, 3 }, { 1, 3 },
    { 1, 2 }, { 1, 3 },
    nil, nil,
})

test('Selection old, virtualedit', { 'old', true }, {
    { 1, 0 }, { 1, 2 },
    { 1, 0 }, { 2, 3 }, -- last EOL not selectable, has no effect
    { 1, 1 }, { 1, 8 },

    { 1, 3 }, { 2, 0 },
    { 1, 2 }, { 1, 3 },
    { 1, 3 }, { 1, 3 },
    { 1, 2 }, { 1, 3 },
    nil, nil,
})

test('Selection old, no virtualedit', { 'old', false }, {
    { 1, 0 }, { 1, 2 },
    { 1, 0 }, { 2, 3 }, -- last EOL not selectable, has no effect
    { 1, 1 }, { 1, 7 },

    { 2, 0 }, { 2, 0 },
    { 1, 2 }, { 1, 2 },
    nil, nil,
    { 1, 2 }, { 1, 2 },
    nil, nil,
})
