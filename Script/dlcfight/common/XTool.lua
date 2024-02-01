--local Json = require("XCommon/Json")
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

XTool =
    XTool or
    {
        _IsAutoRefreshOnNextFrame = true
    }

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

--XTool.CsObjectFields2LuaTable = function(CsObj)
--    if CsObj == nil or type(CsObj) ~= "userdata" then
--        return {}
--    end
--    local jsonStr = CS.XTool.SerializeObject(CsObj)
--    return Json.decode(jsonStr)
--end

XTool.Clone = function(t)
    local cache = {}

    local function clone(o)
        if type(o) ~= "table" then
            return o
        end
        if cache[o] then
            return cache[o]
        end

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
        return 0
    end

    local count = 0
    for _, _ in pairs(list) do
        count = count + 1
    end

    return count
end

--local NumberText = {
--    [0] = "",
--    [1] = CS.XTextManager.GetText("One"),
--    [2] = CS.XTextManager.GetText("Two"),
--    [3] = CS.XTextManager.GetText("Three"),
--    [4] = CS.XTextManager.GetText("Four"),
--    [5] = CS.XTextManager.GetText("Five"),
--    [6] = CS.XTextManager.GetText("Six"),
--    [7] = CS.XTextManager.GetText("Seven"),
--    [8] = CS.XTextManager.GetText("Eight"),
--    [9] = CS.XTextManager.GetText("Nine"),
--    [10] = CS.XTextManager.GetText("Ten")
--}
--
--XTool.ParseNumberString = function(num)
--    return NumberText[mathModf(num / 10)] .. NumberText[num % 10]
--end
--
--XTool.ConvertNumberString = function(num)
--    return NumberText[num] or ""
--end

XTool.MatchEmoji = function(text)
    return stringMatch(text, "%[%d%d%d%d%d%]")
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
    for _, t in pairs({...}) do
        if type(t) == "table" then
            for _, v in pairs(t) do
                table.insert(res, v)
            end
        end
    end
    return res
end

function XTool.ReverseList(list)
    if not list then
        return
    end

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

XTool.InitUiObjectByInstance = function(uiObject, instance)
    for i = 0, uiObject.NameList.Count - 1 do
        instance[uiObject.NameList[i]] = uiObject.ObjList[i]
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
    return number and number ~= 0 or false
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
    if removePos then
        table.remove(datas, removePos)
    end
end

-- 直接使用getRoundingValue
-- 保留digit位小数
XTool.MathGetRoundingValue = function(value, digit)
    return math.floor(value * XTool.MathPow(10, digit)) / XTool.MathPow(10, digit)
end

-- 直接使用math.pow
XTool.MathPow = function(a, b)
    return a ^ b
end

--==================
--将utf8字符转换为unicode编码格式对应的十进制数值
--==================
XTool.Utf8_to_unicode = function(convertStr)
    if type(convertStr) ~= "string" then
        return convertStr
    end
    local resultDec = 0
    local i = 1
    local num1 = string.byte(convertStr, i)
    if num1 ~= nil then
        local tempVar1, tempVar2 = 0, 0
        if num1 >= 0x00 and num1 <= 0x7f then
            tempVar1 = num1
            tempVar2 = 0
        elseif num1 & 0xe0 == 0xc0 then
            local t1 = 0
            local t2 = 0
            t1 = num1 & 0xff >> 3
            i = i + 1
            num1 = string.byte(convertStr, i)
            t2 = num1 & 0xff >> 2
            tempVar1 = t2 | ((t1 & (0xff >> 6)) << 6)
            tempVar2 = t1 >> 2
        elseif num1 & 0xf0 == 0xe0 then
            local t1 = 0
            local t2 = 0
            local t3 = 0
            t1 = num1 & (0xff >> 3)
            i = i + 1
            num1 = string.byte(convertStr, i)
            t2 = num1 & (0xff >> 2)
            i = i + 1
            num1 = string.byte(convertStr, i)
            t3 = num1 & (0xff >> 2)
            tempVar1 = ((t2 & (0xff >> 6)) << 6) | t3
            tempVar2 = (t1 << 4) | (t2 >> 2)
        end
        resultDec = tempVar2 * 256 + tempVar1
    end
    return resultDec
