XMain = XMain or {}
XMain.IsEditorDebug = true

local lockGMeta = {
    __newindex = function(t, k)
        XLog.Error("can't assign " .. k .. " in _G")
    end,
    __index = function(t, k)
        XLog.Error("can't index " .. k .. " in _G, which is nil")
    end
}

function LuaLockG()
    setmetatable(_G, lockGMeta)
end

function import(fileName)
    XLuaEngine:Import(fileName)
end

import("Common/XClass.lua")
import("Common/XTool.lua")
import("Common/XLog.lua")

XMain.StepDlc = function()
    require("Common/XDlcNpcAttribType")
    require("XDlcScriptManager")
    require("DlcHotReload/XDlcHotReload")

    LuaLockG()
end