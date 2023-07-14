local UnityPlayerPrefs = CS.UnityEngine.PlayerPrefs
-- local CsLog = CS.XLog
local CsInfo = CS.XInfo
local CsRemoteConfig = CS.XRemoteConfig

-- 应用版本模块
local XLaunchAppVersionModule = {}

local DOCUMENT_VERSION = "DOCUMENT_VERSION"
local LAUNCH_MODULE_VERSION = "LAUNCH_MODULE_VERSION"

local AppVersion

local OldDocVersion
local NewDocVersion

local OldLaunchModuleVersion
local NewLaunchModuleVersion

local IsCurAppVersionMatched = false
local IsCurDocVersionMatched = false
local IsCurLaunchModuleVersionMatched = false

local IsDocUpdated = true
local IsLaunchModuleUpdated = true


-- 初始化
local Init = function()
    AppVersion = CsInfo.Version
    IsCurAppVersionMatched = CsRemoteConfig.ApplicationVersion == AppVersion

    OldDocVersion = UnityPlayerPrefs.GetString(DOCUMENT_VERSION, CsInfo.Version)
    NewDocVersion = CsRemoteConfig.DocumentVersion
    IsCurDocVersionMatched = NewDocVersion == AppVersion
    IsDocUpdated = NewDocVersion == OldDocVersion

    OldLaunchModuleVersion = UnityPlayerPrefs.GetString(LAUNCH_MODULE_VERSION, CsInfo.Version)
    NewLaunchModuleVersion = CsRemoteConfig.LaunchModuleVersion
    IsCurLaunchModuleVersionMatched = AppVersion == NewLaunchModuleVersion
    IsLaunchModuleUpdated = OldLaunchModuleVersion == NewLaunchModuleVersion
end

-- local PrintVersion = function()
--     CsLog.Debug("AppVersion: " .. AppVersion)
--     CsLog.Debug("OldDocVersion: " .. OldDocVersion)
--     CsLog.Debug("NewDocVersion: " .. NewDocVersion)
--     CsLog.Debug("OldLaunchModuleVersion: " .. OldLaunchModuleVersion)
--     CsLog.Debug("NewLaunchModuleVersion: " .. NewLaunchModuleVersion)
-- end

function XLaunchAppVersionModule.GetAppVersion()
    return AppVersion
end

function XLaunchAppVersionModule.GetNewDocVersion()
    return NewDocVersion
end

function XLaunchAppVersionModule.GetNewLaunchModuleVersion()
    return NewLaunchModuleVersion
end

function XLaunchAppVersionModule.CheckAppUpdate()
    return not IsCurAppVersionMatched
end

function XLaunchAppVersionModule.CheckDocUpdate()
    return not IsCurDocVersionMatched
end

function XLaunchAppVersionModule.CheckLaunchModuleUpdate()
    return not IsCurLaunchModuleVersionMatched
end

function XLaunchAppVersionModule.HasDocUpdated()
    return IsDocUpdated
end

function XLaunchAppVersionModule.HasLaunchModuleUpdated()
    return IsLaunchModuleUpdated
end

function XLaunchAppVersionModule.UpdateDocVersion()
    OldDocVersion = NewDocVersion
    IsCurDocVersionMatched = NewDocVersion == AppVersion
    IsDocUpdated = NewDocVersion == OldDocVersion

    UnityPlayerPrefs.SetString(DOCUMENT_VERSION, CsRemoteConfig.DocumentVersion)
    UnityPlayerPrefs.Save()
end

function XLaunchAppVersionModule.UpdateLaunchVersion()
    OldLaunchModuleVersion = NewLaunchModuleVersion
    IsCurLaunchModuleVersionMatched = AppVersion == NewLaunchModuleVersion
    IsLaunchModuleUpdated = OldLaunchModuleVersion == NewLaunchModuleVersion

    UnityPlayerPrefs.SetString(LAUNCH_MODULE_VERSION, CsRemoteConfig.LaunchModuleVersion)
    UnityPlayerPrefs.Save()
end

Init()
--PrintVersion()

return XLaunchAppVersionModule