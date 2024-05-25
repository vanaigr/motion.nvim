local M = {}

function M.pos_to_string(p)
    if p == nil then return 'nil'
    else return '{ '..p[1]..', '..p[2]..' }' end
end

function M.print_err(indent, func, ...)
    local ok, res = pcall(func, ...)
    if ok and res then print(indent..'OK')
    elseif not ok then print(indent..'Error:', res) end
end

function M.get_msg(func, ...)
    local ok, res, msg = pcall(func, ...)
    if ok and res then return 'OK', true
    elseif not ok then return 'Error: '..res, false
    else return msg, false end
end

function M.pos_clone(p)
    return { p[1], p[2] }
end

return M
