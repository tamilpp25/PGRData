--这是预下载文件移动模块
local CsLog = CS.XLog
local CsRemoteConfig = CS.XRemoteConfig
local CSPlayerPrefs = CS.UnityEngine.PlayerPrefs
local UnityApplication = CS.UnityEngine.Application
local CSDirectory = CS.System.IO.Directory
local CSXFileTool = CS.XFileTool
local CsApplication = CS.XApplication
local CsGameEventManager = CS.XGameEventManager.Instance
local CsTool = CS.XTool

---@return XLaunchPreloadModule
local module_creator = function()
    ---@class XLaunchPreloadModule
    local XLaunchPreloadModule = {}
    local PrefKeys = {
        PreloadCompleteKey = "__kuro_preload_complete__",
        PreloadIndexKey = "__kuro_preload_index__",
        PreloadDlcIdsKey = "__kuro_preload_dlc_ids__"
    }
    local PreloadIndexName = "preindex"

    XLaunchPreloadModule.PrefKeys = PrefKeys
    XLaunchPreloadModule.PreloadIndexName = PreloadIndexName

    local ResFileType = nil
    local DocumentDir = nil
    local NewVersion = ""
    local OnProgress = nil
    local OnComplete = nil
    local FileCount = 0
    local PreFilesList = nil

    local PreloadDirPath = nil

    function XLaunchPreloadModule.Check(resFileType, documentDir, newVersion, onProgress, onComplete)
        ResFileType = resFileType
        DocumentDir = documentDir
        NewVersion = newVersion
        OnProgress = onProgress
        OnComplete = onComplete

        FileCount = 0
        PreFilesList = nil

        PreloadDirPath = UnityApplication.persistentDataPath .. "/preload" .. "/" .. ResFileType
        CsLog.Debug("[XLaunchPreloadModule] 开始检查预下载文件(多线程): " .. tostring(ResFileType))
        XLaunchPreloadModule.StartMovePreFiles()
    end

    --多线程移动文件
    function XLaunchPreloadModule.MoveThread()
        local moveHelper = CS.XFileMoveHelper(PreloadDirPath, DocumentDir)
        CsTool.WaitCoroutinePerFrame(moveHelper, function(isComplete)
            if isComplete then
                CsApplication.SetProgress(1)
                if OnProgress then --更新进度
                    OnProgress(1)
                end
                XLaunchPreloadModule.MovePreFilesComplete()
            else
                local progress = moveHelper.Progress
                if OnProgress then --更新进度
                    OnProgress(progress)
                end
                CsApplication.SetProgress(progress)
            end
        end)
    end
    

    --开始移动文件
    function XLaunchPreloadModule.StartMovePreFiles()
        local preloadVersion = CSPlayerPrefs.GetString(PrefKeys.PreloadIndexKey, "")
        CsLog.Debug("[XLaunchPreloadModule] 预下载版本号, preloadVersion: " .. preloadVersion)
        if (preloadVersion and #preloadVersion > 0) and preloadVersion <= NewVersion then
            if CSDirectory.Exists(PreloadDirPath) and CSDirectory.Exists(DocumentDir) then
                CsLog.Debug("[XLaunchPreloadModule] 开始移动预下载文件...")

                PreFilesList = CSXFileTool.GetFiles(PreloadDirPath)
                FileCount = PreFilesList.Count

                if FileCount == 0 then
                    XLaunchPreloadModule.MovePreFilesComplete()
                else
                    CsGameEventManager:Notify(CS.XEventId.EVENT_LAUNCH_START_DOWNLOAD, FileCount, false, CsApplication.GetText("MovePreload") .. "(%d/%d)") -- 解压资源
                    CsApplication.SetProgress(0)
                    CsApplication.SetMessage(CsApplication.GetText("MovePreload"))--"资源检查中……"

                    XLaunchPreloadModule.MoveThread()
                end
            else
                XLaunchPreloadModule.MovePreFilesComplete()
            end
        else
            CsLog.Debug(string.format("[XLaunchPreloadModule] 预下载版本号不可用, preloadVersion: %s", preloadVersion))
            XLaunchPreloadModule.CallComplete() --不需要移动直接调用完成函数
        end
    end

    function XLaunchPreloadModule.MovePreFilesComplete()
        --移动完成后清空所有标记
        CSXFileTool.DeleteDirectory(PreloadDirPath, true) --删除临时文件夹

        CSPlayerPrefs.DeleteKey(PrefKeys.PreloadCompleteKey)
        CSPlayerPrefs.DeleteKey(PrefKeys.PreloadIndexKey)
        CSPlayerPrefs.DeleteKey(PrefKeys.PreloadDlcIdsKey)
        CSPlayerPrefs.Save()

        CsLog.Debug("[XLaunchPreloadModule] 预下载所有文件移动完成, 文件数量: " .. tostring(FileCount))

        XLaunchPreloadModule.CallComplete()

        local dict = {}
        dict.file_count = FileCount
        CS.XRecord.Record(dict, "88805", "PreloadMove")
    end


    function XLaunchPreloadModule.CallComplete()
        if OnComplete then
            OnComplete()
            OnComplete = nil
            CsLog.Debug("[XLaunchPreloadModule] 执行完成回调.")
        end

        OnProgress = nil
    end

    return XLaunchPreloadModule
end
return module_creator