local UnityApplication = CS.UnityEngine.Application

local CsApplication = CS.XApplication
local CsLog = CS.XLog
local CsRemoteConfig = CS.XRemoteConfig
local CsTool = CS.XTool
local CsGameEventManager = CS.XGameEventManager.Instance

local CsInfo = CS.XInfo

local CsDownloadService = CS.XDownloadService.Instance
local DownloadState = {
    NONE = -1,
    DONE = 0,
    ING = 1,
    FAIL = 2
}

local IosDownloadState = {
    PreparingLocalFiles = 0,
    PreparingDownload = 1,
    Downloading = 2,
    AppendDownloading = 3,
    Verifying = 4,
    Finished = 5
}

-- 版更时需要强清本地资源的版本
local ForceVersion = {["1.22.0"] = true}
local ForceVersionNum = 22


local SPECIAL_DELETE_MATRIX_PREF_KEY = "__Kuro__reset_Matrix_files_"
local UNCHECKED_FILE_EXTENSION = ".unchecked"

local module_creator = function()
    local XLaunchFileModule = {}

    local MESSAGE_PACK_MODULE_NAME = "XLaunchCommon/XMessagePack"
    require(MESSAGE_PACK_MODULE_NAME)


    local XLaunchDlcManager = require("XLaunchDlcManager")

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
    local OnExitCallback

    local ApplicationFilePath
    local DocumentFilePath
    local DocumentUrl

    local DocumentIndexDir
    local DocumentIndexPath

    local NewVersion
    local NeedUpdate
    local HasUpdated

    -- common
    local ApplicationIndexTable
    local DocumentIndexTable

    local DlcIndexTable
    local DlcCommonIdList

    local CurrentFileTable = nil
    local AllFileTableDlc = nil
    local NeedFileSet = nil

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
    local OnNotifyEvent

    local IsDlcBuild = false
    local NeedShowSelect = false

    function XLaunchFileModule.Check(resFileType, appPathModule, appVersionModule, completeCb,progressCb,exitCb)
        ResFileType = resFileType
        AppPathModule = appPathModule
        AppVersionModule = appVersionModule
        OnCompleteCallback = completeCb
        OnProgressCallback = progressCb
        OnExitCallback = exitCb

        ApplicationFilePath = AppPathModule.GetApplicationFilePath()
        DocumentFilePath = AppPathModule.GetDocumentFilePath()
        DocumentUrl = AppPathModule.GetDocumentUrl()

        IsDlcBuild = CsInfo.IsDlcBuild
        XLaunchDlcManager.SetIsDlcBuild(IsDlcBuild)

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

            NeedShowSelect = XLaunchDlcManager.NeedShowSelectDownloadPart(CsInfo.Version) and IsDlcBuild -- 每个大版本只会弹出一次选择更新，小更新沿用选择结果
        end

        if CS.XRemoteConfig.IsHideFunc then
            --NeedUpdate = false
        end

        CsLog.Debug("NeedUpdate:"..tostring(NeedUpdate)..",type:"..ResFileType)
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

        DocumentIndexTable, DlcIndexTable, DlcCommonIdList = LoadIndexTableWithDlcInfo(DocumentIndexPath)

        local count = 0
        local totalCount = 0
        if DlcIndexTable then
            for _, _ in pairs(DlcIndexTable) do
                totalCount = totalCount + 1
            end
        end
        if totalCount > 0 then
            CsGameEventManager:Notify(CS.XEventId.EVENT_LAUNCH_START_DOWNLOAD, totalCount, false, CsApplication.GetText("UpdateIndex") .. "(%d/%d)") -- 检查更新(0/10)
            CsApplication.SetProgress(0)
        end
        local iter, t, key = pairs(DlcIndexTable)
        local info

        local iterKey = nil
        local Loop
        Loop = function()
            key, info = iter(t, iterKey)

            if not key then
                CsApplication.SetProgress(1)
                cb()
                return
            end

            local id = key
            local name = info[1]
            local sha1 = info[2]
            local cache = true -- 本地缓存 校验通过不重复下载

            local str = string.format("%s/%s/%s/%s", DocumentUrl, NewVersion, ResFileType, name)
            local str2 = DocumentFilePath .. "/" .. ResFileType .. "/" .. name
            local downloader = CS.XUriPrefixDownloader(str, str2, cache, sha1, TIMEOUT, RETRY, READ_TIMEOUT)
            local size = 0
            --CsLog.Debug("DocumentUrl:"..DocumentUrl)
            --CsLog.Debug("str:"..str)
            --CsLog.Debug("str2:"..str2)
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
                        end, CsApplication.GetText("Retry")) -- 重试
                        return
                    end

                    count = count + 1
                    CsApplication.SetProgress(count / totalCount)
                    CsLog.Debug("[] EVENT_LAUNCH_START_DOWNLOAD count:" .. tostring(count))
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
        local documentFilePath = DocumentFilePath .. "/" .. ResFileType .. "/" .. INDEX
        local keepLocalIndex = CS.System.IO.File.Exists(DocumentFilePath .. "/DevelopmentIndex") -- 用于Release环境不清理本地index文件（兼顾覆盖安装和手动放资源的情况）

        CsLog.Debug("[Download] CheckIndexFile:"..ResFileType .. ", documentFilePath:" .. tostring(CS.System.IO.File.Exists(documentFilePath)) 
            .. ", Debug:" .. tostring(CsRemoteConfig.Debug) .. ", NeedUpdate:" .. tostring(NeedUpdate) .. ", keepLocalIndex:" .. tostring(keepLocalIndex))
        if not NeedUpdate then
            if CS.System.IO.File.Exists(documentFilePath) and not CsRemoteConfig.Debug then -- debug情况下不需更新但要保留本地index
                if not keepLocalIndex then
                    CS.XFileTool.DeleteFile(documentFilePath)
                end
            end
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

        if HasUpdated and CS.XFileTool.CheckSha1(documentFilePath, sha1) then
            CsLog.Debug("[Download] HasUpdated:" .. tostring(HasUpdated))
            ResolveResIndex()
            return
        end
        --CsLog.Debug("index download DocumentUrl:"..DocumentUrl)
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
            local dlcIndexTable = indexFile[2] or {}
            local dlcCommonIdList = indexFile[3] or {}
            assetBundle:Unload(true)
            return indexTable, dlcIndexTable, dlcCommonIdList
        end
        return nil
    end

    -- 解析doc目录下index
    InitDocumentIndex = function()
        if not CS.System.IO.File.Exists(DocumentIndexPath) then
            CsLog.Error("[Download] Init DocumentIndex Failed, file not exist: " .. tostring(DocumentIndexPath))
            return
        end

        if not DocumentIndexTable then
            if IsDlcBuild then
                DocumentIndexTable, DlcIndexTable, DlcCommonIdList = LoadIndexTableWithDlcInfo(DocumentIndexPath)
            else
                DocumentIndexTable = LoadIndexTable(DocumentIndexPath) -- {[assetPath] = value{[1] = Name, [2] = Sha1, [3] = Size}, ... } 
            end
        end

        CurrentFileTable = {} -- 当前需下载资源
        AllFileTableDlc = {} -- DLC完整资源

        local count  = 0
        NeedFileSet = {} -- 需下载标记

        -- 基础补丁
        for asset, info in pairs(DocumentIndexTable) do
            NeedFileSet[info[1]] = true
            CurrentFileTable[asset] = info
            AllFileTableDlc[asset] = info
        end
        
        -- 统计资源
        if IsDlcBuild then
            XLaunchDlcManager.Init(DlcIndexTable, DlcCommonIdList)
            
            -- 分包补丁
            for dlcId, dlcIndexInfo in pairs(DlcIndexTable) do
                local dlcIndexPath = DocumentIndexDir .. dlcIndexInfo[1]
                local dlcTable =  LoadIndexTable(dlcIndexPath)
                XLaunchDlcManager.SetDlcIndexInfo(dlcId, dlcTable)

                -- 历史选择的分包下载记录（不弹出选择框是用于默认下载）
                local hasDownloadDlc = (not NeedShowSelect) and XLaunchDlcManager.HasStartDownloadDlc(dlcId)
                CsLog.Debug("[DLC] dlcId: ".. tostring(dlcId) .. ", hasDownloadDlc: " .. tostring(hasDownloadDlc) .. ", NeedShowSelect:" .. tostring(NeedShowSelect))

                for asset, info in pairs(dlcTable) do
                    NeedFileSet[info[1]] = true

                    if hasDownloadDlc then
                        CurrentFileTable[asset] = info
                    end
                    AllFileTableDlc[asset] = info
                end
            end
            
            -- 剔除包内已有资源（需asset与Name都对应）
            for asset, info in pairs(ApplicationIndexTable) do
                local value = AllFileTableDlc[asset]
                if value and value[1] == info[1] then
                    AllFileTableDlc[asset] = nil
                    CurrentFileTable[asset] = nil
                    count = count + 1
                end
            end
        else
            CurrentFileTable = DocumentIndexTable
            
            -- 剔除包内已有资源（需asset与Name都对应）
            for asset, info in pairs(ApplicationIndexTable) do
                local value = CurrentFileTable[asset]
                if value and value[1] == info[1] then
                    CurrentFileTable[asset] = nil
                    count = count + 1
                end
            end
        end

        CsLog.Debug("[Download] 包内已有资源数量:" .. count)
    end


    ResolveResIndex = function()
		CS.XAppEventManager.LogAppEvent(CS.XAppEventConfig.Version_Checking_End)
        local applicationIndexPath = ApplicationFilePath .. "/" .. ResFileType .. "/" .. INDEX
        ApplicationIndexTable = LoadIndexTable(applicationIndexPath)

        CsLog.Debug("[Download] ResolveResIndex. NeedUpdate:" .. tostring(NeedUpdate) .. ", applicationIndexPath:" .. applicationIndexPath .. ", documentIndexPath:" .. DocumentIndexPath)
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

        UpdateSize = 0
        UpdateTableCount = 0
        UpdateTable = {}
        for _, info in pairs(CurrentFileTable) do
            if UpdateTable[info[1]] then
                local dict = {}
                dict["file_name"] = info[1]
                CS.XRecord.Record(dict, "80006", "UpdateTableAddFileError")
                CsLog.Error("repeat update file:" .. tostring(info[1]))
                ShowStartErrorDialog("FileManagerInitFileTableUpdateTableError")
                return
            end

            UpdateTable[info[1]] = info
            UpdateTableCount = UpdateTableCount + 1
            UpdateSize = UpdateSize + info[3]
        end

        AllUpdateSize = 0
        AllUpdateTable = {}
        AllUpdateTableCount = 0
        if NeedShowSelect then
            for _, info in pairs(AllFileTableDlc) do
                AllUpdateTable[info[1]] = info
                AllUpdateTableCount = AllUpdateTableCount + 1
                AllUpdateSize = AllUpdateSize + info[3]
            end
        end
        
        CsLog.Debug("[Download] IsDlcBuild:" .. tostring(IsDlcBuild))
        CsLog.Debug(string.format("[Download] UpdateSize: %d, UpdateTableCount: %d, AllUpdateSize: %d, AllUpdateTableCount: %d", UpdateSize, UpdateTableCount, AllUpdateSize, AllUpdateTableCount)) -- 2166 -- 基础包补丁

        local deleteKey = SPECIAL_DELETE_MATRIX_PREF_KEY .. tostring(AppVersionModule.GetAppVersion())
        local isMatrix = ResFileType == "matrix"
        local cleanFlag = CS.UnityEngine.PlayerPrefs.GetInt(deleteKey, 0)
        local checkClean = (isMatrix and (not cleanFlag or cleanFlag ~= 1))
        local isForceClean = ForceVersion[CsInfo.Version]

        if isMatrix and not isForceClean then -- 补充强删资源逻辑
            
            local theDeleteKey = SPECIAL_DELETE_MATRIX_PREF_KEY .. "1." .. ForceVersionNum .. ".0"
            local theCleanFlag = CS.UnityEngine.PlayerPrefs.GetInt(theDeleteKey, 0)
            CsLog.Debug("key:" .. theDeleteKey .. ", cleanFlag:" .. tostring(cleanFlag) .. ", force cleanFlag :" .. tostring(theCleanFlag))

            if cleanFlag ~= 1 and (theCleanFlag ~= 1) then -- 首次检测当前版本、 且没经历过强删版本
                for versionNum = ForceVersionNum - 1, 10, -1 do -- 经历过再之前版本 -- 属于旧包覆盖安装，需要强清资源
                    local lastDeleteKey = SPECIAL_DELETE_MATRIX_PREF_KEY .. "1." .. versionNum .. ".0"
                    local lastCleanFlag = CS.UnityEngine.PlayerPrefs.GetInt(lastDeleteKey, 0)
                    CsLog.Debug("[Download] Check Force Clean Key:" .. lastDeleteKey .. ", cleanFlag:" .. tostring(lastCleanFlag) .. ", " .. type(lastCleanFlag))

                    if lastCleanFlag == 1 then
                        isForceClean = true
                        CsLog.Debug("[Download] 过旧版本 需要全面清理资源, version:" .. lastDeleteKey)

                        -- 完成后增加强删版本的标记
                        CS.UnityEngine.PlayerPrefs.SetInt(theDeleteKey, 1)
                        CS.UnityEngine.PlayerPrefs.Save()
                        break
                    end
                end
            end
        end
        
        CsLog.Debug("[Download] 上一版本资源key: " .. tostring(deleteKey) .. ", type: " .. tostring(ResFileType) .. ", checkClean: " .. tostring(checkClean) .. ", force:" .. tostring(isForceClean) .. ", CsInfo.Version:" .. tostring(CsInfo.Version))

        local files = CS.XFileTool.GetFiles(DocumentFilePath .. "/" .. ResFileType)
        
        local lastVerCount = 0
        local otherCount = 0
        local totalCount = 0

        --是否启用IOS后台下载
        --在启用时，由于IOS校验流程的统一需要，因此文件下载完可能还未校验，需要假设资源是完整的
        --在以上条件下，需要合理估计仍然需要下载的文件大小，因此需要减去对仅未验证的文件的大小
        local isUseIosDownloadService = (CS.XRemoteConfig.DownloadMethod == 0) and AppPathModule.IsIos()

        for i = 0, files.Length - 1 do
            local file = files[i]
            local name = CS.XFileTool.GetFileName(file)
            totalCount = totalCount + 1 

            local isIndex = IsDlcBuild and (string.sub(name,1,5) == INDEX) or (name == INDEX)
            if isIndex then
                goto CONTINUE
            end

            if checkClean then
                if isForceClean or not NeedFileSet[name] then
                    CsLog.Debug("[Download] 清理上一版本资源" .. tostring(name) .. ", need:" .. tostring((not NeedFileSet[name])))
                    CS.XFileTool.DeleteFile(file)
                    lastVerCount = lastVerCount + 1
                    goto CONTINUE
                end
            end
            -- 检查更新文件是否存在
            local hasUpdated = false

            local info = UpdateTable[name]
            if info then
                UpdateTable[name] = nil
                UpdateTableCount = UpdateTableCount - 1
                UpdateSize = UpdateSize - info[3]
                hasUpdated = true
            end
            if NeedShowSelect then
                local infoDlc = AllUpdateTable[name]
                if infoDlc then
                    AllUpdateTable[name] = nil
                    AllUpdateTableCount = AllUpdateTableCount - 1
                    AllUpdateSize = AllUpdateSize - infoDlc[3]
                    hasUpdated = true
                end
            end
            if hasUpdated then
                goto CONTINUE
            end

            local nameWithOutExtension = CS.XFileTool.GetFileNameWithoutExtension(file)
            if UpdateTable[nameWithOutExtension] then -- 下载时临时文件（name.download）将会保留
                info = UpdateTable[nameWithOutExtension]
                if isUseIosDownloadService then
                    if CS.XFileTool.GetFileExtension(file) == UNCHECKED_FILE_EXTENSION then
                        UpdateSize = UpdateSize - info[3]
                    end
                end
                goto CONTINUE
            end

            otherCount = otherCount + 1
            CS.XFileTool.DeleteFile(file)

            :: CONTINUE ::
        end
        
        CsLog.Debug(string.format("[Download] 资源清理 本地总数：%d, 清理上版本数：%d, 其他清理：%d, 需更新: %d， dlc需更新：%d", 
            totalCount, lastVerCount, otherCount, UpdateTableCount, AllUpdateTableCount))

        if checkClean then
            CsLog.Debug("[Download] 清理上一版本资源完成。")
            CS.UnityEngine.PlayerPrefs.SetInt(deleteKey, 1)
            CS.UnityEngine.PlayerPrefs.Save()
        end

        PrepareDownload()
    end

    local GetSizeAndUnit = function(size)
        local unit = "k"
        local num = size / 1024
        if (num > 100) then
            unit = "MB"
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
            CsGameEventManager:RegisterEvent(CS.XEventId.EVENT_LAUNCH_DONE_DOWNLOAD_SELECT,  function(evt,data)
                OnDoneSelect(data[0])
            end)
            CsGameEventManager:Notify(CS.XEventId.EVENT_LAUNCH_SHOW_DOWNLOAD_SELECT,UpdateSize,AllUpdateSize)
        else
            DoPrepareDownload()
        end
    end

    DoPrepareDownload = function()
        local dict = {["type"] = ResFileType, ["version"] = NewVersion}
        CS.XRecord.Record(dict, "80011", "StartDownloadNewFiles")

        local unit,num = GetSizeAndUnit(UpdateSize)
		-- 日服不做热更时网络状态判断
        --if (UnityApplication.internetReachability == CS.UnityEngine.NetworkReachability.ReachableViaCarrierDataNetwork and UpdateSize > SIZE) then
            --BDC
            -- CS.XHeroBdcAgent.BdcUpdateGame("203", "1", "0")
            -- local tmpStr = string.format("%0.2f%s%s", num, unit, CsApplication.GetText("UpdateCheck"))
            -- CsTool.WaitCoroutine(CsApplication.CoDialog(CsApplication.GetText("Tip"), tmpStr, CsApplication.Exit, function()
            --     DownloadFiles()
            -- end))
            -- return
        --end

        --BDC
        CS.XHeroBdcAgent.BdcUpdateGame("203", "1", "0")
        local tmpStr = string.format("%s%0.2f %s", CsApplication.GetText("UpdateCheck"), num, unit) -- 海外调整热更文本 -- #104203 文本最后与单位新增一个空格
        CsTool.WaitCoroutine(CsApplication.CoDialog(CsApplication.GetText("Tip"), tmpStr, CsApplication.Exit, function()
            DownloadFiles()
        end))
        return
    end

    local AndroidBackgroundDownload = function()
        --android background download todo
        --1.组建好一个数组，传给backgroud download组件，开始下载
        --2.每帧获取下载状态，更新界面（当前下载文件，下载进度）
        --3.重试状态
        --4.下载完成状态
        local urlPrefix = string.format("%s/%s/%s/", DocumentUrl, NewVersion, ResFileType)
        local downloadDir = DocumentFilePath .. "/" .. ResFileType .. "/" 
        
        local allNameTable = {}
        local allSha1Table = {}
        local allSizeTable = {}

        for name, info in pairs(UpdateTable) do
            table.insert(allNameTable, info[1])
            table.insert(allSha1Table, info[2])
            table.insert(allSizeTable, info[3])
        end

        local names = table.concat(allNameTable,";")
        local sha1s = table.concat(allSha1Table,";")
        local sizes = table.concat(allSizeTable,";")

        CsDownloadService:Download(urlPrefix, downloadDir, names, sha1s, TIMEOUT, RETRY, sizes)

        local waitTimeCnt = 0
        local updateInfoCb = nil
        updateInfoCb = function()
            -- 下载进度
            local state = CsDownloadService:GetDownloadState()
            local fileSize = CsDownloadService:GetCurrentFileSize()
            local curDoneSize = CsDownloadService:GetCurrentDownloadSize()
            if state == DownloadState.ING then
                waitTimeCnt = 0
                local updateProgress = UpdateSize == 0 and 0 or curDoneSize  / UpdateSize
                if updateProgress>1  then updateProgress =1 end

                CsApplication.SetProgress(updateProgress)
                if OnProgressCallback then
                    OnProgressCallback(updateProgress)
                end
            elseif state == DownloadState.FAIL or (state == DownloadState.NONE and waitTimeCnt > 20) then
                CsTool.RemoveUpdateEvent(updateInfoCb)
                local errMsg = CsDownloadService:GetExceptionInfo()
                local name = CsDownloadService:GetCurrentFileName()
                CsLog.Error("[Download] Android Download error, state error, state: " .. tostring(state)..", err:" .. errMsg .. ", name:" .. tostring(name) .. ", fileSize:" .. tostring(fileSize))
                local exitCb =  OnExitCallback or CsApplication.Exit

                CsLog.Debug("[Download Android Backgroud] Istate " .. tostring(state) .. ",waitTimeCnt: " .. tostring(waitTimeCnt))
                ShowStartErrorDialog("FileManagerInitFileTableDownloadError", exitCb, function()
                    CheckIndexFile()
                end, CsApplication.GetText("Retry"))

            elseif state == DownloadState.DONE then
                CsLog.Debug("[Download Android Backgroud] Istate == DownloadState.DONE! ")
                CsTool.RemoveUpdateEvent(updateInfoCb)
                CompleteDownload()
            elseif state == DownloadState.NONE then
                waitTimeCnt = waitTimeCnt + CS.UnityEngine.Time.deltaTime
            end
        end
        CsTool.AddUpdateEvent(updateInfoCb)
    end

    local IosBackgroundDownload = function()
        local urlPrefix = string.format("%s/%s/%s", DocumentUrl, NewVersion, ResFileType)
        CS.XIOSDownloadConfig.PrepareCNDList(urlPrefix);
        local taskArr = {}
        for _,v in pairs(UpdateTable) do
            table.insert(taskArr, string.format("%s %s %s", v[1], v[3], v[2]))
        end
        local taskInfo = table.concat(taskArr,"\n")
        CS.XIOSDownloadCustomer.Instance:SetTaskInfo(taskInfo)
        local manager = CS.XIOSDownloadManager.Instance
        local verifier = CS.XIOSDownloadVerifier.Instance

        local updateEvent
        updateEvent = function()
            if manager.StateInt == IosDownloadState.PreparingLocalFiles then
                --Nothing Here
            elseif manager.StateInt == IosDownloadState.PreparingDownload then
                --Nothing Here
            elseif manager.StateInt == IosDownloadState.Downloading or manager.StateInt == IosDownloadState.AppendDownloading then
                if manager.StateInt == IosDownloadState.AppendDownloading and manager.TotalTaskBytes ~= 0 then
                    CsGameEventManager:Notify(CS.XEventId.EVENT_LAUNCH_START_DOWNLOAD, manager.TotalTaskBytes)
                end
                local progress = manager.CurDownloadedBytes / manager.TotalTaskBytes;
                if progress and progress ~= math.huge then
                    CsApplication.SetProgress(progress)
                end
                if OnProgressCallback then
                    OnProgressCallback(progress)
                end
            elseif manager.StateInt == IosDownloadState.Verifying then
                CS.XGameEventManager.Instance:Notify(CS.XEventId.EVENT_LAUNCH_START_LOADING)
                CsApplication.SetMessage(string.format("正在校验中(%d/%d)", verifier.CurrentCheckCount, verifier.TotalNeedCheckCount))
                CsApplication.SetProgress(verifier.CurrentCheckCount / verifier.TotalNeedCheckCount)
            elseif manager.StateInt == IosDownloadState.Finished then
                CsTool.RemoveUpdateEvent(updateEvent)
                manager:Clear()
                CompleteDownload()
            end
        end

        manager:Prepare()

        manager:SetDownloadErrorHandler(function(file)
            local exitCb =  OnExitCallback or CsApplication.Exit
            ShowStartErrorDialog("FileManagerInitFileTableDownloadError", exitCb, function()
                manager:ContinueDownloading()
            end, CsApplication.GetText("Retry")) -- 重试
        end)

        CsTool.AddUpdateEvent(updateEvent)
    end

    local TraditionalDownload = function()
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
                        local msg = "[Download] error, state error, state: " .. tostring(downloader.State)
                        CsLog.Error(msg)
                        local dict = {}
                        dict.file_name = name
                        dict.file_size = info[3]
                        CS.XRecord.Record(dict, "80007", "XFileManagerDownloadError")
                        local exitCb =  OnExitCallback or CsApplication.Exit

                        ShowStartErrorDialog("FileManagerInitFileTableDownloadError",exitCb, function()
                            Loop()
                        end, CsApplication.GetText("Retry")) -- 重试
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

    DownloadFiles = function()
        CsGameEventManager:Notify(CS.XEventId.EVENT_LAUNCH_START_DOWNLOAD, UpdateSize)
		CS.XAppEventManager.LogAppEvent(CS.XAppEventConfig.Resource_Download_Start)
        CS.XHeroBdcAgent.BdcUpdateGame("204", "1", "0")
        CsApplication.SetMessage(CsApplication.GetText("GameUpdate"))
        CsApplication.SetProgress(0)

        local isUseAndroidDownloadService = (CS.XRemoteConfig.DownloadMethod == 0) and AppPathModule.IsAndroid()
        local isUseIosDownloadService = (CS.XRemoteConfig.DownloadMethod == 0) and AppPathModule.IsIos()

        if isUseAndroidDownloadService and ResFileType == RES_FILE_TYPE.MATRIX_FILE then
            CsLog.Debug("安卓后台下载模式")
            AndroidBackgroundDownload()
        elseif isUseIosDownloadService and ResFileType == RES_FILE_TYPE.MATRIX_FILE then
            CsLog.Debug("IOS后台下载模式")
            IosBackgroundDownload()
        else
            CsLog.Debug("传统下载模式")
            TraditionalDownload()
        end
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

        if IsDlcBuild then
            if AllFileTableDlc then
                for asset, info in pairs(AllFileTableDlc) do
                    urlTable[asset] = DocumentFilePath .. "/" .. ResFileType .. "/" .. info[1]
                end
                XLaunchDlcManager.DoneDownload()
            end
        else
            if DocumentIndexTable then
                for asset, info in pairs(DocumentIndexTable) do
                    urlTable[asset] = DocumentFilePath .. "/" .. ResFileType .. "/" .. info[1]
                end
            end
        end

        for asset, info in pairs(ApplicationIndexTable) do
            if not urlTable[asset] or HasLocalFiles then -- 包体资源优先于本地测试资源
                urlTable[asset] = ApplicationFilePath .. "/" .. ResFileType .. "/" .. info[1]
            end
        end

        ApplicationIndexTable = nil
        DocumentIndexTable = nil
        CurrentFileTable = nil

        DlcIndexTable = nil
        AllFileTableDlc = nil

        if NeedShowSelect then
            CsGameEventManager:RemoveEvent(CS.XEventId.EVENT_LAUNCH_DONE_DOWNLOAD_SELECT, OnNotifyEvent)
            XLaunchDlcManager.DoneSelectDownloadPart(CsInfo.Version) -- 下载完成后才记录选择记录
        end

        -- 完成回调
        if OnCompleteCallback then
            OnCompleteCallback(urlTable, NeedUpdate, HasLocalFiles)
        end
    end

    return XLaunchFileModule
    end

return module_creator