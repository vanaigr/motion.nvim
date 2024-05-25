local vim = vim

local u = require('motion.util')

local M = {}

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
            u.visual_set_pos(p1, p2)
        else
            vim.api.nvim_win_set_cursor(0, p1)
        end
        return true
    end
    return false
end


return M
