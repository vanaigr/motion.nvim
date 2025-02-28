local vim = vim

local path = ...
local u = require(path..'.util')

local M = {}

M.util = u

--- @param pos_f table<integer, integer>
--- @param pos_l table<integer, integer>
--- @param context table Context from `create_context()`
--- @return boolean?: Whether the selection can be created.
local function adjust_ve_all(pos_f, pos_l, context)
    local lines = context.lines

    -- see #1
    -- virtualedit=all makes EOL a space, which wasn't there.
    -- Go back until last position is not at EOL.
    if context.virtualedit.all then
        while pos_l[2] == #lines[pos_l[1]] and not u.pos_lt(pos_l, pos_f) do
            if not u.move_to_prev(pos_l, context) then
                return false
            end
        end
    end
end

--- Modifies endpoints from range [`p1`, `p2`) or [`p2`, `p1`)
--- for charwise visual selection. Positions are (1, 0) indexed.
---
--- @param p1 table<integer, integer>
--- @param p2 table<integer, integer>
--- @param context table? Context from `create_context()`
--- @return boolean: Whether the selection can be created.
function M.range_to_visual(p1, p2, context)
    if not context then context = u.create_context() end
    local lines = context.lines
    local lines_count = context.lines_count
    local sel = context.selection

    u.clamp_pos(p1, context)
    u.clamp_pos(p2, context)

    if sel == 'exclusive' then
        return not u.is_same_char(p1, p2, context)
    end

    local pos_f, pos_l
    if u.pos_lt(p1, p2) then pos_f, pos_l = p1, p2
    else pos_f, pos_l = p2, p1 end

    u.move_to_cur(pos_f, context)
    u.move_to_prev(pos_l, context)

    if adjust_ve_all(pos_f, pos_l, context) == false then
        return false
    end

    if sel == 'inclusive' then
        return not u.pos_lt(pos_l, pos_f)
    end

    assert(sel == 'old')

    if pos_f[2] > 0 and pos_f[2] >= #lines[pos_f[1]] then
        if pos_f[1] >= lines_count then return false end
        pos_f[1] = pos_f[1] + 1
        pos_f[2] = 0
    end

    if pos_l[2] > 0 and pos_l[2] >= #lines[pos_l[1]] then
        pos_l[2] = #lines[pos_l[1]] - 1
    end

    return not u.pos_lt(pos_l, pos_f)
end

--- Modifies endpoints from range [`p1`, `p2`] or [`p2`, `p1`]
--- for charwise visual selection. Positions are (1, 0) indexed.
---
--- @param p1 table<integer, integer>
--- @param p2 table<integer, integer>
--- @param context table? Context from `create_context()`
---
--- @return boolean: Whether the selection can be created.
function M.range_inclusive_to_visual(p1, p2, context)
    if not context then context = u.create_context() end
    local lines = context.lines
    local lines_count = context.lines_count
    local sel = context.selection

    u.clamp_pos(p1, context)
    u.clamp_pos(p2, context)

    local pos_f, pos_l
    if u.pos_lt(p1, p2) then pos_f, pos_l = p1, p2
    else pos_f, pos_l = p2, p1 end

    if sel == 'exclusive' then
        u.move_to_next(pos_l, context)
        return not u.is_same_char(pos_f, pos_l, context)
    end

    u.move_to_cur(pos_f, context)
    u.move_to_cur(pos_l, context)

    if adjust_ve_all(pos_f, pos_l, context) == false then
        return false
    end

    if sel == 'inclusive' then
        return not u.pos_lt(pos_l, pos_f)
    end

    assert(sel == 'old')

    if pos_f[2] > 0 and pos_f[2] >= #lines[pos_f[1]] then
        if pos_f[1] >= lines_count then return false end -- last EOL in file
        pos_f[1] = pos_f[1] + 1
        pos_f[2] = 0
    end

    if pos_l[2] > 0 and pos_l[2] >= #lines[pos_l[1]] then
        pos_l[2] = #lines[pos_l[1]] - 1
    end

    return not u.pos_lt(pos_l, pos_f)
