XPerformance = XPerformance or {}

local CsTime = CS.UnityEngine.Time
local IO = CS.System.IO
local collectgarbage = collectgarbage
local AutoSaveTime = 10
local LastSaveTime = 0
local TraceLevel = 5

XPerformance.SaveDataPath = XPerformance.SaveDataPath or string.format("Log/MemData_%s.tab", CS.System.DateTime.Now:ToString("MMddhhmm"))
XPerformance.SaveTimerId = XPerformance.SaveTimerId or 0
XPerformance.LuaMemData = XPerformance.LuaMemData or {}

-- 定期保存数据
function XPerformance.StartLuaMenCollect()
    if CS.UnityEngine.Application.platform ~= CS.UnityEngine.RuntimePlatform.WindowsEditor then
        return 
    end
    if XPerformance.SaveTimerId then
        XScheduleManager.UnSchedule(XPerformance.SaveTimerId)
        XPerformance.SaveTimerId = 0
    end
    XPerformance.SaveTimerId = XScheduleManager.ScheduleForever(function()
        if not next(XPerformance.LuaMemData) then
            return
        end
        local nowTime = CsTime.realtimeSinceStartup
        if nowTime - LastSaveTime > AutoSaveTime then
            LastSaveTime = nowTime
            XPerformance.SaveMemData()
        end 
    end, AutoSaveTime * 1000)
end

-- 保存数据
function XPerformance.SaveMemData()
    local sw
    if not IO.File.Exists(XPerformance.SaveDataPath) then
        sw = IO.File.CreateText(XPerformance.SaveDataPath)
        sw:Write("traceName\tkey\tcostMem\tcurrentMem\n")
    else
        sw = IO.File.AppendText(XPerformance.SaveDataPath)
        sw:Write("\n")
    end

    local tab = {}
    for key, str in pairs(XPerformance.LuaMemData) do
        table.insert(tab, str)
    end
    XPerformance.LuaMemData = {}
    local content = table.concat(tab, '\n')
    sw:Write(content)
    sw:Flush()
    sw:Close()
    
    XLog.Debug("... save data:" .. content)
end

-- 记录一段代码消耗的lua内存
function XPerformance.RecordLuaMemData(name, func, isCollect)
    if isCollect == nil then
        isCollect = true
    end
    if isCollect then
        collectgarbage("collect")
    end
    local beforeMem = collectgarbage("count")
    func()
    if isCollect then
        collectgarbage("collect")
    end
    local currentMem = collectgarbage("count")

    local costMem = currentMem - beforeMem
    costMem = math.floor(costMem / 1024 * 10000) / 10000
    currentMem = math.floor(beforeMem / 1024 * 10000) / 10000 

    -- 记录消耗
    local traceName = XTool.GetStackTraceName(TraceLevel)
    local str = string.format("%s\t%s\t%s\t%s", traceName, name, costMem, currentMem)
    table.insert(XPerformance.LuaMemData, str)
end