end
--==================
--提取字符串中的英文和汉字文本
--==================
XTool.GetPureStr = function(str)
    if str == nil then
        return nil
    end
    local resultChar = {}
    for i = 1, #str do
        local curByte = string.byte(str, i)
        local byteCount = 1
        if curByte > 239 then
            byteCount = 4
        elseif curByte > 223 then
            byteCount = 3
        elseif curByte > 128 then
            byteCount = 2
        else
            byteCount = 1
        end
        local subStr = string.sub(str, i, i + byteCount - 1)
        local charUnicodeNum = XTool.Utf8_to_unicode(subStr)
        --
        --[[if  curByte == 32 or                        --空格
        (curByte > 47 and curByte < 58) or      --数字
        (curByte > 96 and curByte < 123) or     --小写字母
        (curByte > 64 and curByte < 91)        --大写字母
        ]] if
            (curByte > 96 and curByte < 123) or (curByte > 64 and curByte < 91) or
                (charUnicodeNum >= 19968 and charUnicodeNum <= 40891)
         then --汉字/u4E00 -- /u9fbb
            table.insert(resultChar, subStr)
        end
        i = i + byteCount
        if i > #str then
            return table.concat(resultChar)
        end
    end
    return nil
end

--随机打乱
XTool.RandomBreakTableOrder = function(t)
    local index
    local temp
    local total = #t
    for i = 1, total, 1 do
        for j = i + 1, total, 1 do
            index = math.random(j, total)
            temp = t[i]
            t[i] = t[index]
            t[index] = temp
            break
        end
    end

    return t
end

--权重随机算法（输入：带有Weight字段的元素组 输出：加权后的随机元素）
XTool.WeightRandomSelect = function(elements, isNotSetRandomseed)
    local sum = 0
    for _, v in ipairs(elements) do
        sum = sum + v.Weight
    end

    if not isNotSetRandomseed then
        math.randomseed(os.time())
    end
    local compareWeight = math.random(1, sum)
    local index = 1
    while sum > 0 do
        sum = sum - elements[index].Weight
        if sum < compareWeight then
            return elements[index]
        end
        index = index + 1
    end
    XLog.Error("compare error, return nil")
    return nil
end

-- 权重随机算法（输入：权重数组 输出：加权后的随机index）
XTool.RandomSelectByWeightArray = function(weights)
    local sum = 0
    for i = 1, #weights do
        sum = sum + weights[i]
    end

    math.randomseed(os.time())
    local compareWeight = math.random(1, sum)
    local index = 1
    while sum > 0 do
        sum = sum - weights[index]
        if sum < compareWeight then
            return index
        end
        index = index + 1
    end
    XLog.Error("compare error, return nil")
    return nil
end

--从1-limit之间获取指定count不重复随机数
function XTool.GetRandomNumbers(limit, count)
    local result = {}

    for i = 1, limit do
        tableInsert(result, i)
    end

    local num, tmp
    math.randomseed(os.time())
    for i = 1, limit do
        num = math.random(1, limit)
        tmp = result[i]
        result[i] = result[num]
        result[num] = tmp
    end

    if count then
        for i = count + 1, limit do
            result[i] = nil
        end
    end

    return result
end

--- 根据随机种子打乱数组
---@param array table 需要打乱的数组
---@param randomseed number 随机种子
---@return table
--------------------------
function XTool.RandomArray(array, randomseed)
    if #array < 0 then
        XLog.Warning("XTool.RandomArray: random array error: array is empty or not an array", array)
        return {}
    end
    local result = {}
    --不对原数据产生变化
    local tmpArray = XTool.Clone(array)
    math.randomseed(randomseed)
    
    local count = #tmpArray
    while count > 0 do
        local idx = math.random(1, count)
        if tmpArray[idx] then
            tableInsert(result, tmpArray[idx])
            table.remove(tmpArray, idx)
        end
        count = #tmpArray
    end
    
    return result
end

