local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
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

XTool = XTool or
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

XTool.LoopHashSet = function(hashSet, func)
    if type(hashSet) == "table" then
        for _, value in pairs(hashSet) do
            func(value)
        end
    elseif type(hashSet) == "userdata" then
        local e = hashSet:GetEnumerator()

        while e:MoveNext() do
            func(e.Current)
        end
        e:Dispose()
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

XTool.CsHashSet2LuaTable = function(hashSet)
    local ret = {}
    local index = 1
    local e = hashSet:GetEnumerator()

    while e:MoveNext() do
        ret[index] = e.Current
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
        if type(o) ~= "table" then
            return o
        end
        if cache[o] then
            return cache[o]
        end

        local newO = {}

        cache[o] = newO
        
        for k, v in pairs(o) do
            newO[clone(k)] = clone(v)
        end

        local mTable = getmetatable(o)
        if type(mTable) == "table" then
            setmetatable(newO, mTable)
        end
        
        return newO
    end

    return clone(t)
end

local function IsConfig(t)
    return t.__metatable == "readonly table"
end

-- 兼容死循环引用
XTool.CloneEx = function(data, removeReadonly)
    if not data then
        return data
    end
    if type(data) ~= "table" or IsConfig(data) then
        return data
    end
    local visitedMap = {}
    -- 对于只读表，得等最后才赋值metatable只读约束
    local metatableMap = {}
    ---@type XQueue
    local queue = XQueue.New()
    queue:Enqueue(data)

    while (not queue:IsEmpty()) do
        -- curData是原始对象，obj是复制对象
        local curData = queue:Dequeue()
        local obj
        if visitedMap[curData] then
            obj = visitedMap[curData]
        else
            obj = {}
            visitedMap[curData] = obj
            local mTable = getmetatable(curData)
            if type(mTable) == "table" then
                metatableMap[obj] = mTable
            end
        end
        for k, v in pairs(curData) do
            local key
            if type(k) == "table" and not IsConfig(v) then
                if visitedMap[k] then
                    key = visitedMap[k]
                else
                    key = {}
                    visitedMap[k] = key
                    queue:Enqueue(k)
                    local mTable = getmetatable(curData)
                    if type(mTable) == "table" then
                        metatableMap[obj] = mTable
                    end
                end
            else
                key = k
            end
            local value
            if type(v) == "table" and not IsConfig(v) then
                if visitedMap[v] then
                    value = visitedMap[v]
                else
                    value = {}
                    visitedMap[v] = value
                    queue:Enqueue(v)
                    local mTable = getmetatable(curData)
                    if type(mTable) == "table" then
                        metatableMap[obj] = mTable
                    end
                end
            else
                value = v
            end
            obj[key] = value
        end
    end
    if not removeReadonly then
        for obj, metatable in pairs(metatableMap) do
            setmetatable(obj, metatable)
        end
    end
    return visitedMap[data]
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
    [10] = CS.XTextManager.GetText("Ten")
}

local RomanNumberText = {
    [0] = "",
    [1] = CS.XTextManager.GetText("RomanOne"),
    [2] = CS.XTextManager.GetText("RomanTwo"),
    [3] = CS.XTextManager.GetText("RomanThree"),
    [4] = CS.XTextManager.GetText("RomanFour"),
    [5] = CS.XTextManager.GetText("RomanFive"),
    [6] = CS.XTextManager.GetText("RomanSix"),
    [7] = CS.XTextManager.GetText("RomanSeven"),
    [8] = CS.XTextManager.GetText("RomanEight"),
    [9] = CS.XTextManager.GetText("RomanNine"),
    [10] = CS.XTextManager.GetText("RomanTen")
}

XTool.ParseNumberString = function(num)
    return NumberText[mathModf(num / 10)] .. NumberText[num % 10]
end

XTool.ConvertNumberString = function(num)
    return NumberText[num] or ""
end

XTool.ConvertRomanNumberString = function(num)
    return RomanNumberText[num] or ""
end

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

---@param uiObject UiObject
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

