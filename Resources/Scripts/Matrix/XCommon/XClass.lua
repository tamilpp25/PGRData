local getinfo = debug.getinfo
local type = type

local _class = {}
local _classNameDic = {}

function XClass(super, className)
    local class

    if XMain.IsEditorDebug then
        local fullClassName = className .. getinfo(2, "S").source
        class = _classNameDic[fullClassName]
        if class then
            return class
        end

        class = {}
        _classNameDic[fullClassName] = class
    else
        class = {}
    end

    class.Ctor = false
    class.Super = super
    class.New = function(...)
        local obj = {}
        setmetatable(obj, { __index = _class[class] })
        do
            local create
            create = function(c, ...)
                if c.Super then
                    create(c.Super, ...)
                end

                if c.Ctor then
                    c.Ctor(obj, ...)
                end
            end
            create(class, ...)
        end
        return obj
    end

    local vtbl = {}
    _class[class] = vtbl

    setmetatable(class, {
        __newindex = function(_, k, v)
            vtbl[k] = v
        end,
        __index = function(_, k)
            return vtbl[k]
        end
    })

    if super then
        setmetatable(vtbl, {
            __index = function(_, k)
                local ret = _class[super][k]
                vtbl[k] = ret
                return ret
            end
        })
    end

    return class
end

function UpdateClassType(newClass, oldClass)
    if "table" ~= type(newClass) then return end
    if "table" ~= type(oldClass) then return end

    if oldClass == newClass then return end

    local new_vtbl = _class[newClass]
    local old_vtbl = _class[oldClass]
    if not new_vtbl or not old_vtbl then return end

    _class[oldClass] = new_vtbl
    _class[newClass] = nil
end