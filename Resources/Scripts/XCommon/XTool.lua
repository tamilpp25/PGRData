local Json = require("XCommon/Json")
local type = type
local table = table
local string = string
local math = math
local next = next
local debug = debug
local tostring = tostring

local tableInsert = table.insert
local stringMatch = string.match
local mathModf = math.modf

XTool = XTool or {}

XTool.UObjIsNil = function(uobj)
    return uobj == nil or not uobj:Exist()
end

XTool.LoopMap = function(map, func)
    if type(map) == "userdata" then
        if not map then
            return
        end

        local e = map:GetEnumerator()
        while e:MoveNext() do
            func(e.Current.Key, e.Current.Value)
        end
        e:Dispose()
    elseif type(map) == "table" then
        for key, value in pairs(map) do
            func(key, value)
        end
    end
end

XTool.LoopCollection = function(collection, func)
    if type(collection) == "table" then
        for _, value in pairs(collection) do
            func(value)
        end
    elseif type(collection) == "userdata" then
        for i = 0, collection.Count - 1 do
            func(collection[i])
        end
    end
end

XTool.LoopArray = function(collection, func)
    for i = 0, collection.Length - 1 do
        func(collection[i])
    end
end

XTool.CsList2LuaTable = function(collection)
    local ret = {}
    for i = 0, collection.Count - 1 do
        tableInsert(ret, collection[i])
    end
    return ret
end

XTool.CsMap2LuaTable = function(map)
    local ret = {}
    local e = map:GetEnumerator()
    while e:MoveNext() do
        ret[e.Current.Key] = e.Current.Value
    end
    e:Dispose()
    return ret
end

XTool.CsObjectFields2LuaTable = function(CsObj)
    if CsObj == nil or type(CsObj) ~= "userdata" then
        return {}
    end
    local jsonStr = CS.XTool.SerializeObject(CsObj)
    return Json.decode(jsonStr)
end

XTool.Clone = function(t)
    local cache = {}

    local function clone(o)
        if type(o) ~= "table" then return o end
        if cache[o] then return cache[o] end

        local newO = {}
        for k, v in pairs(o) do
            newO[clone(k)] = clone(v)
        end

        local mTable = getmetatable(o)
        if type(mTable) == "table" then
            setmetatable(newO, mTable)
        end
        
        cache[o] = newO

        return newO
    end

    return clone(t)
end

XTool.GetFileNameWithoutExtension = function(path)
    return stringMatch(path, "[./]*([^/]*)%.%w+")
end

XTool.GetFileName = function(path)
    return stringMatch(path, "[./]*([^/]*%.%w+)")
end

XTool.GetExtension = function(path)
    return stringMatch(path, "[./]*(%.%w+)")
end

XTool.GetTableCount = function(list)
    if type(list) ~= "table" then
        XLog.Error("  XTool.GetTableCount 函数错误 : 参数list需要是table类型的, list：" .. type(list))
        return
    end

    local count = 0
    for _, _ in pairs(list) do
        count = count + 1
    end

    return count
end

local NumberText = {
    [0] = "",
    [1] = CS.XTextManager.GetText("One"),
    [2] = CS.XTextManager.GetText("Two"),
    [3] = CS.XTextManager.GetText("Three"),
    [4] = CS.XTextManager.GetText("Four"),
    [5] = CS.XTextManager.GetText("Five"),
    [6] = CS.XTextManager.GetText("Six"),
    [7] = CS.XTextManager.GetText("Seven"),
    [8] = CS.XTextManager.GetText("Eight"),
    [9] = CS.XTextManager.GetText("Nine"),
    [10] = CS.XTextManager.GetText("Ten"),
}

XTool.ParseNumberString = function(num)
    return NumberText[mathModf(num / 10)] .. NumberText[num % 10]
end

XTool.ConvertNumberString = function(num)
    return NumberText[num] or ""
end

XTool.MatchEmoji = function(text)
    return stringMatch(text, '%[%d%d%d%d%d%]')
end

XTool.CopyToClipboard = function(text)
    CS.XAppPlatBridge.CopyStringToClipboard(tostring(text))
    XUiManager.TipText("Clipboard", XUiManager.UiTipType.Tip)
end

XTool.ToArray = function(t)
    local array = {}
    for _, v in pairs(t) do
        table.insert(array, v)
    end
    return array
end

XTool.MergeArray = function(...)
    local res = {}
    for _, t in pairs({ ... }) do
        if type(t) == "table" then
            for _, v in pairs(t) do
                table.insert(res, v)
            end
        end
    end
    return res
end

function XTool.ReverseList(list)
    if not list then return end

    local length = #list
    local middle = math.floor(length * 0.5)
    for i = 1, middle do
        local reverseI = length - i + 1
        local tmp = list[i]
        list[i] = list[reverseI]
        list[reverseI] = tmp
    end

    return list
end

XTool.Waterfall = function(cbList)
    local last
    for i = #cbList, 1, -1 do
        if type(cbList[i]) == "function" then
            local nextCb = last
            local cb = function()
                cbList[i](nextCb)
            end
            last = cb
        else
            XLog.Error("XTool.Waterfall error, unit is not function")
        end
    end
    if last then
        last()
    end
end

XTool.InitUiObject = function(targetObj)
    targetObj.Obj = targetObj.Transform:GetComponent("UiObject")
    if targetObj.Obj ~= nil then
        for i = 0, targetObj.Obj.NameList.Count - 1 do
            targetObj[targetObj.Obj.NameList[i]] = targetObj.Obj.ObjList[i]
        end
    end
end

XTool.InitUiObjectByUi = function(targetUi, uiPrefab)
    targetUi.GameObject = uiPrefab.gameObject
    targetUi.Transform = uiPrefab.transform
    XTool.InitUiObject(targetUi)
    return targetUi
end

XTool.DestroyChildren = function(gameObject)
    if not gameObject then
        return
    end

    if XTool.UObjIsNil(gameObject) then
        return
    end

    local transform = gameObject.transform
    for i = 0, transform.childCount - 1, 1 do
        CS.UnityEngine.Object.Destroy(transform:GetChild(i).gameObject)
    end
end

XTool.IsTableEmpty = function(tb)
    return not tb or not next(tb)
end

XTool.IsNumberValid = function(number)
    return number and number ~= 0
end

XTool.GetStackTraceName = function(level)
    level = level or 3
    local info
    for i = level, 2, -1 do
        info = debug.getinfo(i)
        if info then
            break
        end
    end
    
    local name = "lua:" .. tostring(info.source) .. "_" .. tostring(info.currentline)
    return name
end

-- datas : 只接受数组
XTool.TableRemove = function(datas, removeValue)
    local removePos = nil
    for index, value in ipairs(datas) do
        if value == removeValue then
            removePos = index
            break
        end
    end
    if removePos then table.remove(datas, removePos) end
end

-- 保留digit位小数
XTool.MathGetRoundingValue = function(value, digit)
    return math.floor( value * XTool.MathPow(10, digit) ) / XTool.MathPow(10 , digit)
end

XTool.MathPow = function(a, b)
    return a ^ b
end

--随机打乱
XTool.RandomBreakTableOrder = function(t)
    local index
    local temp
    local total = #t
    for i = 1, total, 1 do
        for j = i + 1, total, 1 do
            index = math.random(j, total);
            temp = t[i];
            t[i] = t[index];
            t[index] = temp;
            break
        end
    end

    return t
end