---用来监听收集赋值的C#对象
XTool.InitUiObjectNewIndex = function(tbl)
    local metaTbl = getmetatable(tbl)
    if not metaTbl.__newindex then
        tbl._uObjIndexes = {}
        metaTbl.__newindex = function(tbl, k, v)
            rawset(tbl, k, v)
            if v then
                --有值的, 有些界面会在close之后还对一些属性进行置空
                local t = type(v)
                if t == "userdata" and CsXUiHelper.IsUnityObject(v) then
                    if tbl._uObjIndexes then
                        table.insert(tbl._uObjIndexes, k)
                    else
                        if XMain.IsWindowsEditor then
                            XLog.Error(string.format("%s has been call ReleaseUiObjectIndex", tostring(tbl.Name)))
                        end
                    end
                end
            end
        end
        setmetatable(tbl, metaTbl)
    else
        if XMain.IsWindowsEditor then
            XLog.Error(string.format("tbl %s 已经存在__newindex元表", tostring(tbl.Name)))
        end
    end
end

XTool.ReleaseUiObjectIndex = function(tbl)
    if tbl.Obj and tbl.Obj:Exist() then
        local nameList = tbl.Obj.NameList
        for _, v in pairs(nameList) do
            tbl[v] = nil
        end
        tbl.Obj = nil
    end

    if tbl._uObjIndexes then
        for _, key in ipairs(tbl._uObjIndexes) do
            tbl[key] = nil
        end
        tbl._uObjIndexes = nil
    end
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
XTool.MathGetRoundingValueStandard = function(value, digit)
    return XTool.ValueStandard(XTool.MathGetRoundingValue(value, digit))
end

-- 去掉.0显示
XTool.ValueStandard = function(value)
    local floorNum = math.floor(value)
    if value == floorNum then return floorNum end
    return value
end

-- 直接使用math.pow
XTool.MathPow = function(a, b)
    return a ^ b
end

--[[
关系类型
1：任意一个等于
2：大于等于
3：小于等于
4：等于
--]]
XTool.CommonVariableCompare = function(compareType, ownValue, params, index)
    if compareType == 1 then
        return ownValue == params[index]
    elseif compareType == 2 then
        return ownValue >= params[index]
    elseif compareType == 3 then
        return ownValue <= params[index]
    elseif compareType == 4 then
        for i = index, #params do
            if ownValue == params[i] then
                return true
            end
        end
    end
    return false
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
    then
        --汉字/u4E00 -- /u9fbb
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
function XTool.RandomArray(array, randomseed, isChangeOrigin)
    if XTool.IsTableEmpty(array) then
        XLog.Warning("XTool.RandomArray: random array error: array is empty or not an array", array)
        return {}
    end
    math.randomseed(randomseed)
    
    local temp = isChangeOrigin and array or XTool.Clone(array)
    
    local count = #temp
    while count > 0 do
        local idx = math.random(1, count)
        --交换
        if idx ~= count then
            temp[idx], temp[count] = temp[count], temp[idx]
        end
        count = count - 1
    end
    return temp
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
        callerData[callback] = { caller, ... }
        XTool._FunctionsOnNextFrame[caller] = callerData
    else
        callerData = XTool._FunctionsOnNextFrame["STATIC"] or {}
        callerData[callback] = { ... }
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
    local values = string.Split(str, "|")
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
    result = result .. splitStr .. XTool.LoopSplitStr(remaind, splitStr, splitLen)
    return result
end

-- 将字符串中空格替换为不换行空格
XTool.ReplaceSpaceToNonBreaking = function(str)
    return string.gsub(str, " ", "\u{00A0}")
end

-- 按位运算获取关卡星级标记
-- @stageFlags: 按位的星级标记
-- @starsCount: 星级最大数，默认是3
XTool.GetStageStarsFlag = function(stageFlags, starsCount)
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
    table.sort(idTable, function(a, b)
        return isDescend and a > b or a < b
    end)
end

function XTool.DeepCompare(tbl1, tbl2)
    if tbl1 == tbl2 then
        return true
    end

    if type(tbl1) ~= "table" or type(tbl2) ~= "table" then
        return false
    end

    for k, v in pairs(tbl1) do
        if type(v) == "table" then
            if not XTool.DeepCompare(v, tbl2[k]) then
                return false
            end
        elseif v ~= tbl2[k] then
            return false
        end
    end

    for k, v in pairs(tbl2) do
        if type(v) == "table" then
            if not XTool.DeepCompare(v, tbl1[k]) then
                return false
            end
        elseif v ~= tbl1[k] then
            return false
        end
    end

    return true
end

--XTool.AbandonedTable = {}
local function ErrorAbandon()
    if XMain.IsDebug then
        XLog.Error("[XConfigUtil] config已被移除,如果看到此提示,麻烦您通知ZLB,谢谢")
        --local str = debug.traceback()
        --XTool.AbandonedTable[str] = true
    end
