local UnityApplication = CS.UnityEngine.Application

local CsApplication = CS.XApplication
local CsLog = CS.XLog
local CsRemoteConfig = CS.XRemoteConfig
local CsTool = CS.XTool
local CsGameEventManager = CS.XGameEventManager.Instance
local CsInfo = CS.XInfo



local SPECIAL_DELETE_MATRIX_PREF_KEY = "__Kuro__reset_Matrix_files_"

local module_creator = function()
    local XLaunchFileModule = {}

    local MESSAGE_PACK_MODULE_NAME = "XLaunchCommon/XMessagePack"
    require(MESSAGE_PACK_MODULE_NAME)


    local DlcManager = require("XLaunchDlcManager")

    local SIZE = 10 * 1024 * 1024
    local TIMEOUT = 5 * 1000
    local READ_TIMEOUT = 10 * 1000
    local RETRY = 10

    local INDEX = "index"

    local ResFileType
    local AppPathModule
    local AppVersionModule
    local OnCompleteCallback
    local OnProgressCallback

    local ApplicationFilePath
    local DocumentFilePath
    local DocumentUrl

    local DocumentIndexDir
    local DocumentIndexPath

    local NeedUpdate
    local HasUpdated
    local NewVersion

    -- common
    local ApplicationIndexTable
    local DocumentIndexTable
    local DlcIndexTable
    local DlcIndexDetailTable
    local CurrentNeedDocTable 
    local AllNeedDocTable 
    local NeedFileSet

    local UpdateTable = {}
    local UpdateTableCount = 0
    local UpdateSize = 0

    local AllUpdateTable = {}
    local AllUpdateTableCount = 0
    local AllUpdateSize = 0

    local CurrentUpdateSize = 0
    -- 
    local HasLocalFiles = false

    -- Local Function
    local CheckIndexFile
    local ResolveResIndex
    local PrepareDownload
    local DownloadFiles
    local CompleteDownload
    local OnCompleteResFilesInit
    local LoadIndexTable
    local LoadIndexTableWithDlcInfo
    local InitDocumentIndex
    local DownloadDlcIndexs
    local DoPrepareDownload
    local OnDoneSelect 
    local GetSizeAndUnit 

    local IsDlcBuild = false
    local NeedShowSelect = false

    function XLaunchFileModule.Check(resFileType, appPathModule, appVersionModule, completeCb,progressCb)
        ResFileType = resFileType
        AppPathModule = appPathModule
        AppVersionModule = appVersionModule
        OnCompleteCallback = completeCb
        OnProgressCallback = progressCb

        ApplicationFilePath = AppPathModule.GetApplicationFilePath()
        DocumentFilePath = AppPathModule.GetDocumentFilePath()
        DocumentUrl = AppPathModule.GetDocumentUrl()

        IsDlcBuild = CsInfo.IsDlcBuild

        DocumentIndexDir = DocumentFilePath .. "/" .. ResFileType .. "/"
        DocumentIndexPath= DocumentIndexDir .. INDEX


        NeedUpdate = false
        NeedShowSelect = false

        if ResFileType == RES_FILE_TYPE.LAUNCH_MODULE then
            NeedUpdate = AppVersionModule.CheckLaunchModuleUpdate()
            HasUpdated = AppVersionModule.HasLaunchModuleUpdated()
            NewVersion = AppVersionModule.GetNewLaunchModuleVersion()
        elseif ResFileType == RES_FILE_TYPE.MATRIX_FILE then
            NeedUpdate = AppVersionModule.CheckDocUpdate()
            HasUpdated = AppVersionModule.HasDocUpdated()
            NewVersion = AppVersionModule.GetNewDocVersion()

            NeedShowSelect = DlcManager.NeedShowSelectDownloadPart(CsInfo.Version) and IsDlcBuild
        end

        if CS.XRemoteConfig.IsHideFunc then
            NeedUpdate = false
        end
        --
        CheckIndexFile()
    end

    -- function XLaunchFileModule.GetOffset()
    --     return OFFSET
    -- end

    DownloadDlcIndexs = function(cb)
        if not IsDlcBuild then
            cb()
            return
        end

        DocumentIndexTable,DlcIndexTable = LoadIndexTableWithDlcInfo(DocumentIndexPath)

        local iter, t, key = pairs(DlcIndexTable)
        local info

        local iterKey = nil
        local Loop
        Loop = function()
            key, info = iter(t, iterKey)

            if not key then
                cb()
                return
            end

            local id = key
            local name = info[1] -- 补丁index中记录的sha1，和下载后文件sha1对比
            local sha1 = info[2] -- 补丁index中记录的sha1，和下载后文件sha1对比


            local str = string.format("%s/%s/%s/%s", DocumentUrl, NewVersion, ResFileType, name)
            local str2 = DocumentFilePath .. "/" .. ResFileType .. "/" .. name
            local downloader = CS.XUriPrefixDownloader(str, str2, true, sha1, TIMEOUT, RETRY, READ_TIMEOUT)
            local size = 0

            CsTool.WaitCoroutinePerFrame(downloader:Send(), function(isComplete)
                if not isComplete then
                    --
                else
                    if downloader.State ~= CS.XDownloaderState.Success then
                        local msg = "XFileManager Download error, state error, state: " .. tostring(downloader.State)
                        CsLog.Error(msg)
                        local dict = {}
                        dict.file_name = name
                        dict.file_size = 1 
                        CS.XRecord.Record(dict, "80007", "XFileManagerDownloadError")
                        ShowStartErrorDialog("FileManagerInitFileTableDownloadError", CsApplication.Exit, function()
                            Loop()
                        end, "重试")
                        return
                    end

                    iterKey = key
                    Loop()
                end
            end)
        end

        Loop()
    end

    -- 检测资源列表文件
    CheckIndexFile = function()
        CS.XAppEventManager.LogAppEvent(CS.XAppEventConfig.Version_Checking_Start)
        if not NeedUpdate then
            -- 原始版本，直接进
            ResolveResIndex()
            return
        end

        -- 下载/检测 当前index文件是否最新
        local sha1 = "empty"
        local newVersion = ""
        if ResFileType == RES_FILE_TYPE.LAUNCH_MODULE then
            sha1 = CsRemoteConfig.LaunchIndexSha1
            newVersion = CsRemoteConfig.LaunchModuleVersion
        elseif ResFileType == RES_FILE_TYPE.MATRIX_FILE then
            sha1 = CsRemoteConfig.IndexSha1
            newVersion = CsRemoteConfig.DocumentVersion
        end
        local documentFilePath = DocumentFilePath .. "/" .. ResFileType .. "/" .. INDEX

        if HasUpdated and CS.XFileTools.CheckSha1(documentFilePath, sha1) then
            ResolveResIndex()
            return
        end

        local uriPrefixStr = DocumentUrl .. "/" .. newVersion .. "/" .. ResFileType .. "/" .. INDEX
        local downloader = CS.XUriPrefixDownloader(uriPrefixStr, documentFilePath, false, sha1)
        CsTool.WaitCoroutine(downloader:Send(), function()
            if downloader.State ~= CS.XDownloaderState.Success then
                ShowStartErrorDialog("FileManagerInitVersionDownLoadError")
            else
                if ResFileType == RES_FILE_TYPE.LAUNCH_MODULE then
                    AppVersionModule.UpdateLaunchVersion()
                    ResolveResIndex()
                elseif ResFileType == RES_FILE_TYPE.MATRIX_FILE then
                  
                    DownloadDlcIndexs(function()
                        AppVersionModule.UpdateDocVersion()
                        ResolveResIndex()
                    end)
                end
                
            end
        end)
    end

    LoadIndexTable = function(indexPath)
        local assetBundle = CS.UnityEngine.AssetBundle.LoadFromFile(indexPath)
        if (assetBundle and assetBundle:Exist()) then
            local assetName = assetBundle:GetAllAssetNames()[0]
            local asset = assetBundle:LoadAsset(assetName, typeof(CS.UnityEngine.TextAsset))
            local indexFile = XMessagePack.Decode(asset.bytes)
            local indexTable = indexFile[1]
            assetBundle:Unload(true)
            return indexTable
        end
        return nil
    end

    LoadIndexTableWithDlcInfo = function(indexPath)
        local assetBundle = CS.UnityEngine.AssetBundle.LoadFromFile(indexPath)
        if (assetBundle and assetBundle:Exist()) then
            local assetName = assetBundle:GetAllAssetNames()[0]
            local asset = assetBundle:LoadAsset(assetName, typeof(CS.UnityEngine.TextAsset))
            local indexFile = XMessagePack.Decode(asset.bytes)
            local indexTable = indexFile[1]
            local indexDlcTalbe = indexFile[2]
            assetBundle:Unload(true)
            return indexTable,indexDlcTalbe
        end
        return nil
    end

  

    InitDocumentIndex = function()
        if not DocumentIndexTable then
            if IsDlcBuild then
                DocumentIndexTable,DlcIndexTable = LoadIndexTableWithDlcInfo(DocumentIndexPath)
            else
                DocumentIndexTable = LoadIndexTable(DocumentIndexPath)
            end

        end -- {[assetPath] = value{[1] = Name, [2] = Sha1, [3] = Size}, ... } 

        if IsDlcBuild then
            DlcManager.Init(DlcIndexTable)
        end
        

        CurrentNeedDocTable ={}
        AllNeedDocTable = {}

        local count  = 0
        local totalCount = 0 
        NeedFileSet = {} -- 所需文件的完整记录
        for key, docInfo in pairs(DocumentIndexTable) do
            totalCount = totalCount + 1
            NeedFileSet[docInfo[1]] = true
        end

        

        -- 剔除包内已有资源（需assetPath与Name都对应）
        for key, value in pairs(ApplicationIndexTable) do
            local info = DocumentIndexTable[key]
            if info and info[1] == value[1] then
                DocumentIndexTable[key] = nil
                count = count + 1
            end
        end 


        if IsDlcBuild and DlcIndexTable then
            DlcIndexDetailTable = {}
            CurrentNeedDocTable = {}

            for dlcId,dlcIndexInfo in pairs(DlcIndexTable) do
                local dlcTable =  LoadIndexTable(DocumentIndexDir..dlcIndexInfo[1])
                DlcIndexDetailTable[key] = dlcTable

                local hasDownloadDlc = DlcManager.HasStartDownloadDlc(dlcId)
                for assetPath, docInfo in pairs(dlcTable) do
                    totalCount = totalCount + 1
                    NeedFileSet[docInfo[1]] = true

                    if hasDownloadDlc then
                        CurrentNeedDocTable[assetPath] = docInfo
                    end
                    if NeedShowSelect then
                        AllNeedDocTable[assetPath] = docInfo
                    end
                end
            end

            
            for k,v in pairs(DocumentIndexTable) do
                CurrentNeedDocTable[k] = v
                if NeedShowSelect then
                    AllNeedDocTable[k] = v
                end
            end

        else
            CurrentNeedDocTable = DocumentIndexTable
        end


        CsLog.Debug("包内资源数量:" .. count .. "/" .. totalCount)
    end


    ResolveResIndex = function()
        local applicationIndexPath = ApplicationFilePath .. "/" .. ResFileType .. "/" .. INDEX
        ApplicationIndexTable = LoadIndexTable(applicationIndexPath)
        CS.XAppEventManager.LogAppEvent(CS.XAppEventConfig.Version_Checking_End)
        CsLog.Debug("ResolveResIndex. NeedUpdate:" .. tostring(NeedUpdate) .. ", applicationIndexPath:" .. applicationIndexPath .. ", documentIndexPath:" .. DocumentIndexPath)
        if not NeedUpdate then -- 原始版本
            if CS.System.IO.File.Exists(DocumentIndexPath) then
                CsLog.Debug("Local index:" .. DocumentIndexPath)
                InitDocumentIndex()
                HasLocalFiles = true
            end
            
            OnCompleteResFilesInit() -- 无需更新，直接完成
            return
        end

        InitDocumentIndex()

        UpdateTableCount = 0
        UpdateTable={}
        for _, value in pairs(CurrentNeedDocTable) do
            if UpdateTable[value[1]] then
                --
                local dict = {}
                dict["file_name"] = value[1]
                CS.XRecord.Record(dict, "80006", "UpdateTableAddFileError")
                ShowStartErrorDialog("FileManagerInitFileTableUpdateTableError")
                return
            end

            UpdateTable[value[1]] = value
            UpdateTableCount = UpdateTableCount + 1
            UpdateSize = UpdateSize + value[3]
        end

        if NeedShowSelect then
            AllUpdateTable={}
            AllUpdateTableCount = 0
            AllUpdateSize = 0
            for _, value in pairs(AllNeedDocTable) do
                AllUpdateTable[value[1]] = value
                AllUpdateTableCount = UpdateTableCount + 1
                AllUpdateSize = AllUpdateSize + value[3]
            end
        end

        local deleteKey = SPECIAL_DELETE_MATRIX_PREF_KEY .. tostring(AppVersionModule.GetAppVersion())
        local isMatrix = ResFileType == "matrix"
        local cleanFlag = CS.UnityEngine.PlayerPrefs.GetInt(deleteKey, 0)
        local checkClean = (isMatrix and (not cleanFlag or cleanFlag ~= 1))
        CsLog.Debug("上一版本资源key: " .. tostring(deleteKey) .. ", type: " .. tostring(ResFileType) .. ", checkClean: " .. tostring(checkClean))

        local files = CS.XFileTools.GetFiles(DocumentFilePath .. "/" .. ResFileType)
        
        local totalCount = 0 
        local count  = 0
        local extensionCount = 0
        local otherCount = 0

        for i = 0, files.Length - 1 do
            local file = files[i]
            local name = CS.XFileTools.GetFileName(file)

            if IsDlcBuild then
                if string.sub(name,1,5) == INDEX then
                    goto CONTINUE
                end
            else
                if name == INDEX then
                    goto CONTINUE
                end
            end

            totalCount = totalCount + 1 

            if checkClean and not NeedFileSet[name] then
                CsLog.Debug("清理上一版本资源" .. tostring(name))
                CS.XFileTools.DeleteFile(file)
                count = count + 1
                goto CONTINUE
            end

            local info = UpdateTable[name] -- 更新文件已存在
            if info then
                UpdateTable[name] = nil
                UpdateTableCount = UpdateTableCount - 1
                UpdateSize = UpdateSize - info[3]

                if NeedShowSelect then
                    AllUpdateTable[name] = nil
                    AllUpdateTableCount = AllUpdateTableCount - 1
                    AllUpdateSize = AllUpdateSize - info[3]
                end
                goto CONTINUE
            end

            if UpdateTable[CS.XFileTools.GetFileNameWithoutExtension(file)] then -- 无用代码，留着防止未知历史原因出错。 -- 当前文件名的使用都带后缀
                extensionCount = extensionCount + 1
                goto CONTINUE
            end

            otherCount = otherCount + 1
            CS.XFileTools.DeleteFile(file)

            :: CONTINUE ::
        end
        CsLog.Debug(string.format("资源清理: %d/%d/%d, %d, 需更新: %d", count, otherCount, totalCount, extensionCount, UpdateTableCount))

        if checkClean then
            CsLog.Debug("清理上一版本资源完成。")
            CS.UnityEngine.PlayerPrefs.SetInt(deleteKey, 1)
            CS.UnityEngine.PlayerPrefs.Save()
        end

        PrepareDownload()
    end

    GetSizeAndUnit = function(size)
        local unit = "k"
        local num = size / 1024
        if (num > 100) then
            unit = "m"
            num = num / 1024
        end
        return unit,num
    end

    OnDoneSelect = function(isFullDownload)
        DlcManager.DoneSelectDownloadPart(CsInfo.Version)
        if isFullDownload then
            DlcManager.SetAllNeedDownload()
            UpdateTable = AllUpdateTable
        end

        DoPrepareDownload()
    end

    PrepareDownload = function()
        if UpdateTableCount <= 0 and (not NeedShowSelect or AllUpdateTableCount <=0) then
            OnCompleteResFilesInit()
            return
        end

        --todo 如果是dlc打包，显示选择框，选择完重新下载
        if NeedShowSelect then
            CsXGameEventManager.Instance:RegisterEvent(CS.XEventId.EVENT_LAUNCH_DONE_DOWNLOAD_SELECT, OnDoneSelect)
            CsGameEventManager:Notify(CS.XEventId.EVENT_LAUNCH_SHOW_DOWNLOAD_SELECT,UpdateSize,AllUpdateSize)
        else
            DoPrepareDownload()
        end
    end

    DoPrepareDownload = function()
        local dict = {["type"] = ResFileType, ["version"] = NewVersion}
        CS.XRecord.Record(dict, "80011", "StartDownloadNewFiles")

        local unit,num = GetSizeAndUnit(UpdateSize)

        --BDC
        CS.XHeroBdcAgent.BdcUpdateGame("203", "1", "0")
        local tmpStr = string.format("%s%0.2f%s", CsApplication.GetText("UpdateCheck"), num, unit) -- 海外调整热更文本
        CsTool.WaitCoroutine(CsApplication.CoDialog(CsApplication.GetText("Tip"), tmpStr, CsApplication.Exit, function()
            DownloadFiles()
        end))
        return
    end

    DownloadFiles = function()
        CsGameEventManager:Notify(CS.XEventId.EVENT_LAUNCH_START_DOWNLOAD, UpdateSize)
        CS.XAppEventManager.LogAppEvent(CS.XAppEventConfig.Resource_Download_Start)
        CS.XHeroBdcAgent.BdcUpdateGame("204", "1", "0")
        CsApplication.SetMessage(CsApplication.GetText("GameUpdate"))
        CsApplication.SetProgress(0)

        local updateFileText = CsApplication.GetText("UpdateFile")

        local iter, t, key = pairs(UpdateTable)
        local info

        local iterKey = nil
        local Loop
        Loop = function()
            key, info = iter(t, iterKey)

            if not key then
                CompleteDownload()
                return
            end

            local name = info[1]
            local sha1 = info[2] -- 补丁index中记录的sha1，和下载后文件sha1对比

            CsApplication.SetMessage(updateFileText .. ": " .. name)

            local str = string.format("%s/%s/%s/%s", DocumentUrl, NewVersion, ResFileType, name)
            local str2 = DocumentFilePath .. "/" .. ResFileType .. "/" .. name
            local downloader = CS.XUriPrefixDownloader(str, str2, true, sha1, TIMEOUT, RETRY, READ_TIMEOUT)
            local size = 0

            CsTool.WaitCoroutinePerFrame(downloader:Send(), function(isComplete)
                if not isComplete then
                    --
                    CurrentUpdateSize = CurrentUpdateSize - size + downloader.CurrentSize
                    size = downloader.CurrentSize
                    local updateProgress = UpdateSize == 0 and 0 or CurrentUpdateSize / UpdateSize
                    CsApplication.SetProgress(updateProgress)

                    if OnProgressCallback then
                        OnProgressCallback(updateProgress)
                    end
                else
                    if downloader.State ~= CS.XDownloaderState.Success then
                        local msg = "XFileManager Download error, state error, state: " .. tostring(downloader.State)
                        CsLog.Error(msg)
                        local dict = {}
                        dict.file_name = name
                        dict.file_size = info[3]
                        CS.XRecord.Record(dict, "80007", "XFileManagerDownloadError")
                        ShowStartErrorDialog("FileManagerInitFileTableDownloadError", CsApplication.Exit, function()
                            Loop()
                        end, "重试")
                        return
                    end

                    CurrentUpdateSize = CurrentUpdateSize - size + downloader.Size
                    iterKey = key
                    Loop()
                end
            end)
        end

        Loop()
    end

    CompleteDownload = function()
        CsApplication.SetProgress(1)
        local dict = {["type"] = ResFileType, ["version"] = NewVersion}
        CS.XRecord.Record(dict, "80012", "DownloadNewFilesEnd")
        CS.XAppEventManager.LogAppEvent(CS.XAppEventConfig.Resource_Download_End)
        OnCompleteResFilesInit()
    end

    OnCompleteResFilesInit = function()
        local urlTable = {}

        if DocumentIndexTable then
            for key, item in pairs(DocumentIndexTable) do
                urlTable[key] = DocumentFilePath .. "/" .. ResFileType .. "/" .. item[1]
            end
        end

        if IsDlcBuild and DlcIndexDetailTable then
            for id, subTable in pairs(DlcIndexDetailTable) do
                for key, item in pairs(subTable) do
                    urlTable[key] = DocumentFilePath .. "/" .. ResFileType .. "/" .. item[1]
                end
            end

            DlcManager.DoneDownload()
        end

        for key, item in pairs(ApplicationIndexTable) do
            if not urlTable[key] or HasLocalFiles then -- 包体资源优先于本地测试资源
                urlTable[key] = ApplicationFilePath .. "/" .. ResFileType .. "/" .. item[1]
            end
        end

        ApplicationIndexTable = nil
        DocumentIndexTable = nil
        NeedFileSet = nil

        DlcIndexTable = nil
        DlcIndexDetailTable = nil
        CurrentNeedDocTable = nil
        AllNeedDocTable = nil

        if NeedShowSelect then
            CsXGameEventManager.Instance:RemoveEvent(CS.XEventId.EVENT_LAUNCH_DONE_DOWNLOAD_SELECT, OnDoneSelect)
        end

        -- 完成回调
        if OnCompleteCallback then
            OnCompleteCallback(urlTable, NeedUpdate, HasLocalFiles)
        end
    end

    return XLaunchFileModule
end

return module_creator