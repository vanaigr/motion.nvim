-- note \x12 is luajit...
local it = require('motion.util')

local h = require('motion-test.helpers')

local function from_bool(bool)
    if bool then return 't' else return 'f' end
end

local function test_char(func, lines, expected)
    local context = { lines = lines, lines_count = #lines }

    local ok = true
    local msg = ''

    local ri = 1
    for j = 1, context.lines_count do
        for i = 0, #context.lines[j] do
            local act = { j, i }
            local act_res = func(act, context)
            local exp = expected[ri]
            ri = ri + 1
            if not it.pos_eq(act, exp) or act_res ~= exp[3] then
                msg = msg ..'\n    at '..j..':'..i
                    ..', expected='..h.pos_to_string(exp)..'-'..from_bool(exp[3])
                    ..', actual='..h.pos_to_string(act)..'-'..from_bool(act_res)
                ok = false
            end
        end
    end

    return ok, msg
end

local function test_chars(name, lines, e1, e2, e3)
    print(name..':')
    -- , '') to not print the second return value (boolean ok)
    print('  move_to_prev:', h.get_msg(test_char, it.move_to_prev, lines, e1), '')
    print('  move_to_cur:', h.get_msg(test_char, it.move_to_cur, lines, e2), '')
    print('  move_to_next:', h.get_msg(test_char, it.move_to_next, lines, e3), '')
    print(' ')
end

test_chars(
    'empty', { '', '' },
    { { 1, 0, false }, { 1, 0, true } },
    { { 1, 0, nil }, { 2, 0, nil } },
    { { 2, 0, true }, { 2, 0, false } }
)

test_chars(
    'multibyte', { 'a', 'a€' },
    {
        { 1, 0, false }, { 1, 0, true },
        { 1, 1, true }, { 2, 0, true }, { 2, 0, true }, { 2, 0, true }, { 2, 1, true },
    },
    {
        { 1, 0, nil }, { 1, 1, nil },
        { 2, 0, nil }, { 2, 1, nil }, { 2, 1, nil }, { 2, 1, nil }, { 2, 4, nil },
    },
    {
        { 1, 1, true }, { 2, 0, true },
        { 2, 1, true }, { 2, 4, true }, { 2, 4, true }, { 2, 4, true }, { 2, 4, false },
    }
)

test_chars(
    'multi-code-point', { '', '\xC2\xB5\xCC\x81\xCC\x83', '' },
    {
        { 1, 0, false },
        { 1, 0, true }, { 1, 0, true }, { 1, 0, true }, { 1, 0, true }, { 1, 0, true }, { 1, 0, true }, { 2, 0, true },
        { 2, 6, true },
    },
    {
        { 1, 0, nil },
        { 2, 0, nil }, { 2, 0, nil }, { 2, 0, nil }, { 2, 0, nil }, { 2, 0, nil }, { 2, 0, nil }, { 2, 6, nil },
        { 3, 0, nil },
    },
    {
        { 2, 0, true },
        { 2, 6, true }, { 2, 6, true }, { 2, 6, true }, { 2, 6, true }, { 2, 6, true }, { 2, 6, true }, { 3, 0, true },
        { 3, 0, false },
    }
)
