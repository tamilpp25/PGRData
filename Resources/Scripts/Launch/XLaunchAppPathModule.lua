local UnityApplication = CS.UnityEngine.Application
local UnityRuntimePlatform = CS.UnityEngine.RuntimePlatform

local CsApplication = CS.XApplication
-- local CsLog = CS.XLog
local CsInfo = CS.XInfo

-- 应用路径模块
local XLaunchAppPathModule = {}

local RuntimePlatform = {
    ANDROID = 1,
    IOS = 2,
    EDITOR = 3,
    STANDALONE = 4,
}

local CurRuntimePlatform
local IsEditorOrStandalone
local PLATFORM

-- platform
local DocumentUrl
local ConfigUrl
local ApplicationFilePath

-- editor/standalone
local ProductPath
local DebugFilePath

-- common
local AppUpgradeUrl
local DocumentFilePath

-- Local Function
local function Init()
    AppUpgradeUrl = "client/patch"
    DocumentFilePath = UnityApplication.persistentDataPath .. "/document"

    if UnityApplication.platform == UnityRuntimePlatform.Android then
        -- 安卓平台
        CurRuntimePlatform = RuntimePlatform.ANDROID
        PLATFORM = "android"
        DocumentUrl = "client/patch/" .. CsInfo.Identifier .. "/" .. CsInfo.Version .. "/android"
        ConfigUrl = "client/config/" .. CsInfo.Identifier .. "/" .. CsInfo.Version .. "/android"
        ApplicationFilePath = UnityApplication.streamingAssetsPath .. "/resource"
    elseif UnityApplication.platform == UnityRuntimePlatform.IPhonePlayer then
        -- iOS平台
        CurRuntimePlatform = RuntimePlatform.IOS
        PLATFORM = "ios"
        DocumentUrl = "client/patch/" .. CsInfo.Identifier .. "/" .. CsInfo.Version .. "/ios"
        ConfigUrl = "client/config/" .. CsInfo.Identifier .. "/" .. CsInfo.Version .. "/ios"
        ApplicationFilePath = UnityApplication.streamingAssetsPath .. "/resource"
    else
        --
        PLATFORM = "win"
        if UnityApplication.platform == UnityRuntimePlatform.WindowsEditor or
                UnityApplication.platform == UnityRuntimePlatform.OSXEditor or
                UnityApplication.platform == UnityRuntimePlatform.LinuxEditor then
            -- 编辑器平台
            PLATFORM = CS.XLaunchManager.PLATFORM   --编辑器平台，随平台选择而变化
            CurRuntimePlatform = RuntimePlatform.EDITOR
            DocumentUrl = "client/patch/" .. CsInfo.Identifier .. "/" .. CsInfo.Version .. "/editor"
            ConfigUrl = "client/config/" .. CsInfo.Identifier .. "/" .. CsInfo.Version .. "/editor"
            ProductPath = UnityApplication.dataPath .. "/../../../Product"
            DebugFilePath = ProductPath .. "/File/win/debug"
            ApplicationFilePath = ProductPath .. "/File/" .. PLATFORM .. "/release"
        elseif UnityApplication.platform == UnityRuntimePlatform.WindowsPlayer or
                UnityApplication.platform == UnityRuntimePlatform.OSXPlayer or
                UnityApplication.platform == UnityRuntimePlatform.LinuxPlayer then
            -- 电脑系统平台
            CurRuntimePlatform = RuntimePlatform.STANDALONE
            DocumentUrl = "client/patch/" .. CsInfo.Identifier .. "/" .. CsInfo.Version .. "/standalone"
            ConfigUrl = "client/config/" .. CsInfo.Identifier .. "/" .. CsInfo.Version .. "/standalone"
            ProductPath = UnityApplication.dataPath .. "/../../../../.."
            DebugFilePath = ProductPath .. "/File/win/debug"
            ApplicationFilePath = CsApplication.Debug and ProductPath .. "/File/" .. PLATFORM .. "/release"
            or UnityApplication.streamingAssetsPath .. "/resource"
            if not CsApplication.Debug then 
                -- Release包 资源目录跟安装目录相同
                DocumentFilePath = UnityApplication.streamingAssetsPath .. "/document"
            end
        end
    end
    IsEditorOrStandalone = CurRuntimePlatform == RuntimePlatform.EDITOR or CurRuntimePlatform == RuntimePlatform.STANDALONE
end

-- local function PrintPath()
--     --
--     CsLog.Error("Check files. PLATFORM = " .. PLATFORM)
--     CsLog.Error("Check files. DocumentUrl = " .. DocumentUrl)
--     CsLog.Error("Check files. ConfigUrl = " .. ConfigUrl)
--     CsLog.Error("Check files. ApplicationFilePath = " .. ApplicationFilePath)
--     CsLog.Error("Check files. ProductPath = " .. ProductPath)
--     CsLog.Error("Check files. DebugFilePath = " .. DebugFilePath)
-- end

Init()
--PrintPath()

function XLaunchAppPathModule.IsEditorOrStandalone()
    return IsEditorOrStandalone
end

function XLaunchAppPathModule.GetApplicationFilePath()
    return ApplicationFilePath
end

function XLaunchAppPathModule.GetDocumentFilePath()
    return DocumentFilePath
end

function XLaunchAppPathModule.GetDebugFilePath()
    return DebugFilePath
end

function XLaunchAppPathModule.GetDocumentUrl()
    return DocumentUrl
end

function XLaunchAppPathModule.GetConfigUrl()
    return ConfigUrl
end

function XLaunchAppPathModule.GetAppUpgradeUrl()
    return AppUpgradeUrl
end

return XLaunchAppPathModule