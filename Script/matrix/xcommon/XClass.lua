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
        obj.__cname = className
        obj.__class = class --for typeof
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
        vtbl.Super = super
        if XMain.IsEditorDebug then
            setmetatable(vtbl, {
                __index = function(_, k)
                    local ret = _class[super][k]
                    return ret
                end
            })
        else
            setmetatable(vtbl, {
                __index = function(_, k)
                    local ret = _class[super][k]
                    vtbl[k] = ret
                    return ret
                end
            })
        end
    end

    return class
end

function GetClassVituralTable(class)
    return _class[class]
end

function UpdateClassType(newClass, oldClass)
    if "table" ~= type(newClass) then
        return
    end
    if "table" ~= type(oldClass) then
        return
    end

    if oldClass == newClass then
        return
    end

    local new_vtbl = _class[newClass]
    local old_vtbl = _class[oldClass]
    if not new_vtbl or not old_vtbl then
        return
    end

    _class[oldClass] = new_vtbl
    _class[newClass] = nil
end

-- 检查obj是否从super中继承过来
function CheckClassSuper(obj, super)
    if obj == nil or obj.Super == nil then
        return false
    end
    local checkSuper = obj.Super
    while checkSuper do
        if checkSuper == super then
            return true
        end
        checkSuper = checkSuper.Super
    end
    return false
end

function CheckIsClass(obj)
    -- hack
    return obj.Ctor ~= nil and obj.New ~= nil
end

-- 创建匿名方法类
function CreateAnonClassInstance(funcDic, super, ...)
    local result = super.New(...)
    result.Super = super
    for funcName, func in pairs(funcDic) do
        result[funcName] = func
    end
    return result
end

function become_const(const_table, tipsError)
    function Const(const_table)
        local mt = {
            __index = function(t, k)
                if const_table[k] then
                    return const_table[k]
                elseif tipsError then
                    XLog.Error(string.format("const or enum key = %s is nil", k))
                end
            end,
            __newindex = function(t, k, v)
                XLog.Error("can't set " .. tostring(const_table) .. "." .. tostring(k) .. " to " .. tostring(v))
            end
        }
        return mt
    end

    local t = {}
    setmetatable(t, Const(const_table))
    return t
end

function enum(t, tipsError)
    local ret = {}
    for k, v in pairs(t) do
        ret[k] = v
        ret[v] = k
    end
    ret.dic = t
    return become_const(ret, tipsError)
end