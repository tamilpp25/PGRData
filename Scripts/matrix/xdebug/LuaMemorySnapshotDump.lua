local mri = require("XDebug/MemoryReferenceInfo")
mri.m_cConfig.m_bAllMemoryRefFileAddTime = false
LuaMemorySnapshotDump = {}

function LuaMemorySnapshotDump.BeforeSnapshot()
    collectgarbage("collect")
    mri.m_cMethods.DumpMemorySnapshot("./", "1-Before", -1)
end

function LuaMemorySnapshotDump.Test()
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

function LuaMemorySnapshotDump.AfterSnapshot()
    collectgarbage("collect")
    mri.m_cMethods.DumpMemorySnapshot("./", "2-After", -1)
end

function LuaMemorySnapshotDump.ComparedSnapshot()
    mri.m_cMethods.DumpMemorySnapshotComparedFile("./", "Compared", -1,
            "./LuaMemRefInfo-All-[1-Before].txt",
            "./LuaMemRefInfo-All-[2-After].txt")
end

function LuaMemorySnapshotDump.SnapshotObject(obj)
    collectgarbage("collect")
    mri.m_cMethods.DumpMemorySnapshotSingleObject("./", "SingleObjRef-Object", -1, nil, obj)
end


print("Init LuaMemorySnapshotDump")