end

local function GetTableNonsense()
    local t = {}
    local tableUsed = {
        Init = function()
        end,
        __Configs = false
    }
    local metatable = {
        __newindex = function(table, key, value)
            tableUsed[key] = value
        end,
        __index = function(table, key)
            if type(key) == "number" then
                return nil
            end
            if tableUsed[key] ~= nil then
                return tableUsed[key]
            end
            ErrorAbandon()
            return t
        end,
        __call = function()
            ErrorAbandon()
            return t
        end,
        __add = function()
            ErrorAbandon()
            return 0
        end,
        __sub = function()
            ErrorAbandon()
            return 0
        end,
        __mul = function()
            ErrorAbandon()
            return 0
        end,
        __div = function()
            ErrorAbandon()
            return 0
        end,
        __unm = function()
            ErrorAbandon()
            return 0
        end,
        __mod = function()
            ErrorAbandon()
            return 0
        end,
        __pow = function()
            ErrorAbandon()
            return 0
        end,
        __concat = function()
            ErrorAbandon()
            return ""
        end,
        __eq = function()
            --ErrorAbandon()
            return false
        end,
        __lt = function()
            ErrorAbandon()
            return true
        end,
        __le = function()
            ErrorAbandon()
            return false
        end,
        __tostring = function()
            ErrorAbandon()
            return ""
        end
    }
    setmetatable(t, metatable)
    return t
end

function XTool.GetNoneSenseTable()
    return GetTableNonsense()
end

---@param anim UnityEngine.Playables.PlayableDirector
---@param directorWrapMode number UnityEngine.Playables.DirectorWrapMode
function XTool.PlayTimeLineAnim(anim, time, directorWrapMode)
    if not anim then
        return
    end
    anim.initialTime = time or 0
    if directorWrapMode then
        anim.extrapolationMode = directorWrapMode
    end
    anim:Evaluate()
    anim:Play()
end

function XTool.RemoveRichText(str)
    local result = string.gsub(str, "<[^>]+>", "")
    return result
end

function XTool.DebugIsShowItemIdOnUi()
    if not XMain.IsWindowsEditor then
        return false
    end
    local value = CS.UnityEngine.PlayerPrefs.GetInt("DebugIsShowItemIdOnUi")
    return value ~= 0
end

function XTool.DebugInverseShowItemIdOnUi()
    local value = CS.UnityEngine.PlayerPrefs.GetInt("DebugIsShowItemIdOnUi")
    if value == 0 then
        value = 1
    else
        value = 0
    end
    return CS.UnityEngine.PlayerPrefs.SetInt("DebugIsShowItemIdOnUi", value)
end

function XTool.Shuffle(list)
    if XTool.IsTableEmpty(list) then
        return
    end
    for i = #list, 1, -1 do
        local index = XTool.Random(1, i)
        local swap = list[i]
        list[i] = list[index]
        list[index] = swap
    end
end

---@param gridArray XUiNode[]
function XTool.UpdateDynamicItem(gridArray, dataArray, uiObject, class, parent)
    if #gridArray == 0 and uiObject then
        uiObject.gameObject:SetActiveEx(false)
    end
    local dataCount = dataArray and #dataArray or 0
    for i = 1, dataCount do
        local grid = gridArray[i]
        if not grid then
            local ui = CS.UnityEngine.Object.Instantiate(uiObject, uiObject.transform.parent)
            grid = class.New(ui, parent)
            gridArray[i] = grid
        end
        grid:Open()
        grid:Update(dataArray[i], i)
    end
    for i = dataCount + 1, #gridArray do
        local grid = gridArray[i]
        grid:Close()
    end
end

function XTool.UpdateDynamicGridCommon(gridArray, dataArray, uiObject, parent)
    if #gridArray == 0 then
        uiObject.gameObject:SetActiveEx(false)
    end
    for i = 1, #dataArray do
        local grid = gridArray[i]
        if not grid then
            local ui = CS.UnityEngine.Object.Instantiate(uiObject, uiObject.transform.parent)
            grid = XUiGridCommon.New(parent, ui)
            gridArray[i] = grid
        end
        grid.GameObject:SetActiveEx(true)
        grid:Refresh(dataArray[i])
    end
    for i = #dataArray + 1, #gridArray do
        local grid = gridArray[i]
        grid.GameObject:SetActiveEx(false)
    end
