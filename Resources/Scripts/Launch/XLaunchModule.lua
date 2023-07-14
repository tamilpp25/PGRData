local CsApplication = CS.XApplication
local CsLog = CS.XLog
local CsInfo = CS.XInfo
local CsTool = CS.XTool
local CsStringEx = CS.XStringEx
local CsGameEventManager = CS.XGameEventManager.Instance
local IO = CS.System.IO

--Test 设置模式
--CsApplication.Mode = CS.XMode.Debug
print("Launch Version Code 1." )

RES_FILE_TYPE = {
    LAUNCH_MODULE = "launch",
    MATRIX_FILE = "matrix",
    CG_FILE = "cg",
}

local APP_PATH_MODULE_NAME = "XLaunchAppPathModule"
local APP_VERSION_MODULE_NAME = "XLaunchAppVersionModule"
local FILE_MODULE_NAME = "XLaunchFileModule"
local UI_MODULE_NAME = "XLaunchUiModule"

local PathModule = require(APP_PATH_MODULE_NAME)
local FileModuleCreator = require(FILE_MODULE_NAME)
local XLaunchUiModule = require(UI_MODULE_NAME)
local VersionModule

local LaunchFileModule
local DocFileModule

local IsReloaded = false
local ResFileUrlTable = {}

-- 游戏内强更
local ApkUrlList = nil
local OPPO_CHANNEL_ID = 1
local ApkListUrl = "client/patch/config.js"
local ApkFileName = "Punishing.apk"
local ApkSavePath = string.format("%s/%s", CS.UnityEngine.Application.persistentDataPath, ApkFileName)
local ApkFileSize = 0
local APK_TIMEOUT  = 5000 
-- local IsApkTesting = true -- 调试用

--- >>>>>>>>>>>>>>>>>>>>>>>>>> 私有方法 * 声明 >>>>>>>>>>>>>>>>>>>>>>>>>>
local CheckLaunchModuleUpdate
local CheckDocUpdate
local DownloadDlc

local OnCheckLaunchModuleComplete
local InitGame

local CheckDownloadChannel
local TryDownloadApk
local BeforeDownloadApk
local StartDownloadApk
--- <<<<<<<<<<<<<<<<<<<<<<<<<< 私有方法 * 声明 <<<<<<<<<<<<<<<<<<<<<<<<<<

GetResFileUrl = GetResFileUrl or nil

-- 注意：重载模块需要释放的对象
ShowStartErrorDialog = function(errorCode, confirmCB, cancelCB, cancelStr)
    CS.XHeroBdcAgent.BdcStartUpError(errorCode)
    confirmCB = confirmCB or CsApplication.Exit
    CsTool.WaitCoroutine(CsApplication.CoDialog(CsApplication.GetText("Tip"), CsApplication.GetText(errorCode), cancelCB, confirmCB, cancelStr))
end

--- >>>>>>>>>>>>>>>>>>>>>>>>>> 私有方法 * 定义 >>>>>>>>>>>>>>>>>>>>>>>>>>
CheckLaunchModuleUpdate = function()
    if not PathModule.IsEditorOrStandalone() or CsApplication.Mode == CS.XMode.Release then
        LaunchFileModule = FileModuleCreator()
        LaunchFileModule.Check(RES_FILE_TYPE.LAUNCH_MODULE, PathModule, VersionModule, OnCheckLaunchModuleComplete)
    else
        CheckDocUpdate()
    end
end

CheckDocUpdate = function()
    if not PathModule.IsEditorOrStandalone() or CsApplication.Mode == CS.XMode.Release then
        CsLog.Debug("Release 模式运行")
        DocFileModule = FileModuleCreator()
        DocFileModule.Check(RES_FILE_TYPE.MATRIX_FILE, PathModule, VersionModule, InitGame)
    elseif PathModule.IsEditorOrStandalone() and CsApplication.Mode == CS.XMode.Debug then
        CsLog.Debug("Debug 模式运行")
        InitGame()
    elseif PathModule.IsEditorOrStandalone() and CsApplication.Mode == CS.XMode.Editor then
        CsLog.Debug("Editor 模式运行")
        CS.XResourceManager.InitEditor()
        InitGame()
    end
end

DownloadDlc = function(progressCb,doneCb)
    if not PathModule.IsEditorOrStandalone() or CsApplication.Mode == CS.XMode.Release then
        CsLog.Debug("Release 模式运行")
        DocFileModule = FileModuleCreator()
        DocFileModule.Check(RES_FILE_TYPE.MATRIX_FILE, PathModule, VersionModule, doneCb,progressCb)
    elseif PathModule.IsEditorOrStandalone() and CsApplication.Mode == CS.XMode.Debug then
        CsLog.Debug("Debug 模式运行")
        doneCb()
    elseif PathModule.IsEditorOrStandalone() and CsApplication.Mode == CS.XMode.Editor then
        CsLog.Debug("Editor 模式运行")
        doneCb()
    end
end



