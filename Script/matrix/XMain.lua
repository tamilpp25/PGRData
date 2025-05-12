XMain = XMain or {}

XMain.IsWindowsEditor = CS.UnityEngine.Application.platform == CS.UnityEngine.RuntimePlatform.WindowsEditor
local IsWindowsPlayer = CS.UnityEngine.Application.platform == CS.UnityEngine.RuntimePlatform.WindowsPlayer

XMain.IsDebug = CS.XRemoteConfig.Debug
XMain.IsEditorDebug = (XMain.IsWindowsEditor or IsWindowsPlayer) and XMain.IsDebug

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

local import = CS.XLuaEngine.Import

import("XCommon/XLog.lua")

XMain.Step1 = function()
    --打点
    CS.XRecord.Record("23000", "LuaXMainStart")

    if XMain.IsEditorDebug then
        require("XDebug/LuaProfilerTool")
        require("XHotReload")
        require("XDebug/WeakRefCollector")
    end

    require("XCommon/XRpc")
    import("XCommon")
    require("Binary/ReaderPool")
    require("Binary/CryptoReaderPool")
    import("XConfig")
    require("XModule/XEnumConst")
    require("MVCA/XMVCA") --MVCA入口
    require("XGame")

    require("XEntity/ImportXEntity")
    
    import("XBehavior")
    import("XGuide")
    require("XMovieActions/XMovieActionBase")
    CS.XApplication.SetProgress(0.52)
end

XMain.Step2 = function()
    require("XManager/XUi/XLuaUiManager")
    import("XManager")

    XMVCA:InitModule()
    XMVCA:InitAllAgencyRpc()

    import("XNotify")
    CS.XApplication.SetProgress(0.54)
end

XMain.Step3 = function()
    import("XHome")
    import("XScene")
    require("XUi/XUiCommon/XUiCommonEnum")
    require("XCommon/XFightUtil")
    CS.XApplication.SetProgress(0.68)
end

XMain.Step4 = function()
    LuaLockG()
    --打点
    CS.XRecord.Record("23008", "LuaXMainStartFinish")
end

-- 待c#移除
XMain.Step5 = function()
end

XMain.Step6 = function()
end

XMain.Step7 = function()
end

XMain.Step8 = function()
end

XMain.Step9 = function()
end