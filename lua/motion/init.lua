local vim = vim

local path = ...
local u = require(path..'.util')

local M = {}

M.util = u

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

    u.clamp_pos(p1, context)
    u.clamp_pos(p2, context)

    local sel = context.selection
    if sel == 'exclusive' then
        return not u.is_same_char(p1, p2, context)
    end

    local pos_f, pos_l
    if u.pos_lt(p1, p2) then pos_f, pos_l = p1, p2
    else pos_f, pos_l = p2, p1 end

    u.move_to_cur(pos_f, context)
    u.move_to_prev(pos_l, context)

    -- Note: old + virtualedit ~= inclusive  (if old and ends in EOL, it is ignored)
    if sel == 'inclusive' or (sel == 'old' and context.virtualedit) then
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

    u.clamp_pos(p1, context)
    u.clamp_pos(p2, context)

    local sel = context.selection
    if sel == 'inclusive' or (sel == 'old' and context.virtualedit) then
        return true
    end

    local pos_f, pos_l
    if u.pos_lt(p1, p2) then pos_f, pos_l = p1, p2
    else pos_f, pos_l = p2, p1 end

    if sel == 'exclusive' then
        u.move_to_next(pos_l, context)
        return true
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

--- @deprecated Use `textobj_calc_endpoints()`
--- Modifies endpoints from range [`pos`, `initial_pos`) or [`initial_pos`, `pos`)
--- for charwise exclusive motion. Positions are (1, 0) indexed.
---
--- @param pos table<integer, integer>
--- @param initial_pos table<integer, integer> Cursor position at the start of the current mapping.
--- @param context table Context from `create_context()`
---
--- @return table<integer, integer>?, table<integer, integer>?: if only the first value is not nil, then endpoint can be defined by setting cursor position to it, if both are not nil, then visual selection needs to be used. Otherwise the motion is empty and no positions need to be set.
function M.motion_endpoint(pos, initial_pos, context)
    local lines = context.lines

    u.clamp_pos(pos, context)
    u.clamp_pos(initial_pos, context)

    -- Handle edgecase described below :h :delete .
    -- Also incidentally handles edgecases in :h exclusive
    -- (since end position cannot be in first col of the same line).
    if pos[1] == initial_pos[1] then
        if pos[2] < #lines[pos[1]] then
            if u.is_same_char(pos, initial_pos, context) then return end
            return pos
        elseif pos[2] == initial_pos[2] then return
        elseif context.virtualedit then return pos end -- Note: in cases like all,none  none doesn't matter
    end

    if not M.range_to_visual(pos, initial_pos, context) then return end
    return pos, initial_pos
end

--- @deprecated Use `textobj_set_endpoints()`
--- Sets charwise range [`pos`, `initial_pos`) or [`initial_pos`, `pos`)
--- as positions for a custom motion. Positions are (1, 0) indexed.
---
--- @param pos table<integer, integer> Note: modified.
--- @param initial_pos table<integer, integer>? Cursor position at the start of the current mapping. Defaults to the current cursor position. Note: modified.
--- @param context table? Context from `create_context()`
--- @return boolean: False if couldn't set the positions. Don't forget to reset the cursor position if you changed it previously!
function M.motion_set_endpoint(pos, initial_pos, context)
    if not context then context = u.create_context() end
    if not initial_pos then initial_pos = vim.api.nvim_win_get_cursor(0) end

    local p1, p2 = M.motion_endpoint(pos, initial_pos, context)
    if p1 then
        if p2 then
            u.visual_start(p1, p2)
        else
            vim.api.nvim_win_set_cursor(0, p1)
        end
        return true
    end
    return false
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
            if sel == 'inclusive' or (sel == 'old' and context.blockwise_virtualedit) then
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