OnCheckLaunchModuleComplete = function(urlTable, needUpdate, hasLocalFiles)
    if not needUpdate or IsReloaded then
        CheckDocUpdate()
        if hasLocalFiles then
            CS.XLaunchManager.SetUrlTable(urlTable)
        end
        return
    end

    CS.XUiManager.Instance:Clear()
    CS.XResourceManager.Clear()
    CS.XResourceManager.ClearFileDelegate()
    CS.XLaunchManager.SetUrlTable(urlTable)
    CS.XResourceManager.ResolveBundleManifest("launchmanifest")

    ShowStartErrorDialog = nil
    CheckUpdate = nil
    CS.XLaunchManager.GetLaunchUi = nil

    CS.XGame.ReloadLaunchModule()
end


InitGame = function(urlTable)
    urlTable = urlTable or {}
    for k, v in pairs(urlTable) do
        local url = ResFileUrlTable[k]
        if url then
            CS.XLog.Error("资源文件key重复，key:" .. tostring(k))
            return
        end
        ResFileUrlTable[k] = v
    end

    CsGameEventManager:Notify(CS.XEventId.EVENT_LAUNCH_START_LOADING)

    local import = CS.XLuaEngine.Import

    import("XLaunchCommon")
    import("XLaunchUi")

    --TODO
    GetResFileUrl = function(path)
        if not PathModule.IsEditorOrStandalone() or CsApplication.Mode == CS.XMode.Release then
            return ResFileUrlTable[path]
        elseif PathModule.IsEditorOrStandalone() and CsApplication.Mode == CS.XMode.Debug then
            return PathModule.GetDebugFilePath() .. "/" .. path
        else
            return path
        end
    end

    CS.XLaunchManager.GetPrimaryFileUrl = GetResFileUrl
    if not PathModule.IsEditorOrStandalone() or CsApplication.Mode == CS.XMode.Release then
        --
        CS.XResourceManager.ClearFileDelegate()
        CS.XResourceManager.AddFileDelegate(GetResFileUrl)

        CS.XResourceManager.ResolveBundleManifest("matrixmanifest")
    end
    CS.XGame.InitGame()
end
--- <<<<<<<<<<<<<<<<<<<<<<<<<< 私有方法 * 定义 <<<<<<<<<<<<<<<<<<<<<<<<<<

CheckUpdate = function(isReloaded)
    IsReloaded = isReloaded or false
    CS.XLaunchManager.GetLaunchUi = XLaunchUiModule.NewLaunchUi
    if not IsReloaded then
        XLaunchUiModule.RegisterLaunchUi()
    end

    --测试模式，初始化资源管理器
    if PathModule.IsEditorOrStandalone() and CsApplication.Mode == CS.XMode.Debug then
        CS.XResourceManager.InitBundleDebug(PathModule.GetDebugFilePath())
    elseif PathModule.IsEditorOrStandalone() and CsApplication.Mode == CS.XMode.Editor then
        CS.XResourceManager.InitEditor()
    end

    -- 开启Launch模块Ui
    CS.XUiManager.Instance:Open("UiLaunch")
    CS.XRecord.Record("50000", "UiLaunchand")

    VersionModule  = require(APP_VERSION_MODULE_NAME)
    if not PathModule.IsEditorOrStandalone() or CsApplication.Mode == CS.XMode.Release then
        CS.XHeroBdcAgent.BdcUpdateGame("201", "1", "0")
    end

    -- if IsApkTesting or VersionModule.CheckAppUpdate() then
    if VersionModule.CheckAppUpdate() then
        local tmpStr = CsStringEx.Format(CsApplication.GetText("UpdateApplication"), CsInfo.Version)
        CsTool.WaitCoroutine(CsApplication.CoDialog(CsApplication.GetText("Tip"), tmpStr, nil, function()
            local jumpCB = function()
                print("[Apk] - Failed to Download Apk.")
                CsTool.WaitCoroutine(CsApplication.GoToUpdateURL(PathModule.GetAppUpgradeUrl()), nil)
            end
            local downloadCB = function(url)
                BeforeDownloadApk(url)
            end
            TryDownloadApk(downloadCB, jumpCB)
        end))
    else
        -- 无需更新，并删除本地下载的Apk
        if CheckDownloadChannel() and IO.File.Exists(ApkSavePath) then
            print("[Apk] - Clean Apk path:" .. ApkSavePath)
            CS.XFileTools.DeleteFile(ApkSavePath)
        end

        if not PathModule.IsEditorOrStandalone() or CsApplication.Mode == CS.XMode.Release then
            CS.XHeroBdcAgent.BdcUpdateGame("202", "1", "0")
        end
        CheckLaunchModuleUpdate()
    end
end

GetAppUpgradeUrl = function ()
    return PathModule.GetAppUpgradeUrl()
end


--============包内下载apk逻辑=========
function CheckDownloadChannel()
    local channelId = CS.XHgSdkAgent.GetChannelId()
    return (channelId == OPPO_CHANNEL_ID)
end