end

function XTool.SaveConfig(path, toSave, headTable, isTable)
    local content = XTool.GetConfigContent(toSave, headTable, isTable)
    XTool.SaveConfigByContent(path, content)
end

function XTool.SaveConfigByContent(path, content)
    CS.System.IO.File.WriteAllText(path, content, CS.System.Text.Encoding.GetEncoding("GBK"));
end

function XTool.GetConfigContent(toSave, headTable, isTable)
    local defaultTable = { 0 }

    -- 收集数组
    local headTableAmount = {}
    for i, config in pairs(toSave) do
        for j = 1, #headTable do
            local key = headTable[j]
            local value = config[key]
            if isTable[key] then
                value = value or defaultTable
                local amount = #value
                amount = math.max(amount, 1)
                if (not headTableAmount[key]) or (headTableAmount[key] < amount) then
                    headTableAmount[key] = amount
                end
            else
                headTableAmount[key] = 0
            end
        end
    end

    local contentTable = {}
    for i = 1, #headTable do
        local key = headTable[i]
        local amount = headTableAmount[key] or 0
        if amount == 0 then
            contentTable[#contentTable + 1] = key
            contentTable[#contentTable + 1] = '\t'
        else
            for j = 1, amount do
                contentTable[#contentTable + 1] = key
                contentTable[#contentTable + 1] = '['
                contentTable[#contentTable + 1] = j
                contentTable[#contentTable + 1] = ']'
                contentTable[#contentTable + 1] = '\t'
            end
        end
    end
    contentTable[#contentTable] = nil
    contentTable[#contentTable + 1] = "\r\n"

    for i, config in pairs(toSave) do
        for j = 1, #headTable do
            local key = headTable[j]
            local value = config[key]
            if isTable[key] then
                value = value or defaultTable
                local size = headTableAmount[key]
                for k = 1, size do
                    local element = value[k]
                    if element then
                        contentTable[#contentTable + 1] = element
                    end
                    contentTable[#contentTable + 1] = '\t'
                end
            else
                contentTable[#contentTable + 1] = value
                contentTable[#contentTable + 1] = '\t'
            end
        end
        contentTable[#contentTable] = nil
        contentTable[#contentTable + 1] = "\r\n"
    end
    local content = table.concat(contentTable)
    return content
end

function XTool.IsFileExists(filePath)
    local file = io.open(filePath, "r")
    if file then
        io.close(file)
        return true
    else
        return false
    end
end

function XTool.ExtractFilenameWithoutExtension(path)
    -- 找到最后一个"/"和最后一个"."的位置
    local lastSlash = path:find("/[^/]*$")
    local lastDot = path:find("%.[^%.]*$")
    
    -- 如果找到了"."，并且它在"/"的后面，就去掉后缀
    if lastDot and lastDot > lastSlash then
        return path:sub(lastSlash+1, lastDot-1)
    else
        -- 如果没有找到"."，或者"."在"/"的前面，就返回整个文件名
        return path:sub(lastSlash+1)
    end
end

-- 找到table中离X最近的且小于X的数字
function XTool.FindClosestNumber(t, X, key)
    local closest = nil
    local min_diff = math.huge  -- 初始设为无穷大

    -- 遍历 table 中的每个元素
    for _, element in ipairs(t) do
        local num
        if key then
            -- 如果传入了 key，取出子 table 中对应 key 的值
            num = element[key]
        else
            -- 没有传入 key，直接使用元素值
            num = element
        end

        -- 确保 num 是一个数值并且小于等于 X
        if num and num <= X then
            local diff = math.abs(X - num)  -- 计算与 X 的绝对差值
            if diff < min_diff then  -- 找到更小的差值时更新
                min_diff = diff
                closest = element  -- 记录当前的最接近值
            end
        end
    end

    return closest  -- 返回最接近的元素
end

-- C#列表转lua的table
function XTool.ListToTable(list)
    local listTable = {}
    for i, v in pairs(list) do
        table.insert(listTable, v)
    end
    return listTable
end

-- 实现过滤器功能
---@param list table 需要过滤的列表
---@param filter function 过滤器函数
---@return table 过滤后的列表
function XTool.FilterList(list, filter)
    local result = {}
    for _, v in pairs(list) do
        if filter(v) then
            tableInsert(result, v)
        end
    end
    return result
end
