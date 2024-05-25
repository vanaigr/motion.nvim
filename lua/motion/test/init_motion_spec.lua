local util = require('motion.util')
local h = require('motion.test.helpers')

local it = require('motion')

local function test_motion(opts, lines, pos, init, e1, e2)
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

    h.print_err('    ', function()
        local a1, a2 = it.motion_endpoint(h.pos_clone(pos), h.pos_clone(init), context)

        if a1 and not a2 and e1 and not e2 then
            if util.pos_eq(a1, e1) then
                return true
            end
        elseif a2 and not a1 and e1 and not e2 then
            if util.pos_eq(a2, e1) then
                return true
            end
        elseif a1 and a2 and e1 and e2 then
            if (util.pos_eq(a1, e1) and util.pos_eq(a2, e2))
                or (util.pos_eq(a1, e2) and util.pos_eq(a2, e1))
            then
                return true
            end
        elseif not a1 and not a2 and not e1 and not e2 then
            return true
        end

        local function f(a)
            if a then return h.pos_to_string(a)
            else return 'none' end
        end

        print('    expected='..f(e1)..'-'..f(e2)..', actual='..f(a1)..'-'..f(a2))
    end)
end

print('Virtualedit:')
print('  forward:')
test_motion({ nil, true }, { 'abc' }, { 1, 3 }, { 1, 0 }, { 1, 3 }, nil)
print('  backward:')
test_motion({ nil, true }, { 'abc' }, { 1, 0 }, { 1, 3 }, { 1, 0 }, nil)
print('  empty:')
test_motion({ nil, nil }, { 'abc' }, { 1, 2 }, { 1, 2 }, nil, nil)
test_motion({ nil, nil }, { 'abc' }, { 1, 3 }, { 1, 3 }, nil, nil)

print('No virtualedit:')
test_motion({ 'exclusive', false }, { 'abc' }, { 1, 3 }, { 1, 0 }, { 1, 3 }, { 1, 0 })
test_motion({ 'exclusive', false }, { 'abc', 'def' }, { 2, 1 }, { 1, 1 }, { 2, 1 }, { 1, 1 })
