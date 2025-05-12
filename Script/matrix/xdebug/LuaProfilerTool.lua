local mri = require("XDebug/MemoryReferenceInfo")
mri.m_cConfig.m_bAllMemoryRefFileAddTime = false

LuaProfilerTool = {}

local SaveRoot = false
if CS.UnityEngine.Application.platform == CS.UnityEngine.RuntimePlatform.WindowsEditor then
    SaveRoot = "./"
else
    SaveRoot = CS.UnityEngine.Application.persistentDataPath
end

function LuaProfilerTool.SetLuaMemoryRefOutputPrint(fun)
    mri.m_cCallback.m_cOutputPrint = fun
end

function LuaProfilerTool.ResetLuaMemoryRefOutputPrint()
    mri.m_cCallback.m_cOutputPrint = print
end

function LuaProfilerTool.BeforeSnapshot()
    collectgarbage("collect")
    mri.m_cMethods.DumpMemorySnapshot(SaveRoot, "1-Before", -1)
end

function LuaProfilerTool.Test()
    local author =
    {
        Name = "yaukeywang",
        Job = "Game Developer",
        Hobby = "Game, Travel, Gym",
        City = "Beijing",
        Country = "China",
        Ask = function (question)
            return "My answer is for your question: " .. question .. "."
        end
    }
    _G.Author = author
end

function LuaProfilerTool.AfterSnapshot()
    collectgarbage("collect")
    mri.m_cMethods.DumpMemorySnapshot(SaveRoot, "2-After", -1)
end

function LuaProfilerTool.ComparedSnapshot()
    mri.m_cMethods.DumpMemorySnapshotComparedFile("./", "Compared", -1,
            "./LuaMemRefInfo-All-[1-Before].txt",
            "./LuaMemRefInfo-All-[2-After].txt")
end

function LuaProfilerTool.SnapshotObject(obj)
    collectgarbage("collect")
    mri.m_cMethods.DumpMemorySnapshotSingleObject(SaveRoot, "SingleObjRef-Object", -1, nil, obj)
end

function LuaProfilerTool.SnapshotObjectOutput(obj)
    mri.m_cMethods.DumpMemorySnapshotSingleObject(nil, nil, -1, nil, obj)
end


pcall(function()
    ---@class LuaProfiler
    ---@field BeginSampleCustom fun(name:string):void
    ---@field EndSampleCustom fun():void
    LuaProfiler = require('MikuLuaProfiler').LuaProfiler
end)

print("LuaProfilerTool.Init Finish")