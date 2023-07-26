XReadOnlyTable = XReadOnlyTable or {}

local NeedSetReadonly = CS.XLuaEngine.LuaReadonlyTableMode ~= CS.XMode.Release

XReadOnlyTable.HotLoad = false

XReadOnlyTable.Create = function(t)
    if not NeedSetReadonly or XReadOnlyTable.HotLoad then
        -- release 模式运行
        return t
    end

    for x, y in pairs(t) do
        if type(x) == "table" then
            if type(y) == "table" then
                t[XReadOnlyTable.Create(x)] = XReadOnlyTable.Create(y)
            else
                t[XReadOnlyTable.Create(x)] = y
            end
        elseif type(y) == "table" then
            t[x] = XReadOnlyTable.Create(y)
        end
    end

    local mt = {
        __metatable = "readonly table",
        __index = t,
        __newindex = function(t,k,v)
            if XReadOnlyTable.HotLoad then
                rawset(t,k,v)
            else
                XLog.Error("attempt to update a readonly table")
            end
        end,
        __len = function()
            return #t
        end,
        __pairs = function()
            local function stateless_iter(tbl, k)
                local nk, nv = next(tbl, k)
                if nk then return nk, nv end
            end
            return stateless_iter, t, nil
        end
    }

    return setmetatable({}, mt)
end