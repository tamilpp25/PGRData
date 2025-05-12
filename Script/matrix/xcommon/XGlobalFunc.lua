local coroutineRunning = coroutine.running
local coroutineResume = coroutine.resume
local coroutineYield = coroutine.yield
local coroutineWrap = coroutine.wrap
local tablePack = table.pack
local tableUnpack = table.unpack
local select = select

function Handler(target, func)
    return function(...)
        return func(target, ...)
    end
end
handler = Handler

function LuaGC()
    collectgarbage("collect")
end

--回调转异步任务（需和RunAsyn配合使用）
---@param func: 带回调的function类型, 示例:local testFunc = function(..., callback) end
---@param callbackPos: 回调在参数列表中的位置, 传nil默认为最后一位, 示例:local testFunc = function(p1, p2, callback) end-->callbackPos = 3
---@return asynTask：不处理原函数返回值，异步需求默认void，原函数中的callback回调将不再可用，必须传nil）
---@Examplemple
--[[   
    local testFunc = function(str, cb)
        XScheduleManager.ScheduleOnce(function()
            XLog.Debug(str)
            if cb then cb() end
        end, XScheduleManager.SECOND)
    end

    --callback hell
    XLog.Debug("test callback begin")
    testFunc("test callback CallBack 1"
    , function()
        testFunc("test callback CallBack 2"
        , function()
            testFunc("test callback CallBack 3")
        end)
    end)
    XLog.Debug("test callback end")

    --asyn task
    XLog.Debug("test asyn task begin")
    local asynTest = asynTask(testFunc)
    RunAsyn(function()
        asynTest("test asyn CallBack 1")
        XLog.Debug("test asyn after 1")
        asynTest("test asyn CallBack 2")
        asynTest("test asyn CallBack 3")
    end)
    XLog.Debug("test asyn task end")
]]
function asynTask(func, caller, callbackPos)
    return function(...)
        local results = {}
        local isSync  --同步方法，回调直接执行
        local args = { ... }
        local running = coroutineRunning()
        callbackPos = callbackPos or select("#", ...) + 1 -- 往当前参数列表，加入控制继续执行的回调
        args[callbackPos] = function()
            isSync = true
            coroutineResume(running, tableUnpack(results))
        end
        results = caller and tablePack(func(caller, tableUnpack(args))) or tablePack(func(tableUnpack(args)))
        return not isSync and coroutineYield() or nil
    end
end

--异步等待second秒（需和RunAsyn配合使用）
function asynWaitSecond(second)
    asynTask(
    function(cb)
        XScheduleManager.ScheduleOnce(cb, second * XScheduleManager.SECOND)
    end
    )()
end

--异步执行
function RunAsyn(func)
    return coroutineWrap(func)()
end

function appendArray(dst, src)
    if src == nil then return dst end
    for i, v in ipairs(src) do
        table.insert(dst, v)
    end
    return dst
end

-- 保留digit位小数
function getRoundingValue(value, digit)
    return math.floor(value * math.pow(10, digit)) / math.pow(10, digit)
end

function math.roundDecimals(value, digit)
    local powValue = math.pow(10, digit)

    return math.round(value * powValue) / powValue
end

function math.pow(a, b)
    return a ^ b
end

function math.round(value)
    return math.floor(value + 0.5)
end

function table.indexof(array, value, begin)
    for i = begin or 1, #array do
        if array[i] == value then
            return i
        end
    end
    return false
end

--- 判断是否包含元素
---@param tbl table
---@param ele string
function table.contains(tbl, ele)
    for i, v in pairs(tbl) do
        if v == ele then
            return true, i
        end
    end
    return false
end

--- 字典转数组
---@param tbl table
---@param valueKey string
---@param ele string
function table.containsKey(tbl, valueKey, ele)
    for i, v in pairs(tbl) do
        if (v[valueKey] or v[valueKey]()) == ele then
            return true, i
        end
    end
    return false
end

--- 数组转字典
---@param dic table
---@param keyName string
---@param valueName string
function table.dicToArray(dic, keyName, valueName)
    keyName = keyName or "key"
    valueName = valueName or "value"
    local array = {}
    for k, v in pairs(dic) do
        array[#array + 1] = {
            [keyName] = k,
            [valueName] = v
        }
    end
    return array
end

--- 数组转字典
---@param array table
function table.arrayToDic(array)
    local dic = {}
    for i, v in ipairs(array) do
        dic[v] = i
    end
    return dic
end

--- 数组截取
---@param t table
---@param start number
---@param count number
function table.range(t, start, count)
    local ret = {}
    for i = start, start + count - 1 do
        ret[#ret + 1] = t[i]
    end
    return ret
end


--- 数组数量
function table.nums(t)
    return XTool.GetTableCount(t)
end

--[[
    @desc: 列表去重
    --@t:需要去重的列表
    --@bArray:  true    更新列表的所有为新索引
                false   保留元素原来的索引
    @return:去重后的列表
]]
function table.unique(t, bArray)
    local check = {}
    local n = {}
    local idx = 1
    for k, v in ipairs(t) do
        if not check[v] then
            if bArray then
                n[idx] = v
                idx = idx + 1
            else
                n[k] = v
            end
            check[v] = true
        end
    end
    return n
end

-- 反转数组不产生新数组
function table.reverse(t)
    local len = #t
    local mid = math.floor(len / 2)
    for i = 1, mid do
        t[i], t[len - i + 1] = t[len - i + 1], t[i]
    end
    return t
end

--程序暂停
function ApplicationPause(pause)
    if XEventManager then
        XEventManager.DispatchEvent(XEventId.EVENT_APPLICATION_PAUSE, pause)
    end
end

function ApplicationQuit()
    if XEventManager then
        XEventManager.DispatchEvent(XEventId.EVENT_APPLICATION_QUIT)
    end
    XTableManager.ReleaseIo()
end