--- 计算数组内的每个数占总数的百分比，且总和保持100%
---@param array number[]
---@param decimals number 保留几位小数
---@return number[]
--------------------------
function XTool.CalArrayPercent(array, decimals)
    local result = {}
    if XTool.IsTableEmpty(array) then
        return result
    end
    decimals = math.max(decimals, 0)
    local decimal = 10 ^ decimals
    local hundred = 100
    
    local function addArray(arr, from, to)
        arr = arr or {}
        from = from or 1
        to = to or #arr
        
        local total = 0
        for i = from, to do
            total = total + arr[i]
        end
        return total
    end

    for idx, value in ipairs(array) do
        local leftTotal = addArray(array, idx)
        --四舍五入
        local percent = leftTotal <= 0 and 0.0 or math.floor(value / leftTotal * hundred * decimal + 0.5) / decimal
        if decimals == 0 then
            percent = math.floor(percent)
        end
        hundred = hundred - percent
        result[idx] = percent
    end
    return result
end

XTool.ResetInitSchedule = function()
    XTool.__InitSchedule = nil
end

--[[
    描述：调用函数时延迟到下一帧统一调用，避免同一个函数在同一帧多次调用
    使用场景：
        1.可在注册事件中调用, 多个事件重复触发，也仅在帧结束回调一次
        2.可在自己函数内使用，因逻辑上导致的多次触发可归为帧结束回调一次
]]
XTool.CallFunctionOnNextFrame = function(callback, caller, ...)
    return XTool._RegisterFunctionOnNextFrame(callback, caller, ...)
end

XTool._RegisterFunctionOnNextFrame = function(callback, caller, ...)
    if callback == nil then
        return false
    end
    if not XTool._IsAutoRefreshOnNextFrame then
        if caller then
            callback(caller, ...)
        else
            callback(...)
        end
        return true
    end
    XTool._FunctionsOnNextFrame = XTool._FunctionsOnNextFrame or {}
    local callerData
    -- 分开处理避免两个不同的类调用同一个方法导致其中一个调用缺失
    if caller then
        callerData = XTool._FunctionsOnNextFrame[caller] or {}
        callerData[callback] = {caller, ...}
        XTool._FunctionsOnNextFrame[caller] = callerData
    else
        callerData = XTool._FunctionsOnNextFrame["STATIC"] or {}
        callerData[callback] = {...}
        XTool._FunctionsOnNextFrame["STATIC"] = callerData
    end
    if not XTool.__InitSchedule then
        XTool.__InitSchedule = true
        XScheduleManager.ScheduleForever(XTool._AutoRefreshOnNextFrame, 0, 0)
    end
    return true
end

XTool._AutoRefreshOnNextFrame = function()
    if XTool.IsTableEmpty(XTool._FunctionsOnNextFrame) then
        return
    end
    for key, callbackDic in pairs(XTool._FunctionsOnNextFrame) do
        for callback, args in pairs(callbackDic) do
            callback(table.unpack(args))
        end
        XTool._FunctionsOnNextFrame[key] = nil
    end
end

XTool.ConnectSignal = function(source, path, event, callback, caller, returnArgKey)
    local controlVar = XTool._CheckSignalPath(source, path, event, callback, caller)
    if not controlVar then
        return
    end
    if caller == nil then
        caller = source
    end
    return XTool._ConnectSignal(controlVar, path, event, callback, caller, returnArgKey)
end

XTool.ConnectSignals = function(source, path, event, callback, caller)
    local controlVar = XTool._CheckSignalPath(source, path, event, callback, caller)
    if not controlVar then
        return
    end
    if caller == nil then
        caller = source
    end
    local result = {}
    for _, var in ipairs(controlVar) do
        table.insert(result, XTool._ConnectSignal(var, path, event, callback, caller))
    end
    return result
end

XTool._CheckSignalPath = function(source, path, event, callback, caller)
    local varNames = string.Split(path, "/")
    local controlVar = source
    for _, v in ipairs(varNames) do
        controlVar = controlVar[v]
        if controlVar == nil then
            XLog.Error("信号连接失败，请检查路径：", path)
            return
        end
    end
    return controlVar
end