end

-- Don't bother with the cursor, just use visual selection
-- since it's more consistent (always changes visual selection marks,
-- as opposed to the cursor, which _sometimes_ changes them)

-- Converting blockwise visual positions between inclusive and exclusive
-- is nontrivial [ Even vim doesn't do it :) ]. With regular blockwise visual
--  + selection=exclusive, the bottommost endpoint is exclusive, but if its virtual column
-- is before the 2nd, it is not actually excluded (both endpoints are included).
-- Calculating the virtual column for an arbitrary position in the buffer is not
-- possible (there is `vim.fn.screenpos()`, but it doesn't work for offscreen and folds).
-- And there is also selection old w/o virtualedit, which also needs this info...
--
-- Returning nil since it's better for a motion to be empty than to be incorrect.
-- cursor is 1st, 'normal! o' is 2nd; though 1st doesn't have to be the cursor)

-- Note for linewise exclusive: even if an endpoint is at lnum:0, lnum is still selected.
-- Even if the selection is empty, it is still one line

--- Modifies endpoints `p1` and `p2` from range for a text object. Positions are (1, 0) indexed.
---
--- @param p1 table<integer, integer>
--- @param p2 table<integer, integer>
--- @param opts { mode: "v" | "V" | "", inclusive: boolean, context: table }
---
--- @return string | nil: which visual mode to use when setting selection. nil if not possible to select
function M.textobj_calc_endpoints(p1, p2, opts)
    local mode = opts.mode
    local incl = opts.inclusive
    local context = opts.context
    if mode == 'v' then
        if incl then
            if M.range_inclusive_to_visual(p1, p2, context) then return 'v' end
        else
            if M.range_to_visual(p1, p2, context) then return 'v' end
        end
    elseif mode == 'V' then
        u.clamp_pos(p1, context)
        u.clamp_pos(p2, context)
        return 'V'
    else
        assert(mode == '')

        u.clamp_pos(p1, context)
        u.clamp_pos(p2, context)

        local sel = context.selection
        if incl then
            if
                context.virtualedit.all
                or sel == 'inclusive'
                or (sel == 'old'
                    and (context.virtualedit.onemore
                        or context.virtualedit.block))
            then
                return ''
            elseif sel == 'old' then
                local lines = context.lines
                if (p1[2] == 0 or p1[2] < #lines[p1[1]])
                    and (p2[2] == 0 or p2[2] < #lines[p2[1]])
                then
                    return ''
                end
            end
        else
            -- not guaranteed to work since which endpoint is excluded
            -- is not defined.
            if sel == 'exclusive' then
                if not u.is_same_char(p1, p2, context) then return '' end
            end
        end
    end
end

--- Sets the range defined by `p1` and `p2` as positions for a custom text object.
--- (Default: charwise end-exclusive). `inclusive` only affects the column value,
--- and only in charwise and blockwise modes. Handles forced motion.
--- Positions are (1, 0) indexed, both are modified.
---
--- @param p1 table<integer, integer>
--- @param p2 table<integer, integer>
--- @param opts { mode: nil | "v" | "V" | "", inclusive: boolean?, context: table? }?
--- @return boolean: False if couldn't set the positions.
function M.textobj_set_endpoints(p1, p2, opts)
    local context = opts and opts.context or u.create_context()

    local cur_mode = vim.fn.mode(true)

    -- note: forced motion doesn't affect text objects defined through
    -- visual selection (apart from broken <C-V>). Handle it ourselves.
    local mode = opts and opts.mode or 'v'
    local inclusive = opts and opts.inclusive and true or false
    if cur_mode == 'nov' then
        if mode == 'v' then inclusive = not inclusive end
        mode = 'v'
    elseif cur_mode == 'noV' then
        mode = 'V'
    elseif cur_mode == 'no' then
        mode = ''
    end

    local res_mode = M.textobj_calc_endpoints(p1, p2, {
        mode = mode, inclusive = inclusive, context = context,
    })
    if not res_mode then return false end

    u.visual_start(p1, p2, res_mode)
    return true
end

return M