-- 可在包内强更 调用downloadCB， 否则调用jumpCB跳转外链下载
function TryDownloadApk(downloadCB, jumpCB)
    -- if not IsApkTesting and not CheckDownloadChannel() then
    if not CheckDownloadChannel() then
        jumpCB()
        return
    end

    -- local channelId = IsApkTesting and OPPO_CHANNEL_ID or CS.XHeroSdkAgent.GetChannelId()
    local channelId = CS.XHgSdkAgent.GetChannelId()
    if ApkUrlList then
        if not ApkUrlList[channelId] then -- 兼容apkurl列表中内容错误
            jumpCB()
        else
            downloadCB(ApkUrlList[channelId])
        end
        return
    end

    local request = CS.XUriPrefixRequest.Get(ApkListUrl, nil, APK_TIMEOUT) 
    CS.XTool.WaitCoroutine(request:SendWebRequest(), function()
        if request.isNetworkError or request.isHttpError or not request.downloadHandler then
            CsLog.Error("[Apk] - Request apkList error:" .. tostring(request.error))
            jumpCB()
            return
        end

        local content = request.downloadHandler.text
        ApkUrlList = {}
        for k, v in string.gmatch(content, "\"(%d+)\" : \"(.-)\"") do
            local cid = tonumber(k)
            if not cid then
                CsLog.Error("[Apk] - Error format key:" .. tostring(k))
                jumpCB()
                return
            end
            ApkUrlList[cid] = v
        end
        downloadCB(ApkUrlList[channelId])
    end)
end

-- 获取apk大小并开始下载
function BeforeDownloadApk(apkUrl)
    print("[Apk] - Start Downloading Apk:" .. apkUrl)
    local request = CS.UnityEngine.Networking.UnityWebRequest.Head(apkUrl)
    request.timeout = APK_TIMEOUT
    CS.XTool.WaitNativeCoroutine(request:SendWebRequest(), function()
        if request.isNetworkError or request.isHttpError then
            CsLog.Error("[Apk] - Request ApkUrl error:" .. tostring(request.error))
            ShowStartErrorDialog("DownloadAPKError", function()
                BeforeDownloadApk(apkUrl)
            end)
            return
        end
        
        ApkFileSize = request:GetResponseHeader("Content-Length")
        print("[Apk] - Request ApkFileSize is " .. tostring(ApkFileSize))
        ApkFileSize = tonumber(ApkFileSize)
        StartDownloadApk(apkUrl)
    end)
end

function StartDownloadApk(apkUrl)
    print("[Apk] - Start to download.")
    CsGameEventManager:Notify(CS.XEventId.EVENT_LAUNCH_START_DOWNLOAD, ApkFileSize)

    local cache = true
    local sha1 = nil
    local downloader = CS.XDownloader(apkUrl, ApkSavePath, cache, sha1, APK_TIMEOUT)

    local isDownloading = false
    CS.XTool.WaitCoroutinePerFrame(downloader:Send(), function(isComplete)
        if not isComplete then
            if not isDownloading then
                isDownloading = true
                print("[Apk] - Init Download Apk Info:",  downloader.CurrentSize, ApkFileSize)
                CsGameEventManager:Notify(CS.XEventId.EVENT_LAUNCH_START_DOWNLOAD, ApkFileSize)
            end

            local downloadedSize = downloader.CurrentSize
            local progress = downloadedSize / ApkFileSize
            CsApplication.SetProgress(progress)

        else
            local localFileSize = 0
            if isDownloading then
                localFileSize = downloader.CurrentSize
            elseif IO.File.Exists(ApkSavePath) then
                local fs = IO.File.Open(ApkSavePath, IO.FileMode.Open, IO.FileAccess.Read, IO.FileShare.Read)
                localFileSize = tonumber(fs.Length)
                fs:Close()
            end
            local isFinish = (localFileSize == ApkFileSize)

            print("[Apk] - Finish Download:" .. tostring(downloader.State) .. ",  localFileSize:" .. localFileSize.. ",  Size:" .. ApkFileSize .. ", isFinish:" .. tostring(isFinish))
            if not isFinish then
                local function CleanAndDownload()
                    if IO.File.Exists(ApkSavePath) then
                        print("[Apk] - Clean downloaded Error File:" .. ApkSavePath)
                        CS.XFileTools.DeleteFile(ApkSavePath)
                    end
                    StartDownloadApk(apkUrl)
                end

                if isDownloading then -- 下载过程失败才询问
                    ShowStartErrorDialog("DownloadAPKError", CleanAndDownload, CsApplication.Exit)
                else
                    CleanAndDownload()
                end
                return
            end

            if downloader.State ~= CS.XDownloaderState.Success then
                CsLog.Error("[Apk] - Download Error state:" .. tostring(downloader.State) .. ", Exception:" .. tostring(downloader.Exception and downloader.Exception.Message))
                ShowStartErrorDialog("DownloadAPKError", function()
                    StartDownloadApk(apkUrl)
                end)
                return
            end

            CsApplication.SetProgress(1)
            CS.XTool.OpenFile(ApkSavePath, function(result)
                print("[Apk] - Open File result:" .. tostring(result))
                CsApplication.Exit()
            end)
        end
    end)
end
--============包内下载apk逻辑 end=========