XTool._ConnectSignal = function(controlVar, path, event, callback, caller, returnArgKey)
    local signalData = controlVar.SignalData
    if signalData == nil and CheckClassSuper(controlVar, XSignalData) then
        signalData = controlVar
    end
    if not signalData then
        XLog.Error("信号连接失败，查找对象不属于信号数据：", path)
        return
    end
    signalData:ConnectSignal(event, caller, callback, returnArgKey)
    return signalData
end

XTool.RegisterSignalWrap = function(source)
    local wrapResult = {}
    setmetatable(
        wrapResult,
        {
            __index = function(_, k)
                return source[k]
            end
        }
    )
    wrapResult.SignalData = XSignalData.New()
    wrapResult.__Source = source
    return wrapResult
end

XTool.GetTableNameByTablePath = function(tablePath)
    local tableParts = string.Split(tablePath, "/")
    return string.gsub(tableParts[#tableParts], ".tab", "")
end

--字符串转为Vector3 格式为 x|y|z
XTool.ConvertStringToVector3 = function(str)
    if string.IsNilOrEmpty(str) then
        return CS.UnityEngine.Vector3.zero
    end
    local values = string.Split(str,"|")
    local x = 0
    local y = 0
    local z = 0
    if values[1] then
        x = tonumber(values[1])
    end
    if values[2] then
        y = tonumber(values[2])
    end
    if values[3] then
        z = tonumber(values[3])
    end
    return CS.UnityEngine.Vector3(x, y, z)
end

XTool.Random = function(a, b)
    if nil ~= a and nil ~= b then
        if math.round(a) ~= a or math.round(b) ~= b then
            return a + math.random() * (b - a)
        end
        if a > b then
            XLog.Warning("math.random param b must be bigger than param a")
        end
        return math.random(a, b)
    elseif nil ~= a then
        return math.random(a)
    end
    return math.random()
end

-- 循坏分割字符串
XTool.LoopSplitStr = function(content, splitStr, splitLen)
    local totalLenght = string.Utf8Len(content)
    if totalLenght <= splitLen then
        return content
    end
    local result = string.Utf8Sub(content, 1, splitLen)
    local remaind = string.Utf8Sub(content, splitLen + 1, totalLenght - splitLen)
    result = result .. splitStr ..  XTool.LoopSplitStr(remaind, splitStr, splitLen)
    return result
end

-- 按位运算获取关卡星级标记
-- @stageFlags: 按位的星级标记
-- @starsCount: 星级最大数，默认是3
XTool.GetStageStarsFlag = function (stageFlags, starsCount)
    local count = 0
    local map = {}
    if not XTool.IsNumberValid(stageFlags) then
        return count, map
    end

    local flag = 1
    for i = 1, not XTool.IsNumberValid(starsCount) and 3 or starsCount do
        count = count + (stageFlags & flag > 0 and 1 or 0)
        map[i] = (stageFlags & flag) > 0
        flag = flag << 1
    end
    return count, map
end

-- 创建匿名proxy
XTool.CreateBattleRoomDetailProxy = function(customFunction)
    local XUiBattleRoomRoleDetailDefaultProxy = require("XUi/XUiNewRoomSingle/XUiBattleRoomRoleDetailDefaultProxy")
    local proxy = CreateAnonClassInstance(customFunction or {}, XUiBattleRoomRoleDetailDefaultProxy)
    return proxy
end

---获得贝塞尔曲线点
---@param time number 0到1的值，0获取曲线的起点，1获得曲线的终点
---@param startPoint UnityEngine.Vector3 曲线的起始位置
---@param center UnityEngine.Vector3 决定曲线形状的控制点
---@param endPoint UnityEngine.Vector3 曲线的终点
function XTool.GetBezierPoint(time, startPoint, center, endPoint)
    return (1 - time) * (1 - time) * startPoint + 2 * time * (1 - time) * center + time * time * endPoint
end

function XTool.StrToTable(str)
    local fn, err = load("return " .. str)
    if fn then
        return fn()
    else
        XLog.Error(err)
        return nil
    end
end

function XTool.SortIdTable(idTable, isDescend)
    table.sort(idTable, function(a, b) return isDescend and a > b or a < b end)
end 