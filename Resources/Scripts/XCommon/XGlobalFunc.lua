local coroutineRunning = coroutine.running
local coroutineResume = coroutine.resume
local coroutineYiled = coroutine.yield
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
---@param function类型, 最后一位参数为异步回调, 示例:local testFunc = function(..., callback) end
---@return 异步任务（不处理原函数返回值，异步需求默认void）
---@Examplemple
--[[   
    local testFunc = function(str, cb)
        XScheduleManager.ScheduleOnce(function()
            XLog.Debug(str)
            if cb then cb() end
        end, XScheduleManager.SECOND)
    end

    --callback hell
    XLog.Debug("kkkttt test callback begin")
    testFunc("kkkttt test callback CallBack 1"
    , function()
        testFunc("kkkttt test callback CallBack 2"
        , function()
            testFunc("kkkttt test callback CallBack 3")
        end)
    end)
    XLog.Debug("kkkttt test callback end")

    --asyn task
    XLog.Debug("kkkttt test asyn task begin")
    local asynTest = asynTask(testFunc)
    RunAsyn(function()
        asynTest("kkkttt test asyn CallBack 1")
        XLog.Debug("kkkttt test asyn after 1")
        asynTest("kkkttt test asyn CallBack 2")
        asynTest("kkkttt test asyn CallBack 3")
    end)
    XLog.Debug("kkkttt test asyn task end")
]]
function asynTask(func, caller)
    return function(...)
        local results = {}

        local running = coroutineRunning()
        local args = { ... }
        local length = select("#", ...) + 1
        args[length] = function()
            coroutineResume(running, tableUnpack(results))
        end

        results = caller and tablePack(func(caller, tableUnpack(args))) or tablePack(func(tableUnpack(args)))

        return coroutineYiled()
    end
end

--异步等待second秒（需和RunAsyn配合使用）
function asynWaitSecond(second)
    asynTask(function(cb)
        XScheduleManager.ScheduleOnce(cb, second * XScheduleManager.SECOND)
    end)()
end

--异步执行
function RunAsyn(asynFunc)
    return coroutineWrap(asynFunc)()
end

-- function string.split(input, delimiter)
--     input = tostring(input)
--     delimiter = tostring(delimiter)
--     if (delimiter=='') then return false end
--     local pos,arr = 0, {}
--     for st,sp in function() return string.find(input, delimiter, pos, true) end do
--         table.insert(arr, string.sub(input, pos, st - 1))
--         pos = sp + 1
--     end
--     table.insert(arr, string.sub(input, pos))
--     return arr
-- end

function appendArray(dst, src)
    for i, v in ipairs(src)do
        table.insert(dst, v)
    end
    return dst
end

-- 保留digit位小数
function getRoundingValue(value, digit)
    return math.floor( value * math.pow(10, digit) ) / math.pow(10 , digit)
end

function math.pow(a, b)
    return a ^ b
end

function table.indexof(array, value, begin)
    for i = begin or 1, #array do
        if array[i] == value then return i end
    end
    return false
end