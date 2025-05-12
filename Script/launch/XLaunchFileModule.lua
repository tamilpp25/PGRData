local UnityApplication = CS.UnityEngine.Application
local CSPlayerPrefs = CS.UnityEngine.PlayerPrefs
local CsApplication = CS.XApplication
local CsLog = CS.XLog
local CsRemoteConfig = CS.XRemoteConfig
local CsTool = CS.XTool
local CsGameEventManager = CS.XGameEventManager.Instance
local ForceDeleteTempFile = -2

local CsInfo = CS.XInfo

local ResourcePathClass = CS.XResourcePath

local ResourceTypeToIntDic = {
    launch = 0,
    matrix = 1
}

local ResourcePathType = {
    Application = 0,
    Document = 1,
}

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
local LAUNCH_PLAYED_CG = "LAUNCH_PLAYED_CG"
local UNCHECKED_FILE_EXTENSION = ".unchecked"

local module_creator = function()
    ---@class XLaunchFileModule 游戏启动文件类
    local XLaunchFileModule = {}

    local MESSAGE_PACK_MODULE_NAME = "XLaunchCommon/XMessagePack"
    require(MESSAGE_PACK_MODULE_NAME)

    ---@type XLaunchDlcManager
    local XLaunchDlcManager = require("XLaunchDlcManager")

    local SIZE = 10 * 1024 * 1024
    local TIMEOUT = 5 * 1000
    local READ_TIMEOUT = 10 * 1000
    local RETRY = 10
    local START_TIME -- 开始下载的时间点，用于统计实际消耗的时间

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

    local CurrentFileTable = nil
    local AllFileTableDlc = nil
    local NeedFileSet = nil

    local UpdateTable = {}
    local UpdateTableCount = 0
    local UpdateSize = 0

    local AllUpdateTable = {}
    local AllUpdateTableCount = 0
    local AllUpdateSize = 0

    local DownloadedMap = {}

    -- 
    local HasLocalFiles = false
    local IsDebugBuild = CS.XApplication.Debug
    local IsPause = false
    local CurrentDownloader
    local TipsOnce = false

    -- Local Function
    local CheckIndexFile
    local ResolveResIndex
    local PrepareDownload
    local DownloadFiles
    local StopDownloading
    local CompleteDownload
    local OnCompleteResFilesInit
    local LoadIndexTable
    local LoadIndexTableWithDlcInfo
    local InitDocumentIndex
    local DownloadDlcIndexs
    local DoPrepareDownload
    local OnNotifyEvent
    local DoRecord
    local RemoveEvents
    local IsFullDownloadSelectType

    -- DLC分包相关
    local DLC_BASE_INDEX = 0 -- 基础包
    local DLC_COMMON_INDEX = -1 -- 通用资源
    local IsDlcBuild = CsInfo.IsDlcBuild
    local IsInGame = false
    local NeedShowSelect = false
    local DlcNeedFileMap = nil
    local CheckFixDlcRecord

    local CSUriPrefix = nil

    -- 本地测试
    local NeedLaunchTest = CS.XResourceManager.NeedLaunchTest -- 调试用，debug环境下测试下载流程 ("Tools/本地下载测试/开启")
    local LaunchTestPath = UnityApplication.dataPath .. "/../../../Product/Temp/LocalCdn" 
    local LaunchTestDirApp = UnityApplication.dataPath .. "/../../../Product/Temp/LocalDirApp"
    local LaunchTestDirDoc = UnityApplication.dataPath .. "/../../../Product/Temp/LocalDirDoc"
    XLaunchFileModule.LaunchTestDirDoc = LaunchTestDirDoc
    local InitDocumentIndexTest

    function XLaunchFileModule.Check(resFileType, appPathModule, appVersionModule, completeCb,progressCb,exitCb)
        CSUriPrefix = CS.XUriPrefix.CreateUriPrefix() --要创建一个出来才可以获取cdn

        ResFileType = resFileType
        AppPathModule = appPathModule
        AppVersionModule = appVersionModule
        OnCompleteCallback = completeCb
        OnProgressCallback = progressCb
        OnExitCallback = exitCb

        ApplicationFilePath = AppPathModule.GetApplicationFilePath()
        DocumentFilePath = AppPathModule.GetDocumentFilePath()
        DocumentUrl = AppPathModule.GetDocumentUrl()

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
            --
            --if IsDlcBuild then
            --    --开启分包远程配置时
            --    -- 1. 新包：一定会有弹窗
            --    -- 2. 覆盖安装（本地没有标记时）
            --    --   a. 原来是全量下载的，不用弹窗
            --    --   b. 有新增分包Id时, 弹窗
            --    -- 3. 覆盖安装, 本地有标记时, 不弹窗
            --    NeedShowSelect = XLaunchDlcManager.NeedShowSelect()
            --end
        end

        if CS.XRemoteConfig.IsHideFunc then
            --NeedUpdate = false
        end
        CsLog.Debug("[Download] 开始检查更新 NeedUpdate:"..tostring(NeedUpdate)..", type:"..ResFileType .. ", IsDlcBuild:" .. tostring(IsDlcBuild))

        if IsInGame or NeedLaunchTest then
            NeedUpdate = true
            ResolveResIndex()
            return
        end

        if ResFileType == RES_FILE_TYPE.MATRIX_FILE and CsRemoteConfig.PreloadMoveCount > 0 then --在外部做一层判断, 彻底不跑逻辑
            local XLaunchPreloadModuleCls = require("XLaunchPreloadModule")
            ---@type XLaunchPreloadModule
            local PreloadModule = XLaunchPreloadModuleCls()
            PreloadModule.Check(ResFileType, DocumentIndexDir, NewVersion, nil, CheckIndexFile)
        else
            CsLog.Debug(string.format("[PreloadMove]跳过预下载文件移动: resFileType: %s, preloadMoveCount: %s", tostring(ResFileType), tostring(CsRemoteConfig.PreloadMoveCount)))
            CheckIndexFile()
        end
    end

    function XLaunchFileModule.SetIsInGame(isInGame)
        IsInGame = isInGame
    end

    -- function XLaunchFileModule.GetOffset()
    --     return OFFSET
    -- end

    --打包狗说搞完这阵子工作，就把没用的逻辑删掉
    DownloadDlcIndexs = function(cb)
        if not IsDlcBuild then
            cb()
            return
        end

        if not DocumentIndexTable then
            DocumentIndexTable, DlcIndexTable = LoadIndexTableWithDlcInfo(DocumentIndexPath)
        end

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
            CsApplication.SetMessage(CsApplication.GetText("CheckDlcIndex"))--"分析资源..."
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
            local totalSize = info[3]
            local cache = true -- 本地缓存 校验通过不重复下载

            local url = string.format("%s/%s/%s/%s", DocumentUrl, NewVersion, ResFileType, name)
            local path = DocumentFilePath .. "/" .. ResFileType .. "/" .. name
            local downloader = CS.XUriPrefixDownloader(url, path, cache, sha1, totalSize, TIMEOUT, RETRY, READ_TIMEOUT)
            local size = 0
            --CsLog.Debug("DocumentUrl:"..DocumentUrl)
            --CsLog.Debug("url:"..url)
            --CsLog.Debug("path:"..path)
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
                        dict.version = NewVersion
                        dict.type = ResFileType
                        DoRecord(dict, "80007", "XFileManagerDownloadError")
                        ShowStartErrorDialog("FileManagerInitFileTableDownloadError", CsApplication.Exit, function()
                            Loop()
                        end, CsApplication.GetText("Retry")) -- 重试
                        return
                    end

                    count = count + 1
                    CsApplication.SetProgress(count / totalCount)
                    -- CsLog.Debug("[] EVENT_LAUNCH_START_DOWNLOAD count:" .. tostring(count))
                    iterKey = key
                    Loop()
                end
            end)
        end

        Loop()
    end

    -- 检测资源列表文件
    CheckIndexFile = function()
        local documentFilePath = DocumentFilePath .. "/" .. ResFileType .. "/" .. INDEX
        local keepLocalIndex = CS.System.IO.File.Exists(DocumentFilePath .. "/DevelopmentIndex") -- 用于Release环境不清理本地index文件（兼顾覆盖安装和手动放资源的情况）

        CsLog.Debug("[Download] CheckIndexFile:"..ResFileType .. ", documentFilePath:" .. tostring(CS.System.IO.File.Exists(documentFilePath)) 
            .. ", Debug:" .. tostring(CsRemoteConfig.Debug) .. ", NeedUpdate:" .. tostring(NeedUpdate) .. ", keepLocalIndex:" .. tostring(keepLocalIndex))
        if not NeedUpdate then
            if CS.System.IO.File.Exists(documentFilePath) then
                if CsRemoteConfig.Debug then --在debug情况下, 如果是launch没有补丁, 则需要被删除, Matrix的走热更替换.
                    if not keepLocalIndex then
                        if ResFileType == RES_FILE_TYPE.LAUNCH_MODULE then
                            CS.XFileTool.DeleteFile(documentFilePath)
                        end
                    end
                else
                    if not keepLocalIndex then
                        CS.XFileTool.DeleteFile(documentFilePath)
                    end
                end

            end
            -- 原始版本，直接进
            ResolveResIndex()
            return
        end

        -- 下载/检测 当前index文件是否最新
        local sha1 = "empty"
        local newVersion = ""
        local indexSize = ForceDeleteTempFile

        if ResFileType == RES_FILE_TYPE.LAUNCH_MODULE then
            sha1 = CsRemoteConfig.LaunchIndexSha1
            indexSize = CsRemoteConfig.LaunchIndexSize
            newVersion = CsRemoteConfig.LaunchModuleVersion
        elseif ResFileType == RES_FILE_TYPE.MATRIX_FILE then
            sha1 = CsRemoteConfig.IndexSha1
            newVersion = CsRemoteConfig.DocumentVersion
            indexSize = CsRemoteConfig.IndexSize
        end

        if HasUpdated then
            local isCorrect = CS.XFileTool.CheckSha1(documentFilePath, sha1)
            CsLog.Debug("[Download] HasUpdated:" .. tostring(HasUpdated) .. ", isCorrect:" .. tostring(isCorrect))
            if isCorrect then
                ResolveResIndex()
                return
            end
        end
        --CsLog.Debug("index download DocumentUrl:"..DocumentUrl)
        local uriPrefixStr = DocumentUrl .. "/" .. newVersion .. "/" .. ResFileType .. "/" .. INDEX
        local downloader = CS.XUriPrefixDownloader(uriPrefixStr, documentFilePath, false, sha1, indexSize, TIMEOUT, RETRY)
        CsTool.WaitCoroutine(downloader:Send(), function()
            if downloader.State ~= CS.XDownloaderState.Success then
                ShowStartErrorDialog("FileManagerInitVersionDownLoadError")
            else
                if ResFileType == RES_FILE_TYPE.LAUNCH_MODULE then
                    AppVersionModule.UpdateLaunchVersion()
                    ResolveResIndex()
                elseif ResFileType == RES_FILE_TYPE.MATRIX_FILE then
                    AppVersionModule.UpdateDocVersion()
                    ResolveResIndex()
                end

            end
        end)
    end

     -- {[assetPath] = value{[1] = Name, [2] = Sha1, [3] = Size}, ... } 
    LoadIndexTable = function(indexPath)
        if NeedLaunchTest then
            if not CS.System.IO.File.Exists(indexPath) then
                return {}
            end
        end
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
            assetBundle:Unload(true)
            return indexTable, dlcIndexTable
        end
        return nil
    end

    local SetDlcTable
    -- 解析doc目录下index
    InitDocumentIndex = function()
        if NeedLaunchTest then 
            InitDocumentIndexTest()
        else
            if not CS.System.IO.File.Exists(DocumentIndexPath) then
                CsLog.Error("[Download] Init DocumentIndex Failed, file not exist: " .. tostring(DocumentIndexPath))
                return
            end

            if not DocumentIndexTable then
                if IsDlcBuild then
                    DocumentIndexTable, DlcIndexTable = LoadIndexTableWithDlcInfo(DocumentIndexPath)
                else
                    DocumentIndexTable = LoadIndexTable(DocumentIndexPath) -- {[assetPath] = value{[1] = Name, [2] = Sha1, [3] = Size}, ... } 
                end
            end
        end

        CurrentFileTable = {} -- 当前需下载资源
        AllFileTableDlc = {} -- DLC完整资源

        local countApp = 0
        local countExist = 0

        NeedFileSet = {} -- 需下载标记
        DlcNeedFileMap = {} -- DLC id对应所需资源

        local countAll = 0
        -- 基础补丁
        for asset, info in pairs(DocumentIndexTable) do
            countAll = countAll + 1
            NeedFileSet[info[1]] = true
            CurrentFileTable[asset] = info
            AllFileTableDlc[asset] = info
        end


        -- 统计资源
        if IsDlcBuild then
            if ResFileType == RES_FILE_TYPE.MATRIX_FILE and DlcIndexTable then
                XLaunchDlcManager.Init(DlcIndexTable)
                -- 新分包不需要记录基础资源，减少记录内存
                --XLaunchDlcManager.SetDlcIndexInfo(DLC_BASE_INDEX, DocumentIndexTable)
                -- 使用新分包构建方式后，暂时没有通用资源包了，设置为空
                --XLaunchDlcManager.SetDlcIndexInfo(DLC_COMMON_INDEX, {})

                --开启分包远程配置时
                -- 1. 新包：一定会有弹窗
                -- 2. 覆盖安装（本地没有标记时）
                --   a. 原来是全量下载的，不用弹窗
                --   b. 有新增分包Id时, 弹窗
                -- 3. 覆盖安装, 本地有标记时, 不弹窗
                NeedShowSelect = XLaunchDlcManager.NeedShowSelect()
                
                local dlcUseAppCount = 0
                local dlcTableMap = {} -- 游戏内下载用
                local needDownloadMap = {} -- 调试用

                --下载全量资源 = 未开启分包
                local isSelectFull = not XLaunchDlcManager.CheckSubpackageOpen()
                if not IsInGame then --热更时
                    --下载全量资源 = 未开启分包 or 上个版本选择了全量包 or 所有分包在本地均有完成记录
                    isSelectFull = isSelectFull or XLaunchDlcManager.IsFullDownload() or XLaunchDlcManager.IsAllDlcIdRecord()
                end
                -- 分包补丁
                for dlcId, dlcTable in pairs(DlcIndexTable) do
                    dlcTableMap[dlcId] = dlcTable
                    -- 此处重复记录（在local function SetDlcTable中）, 先移除掉。
                    --XLaunchDlcManager.SetDlcIndexInfo(dlcId, dlcTable)

                    -- 是否需要下载分包资源 = 全量下载 or 分包已经下载完成了，下次热更直接更补丁，不用到游戏内再次点击分包下载
                    local needDownloadDlc = isSelectFull or XLaunchDlcManager.CheckNeedDownload(dlcId, NeedShowSelect)
                    needDownloadMap[dlcId] = needDownloadDlc

                    local fileMap = {}
                    for asset, info in pairs(dlcTable) do
                        NeedFileSet[info[1]] = true

                        if ApplicationIndexTable[asset] and ApplicationIndexTable[asset][1] == info[1]then
                            dlcUseAppCount = dlcUseAppCount + 1
                        else
                            if needDownloadDlc then
                                CurrentFileTable[asset] = info
                            end
                            AllFileTableDlc[asset] = info
                            fileMap[info[1]] = info
                        end
                    end
                    DlcNeedFileMap[dlcId] = fileMap
                end

                SetDlcTable(dlcTableMap)
                if IsDebugBuild then
                    local logTab = {}
                    for dlcId, need in pairs(needDownloadMap) do
                        table.insert(logTab, dlcId .. ":" .. tostring(need))
                    end
                    CsLog.Debug("[DLC] needDownloadMap: " .. tostring(table.concat(logTab, "\n")))
                end
            end

            -- 剔除包内已有资源（需asset与Name都对应）            
            for asset, info in pairs(ApplicationIndexTable) do
                local value = AllFileTableDlc[asset]
                countApp = countApp + 1
                if value and value[1] == info[1] then
                    countExist = countExist + 1
                    AllFileTableDlc[asset] = nil
                    CurrentFileTable[asset] = nil
                end
            end
        else
            CurrentFileTable = DocumentIndexTable
            
            -- 剔除包内已有资源（需asset与Name都对应）
            for asset, info in pairs(ApplicationIndexTable) do
                countApp = countApp + 1
                local value = CurrentFileTable[asset]
                if value and value[1] == info[1] then
                    countExist = countExist + 1
                    CurrentFileTable[asset] = nil
                end
            end
        end

        
        CsLog.Debug("[Download] 基础资源总量：" .. countAll .. "，app包内资源数量（记录/存在）：" .. countApp .. "/" .. countExist)
    end

    SetDlcTable = function(dlcTableMap)
        local documentFilePath = DocumentFilePath .. "/" .. ResFileType .. "/"
        if NeedLaunchTest then
            documentFilePath = LaunchTestDirDoc .. "/" .. ResFileType .. "/"
        end
        local needLog = IsDebugBuild and CS.UnityEngine.Application.platform == CS.UnityEngine.RuntimePlatform.WindowsEditor
        local DownloadedMark = {}
        local logTab = {}
        
        for dlcId, dlcTable in pairs(dlcTableMap) do
            local count, clearCount, downloadedCount = 0, 0, 0
            local size, clearSize, downloadedSize = 0, 0, 0
            for asset, info in pairs(dlcTable) do
                count = count + 1
                size = size + info[3]
                local name = info[1]
                local value = ApplicationIndexTable[asset]
                if value and value[1] == name then -- 包内
                    clearCount = clearCount + 1
                    clearSize = clearSize + info[3]
                    dlcTable[asset] = nil -- 不统计到总大小
                elseif needLog then
                    if DownloadedMark[name] == nil then
                        DownloadedMark[name] = CS.System.IO.File.Exists(documentFilePath .. name) -- 已下载
                    end
                    if DownloadedMark[name] then
                        local downloaded = DownloadedMark[name]
                        downloadedCount = downloadedCount + 1
                        downloadedSize = downloadedSize + info[3]
                    end
                end
            end
            if IsDebugBuild then
                table.insert(logTab, "[DLC] DLC .." .. dlcId 
                    .. ", appb包内 + doc已下载 = 总 - 余量，数量" .. clearCount .. " + " .. downloadedCount.. " = " .. count .. " - " .. (count-clearCount-downloadedCount)
                    .. ", 大小: " .. math.ceil(clearSize/1024/1024) .."mb"
                    .. " + " ..  math.ceil(downloadedSize/1024/1024) .. "mb"
                    .. " = " .. math.ceil(size/1024/1024) .. "mb"
                    .. " - " .. math.ceil((size - clearSize - downloadedSize)/1024/1024) .. "mb)")
            end
            
            XLaunchDlcManager.SetDlcIndexInfo(dlcId, dlcTable) -- 记录总需下载资源
        end
        if IsDebugBuild and #logTab > 0 then
            CsLog.Debug("DLC各分包下载情况：\n" .. table.concat(logTab, "\n"))
        end
        DownloadedMark = nil
    end

    ResolveResIndex = function()
        local applicationIndexPath = ApplicationFilePath .. "/" .. ResFileType .. "/" .. INDEX
        if NeedLaunchTest and IsDlcBuild then
            applicationIndexPath = LaunchTestDirApp .. "/" .. ResFileType .. "/" .. INDEX
        end
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
                --local dict = {}
                --dict["file_name"] = info[1]
                --DoRecord(dict, "80006", "UpdateTableAddFileError")
                --CsLog.Error("repeat update file:" .. tostring(info[1]))
                --ShowStartErrorDialog("FileManagerInitFileTableUpdateTableError")
                --return
            else
                UpdateTable[info[1]] = info
                UpdateTableCount = UpdateTableCount + 1
                UpdateSize = UpdateSize + info[3]
            end
        end

        AllUpdateSize = 0
        AllUpdateTable = {}
        AllUpdateTableCount = 0
        if IsDlcBuild then
            for _, info in pairs(AllFileTableDlc) do
                if not AllUpdateTable[info[1]] then
                    AllUpdateTable[info[1]] = info
                    AllUpdateTableCount = AllUpdateTableCount + 1
                    AllUpdateSize = AllUpdateSize + info[3]
                end
            end
        end
        
        CsLog.Debug(string.format("[Download] UpdateSize: %d(mb), UpdateTableCount: %d, AllUpdateSize: %d(mb), AllUpdateTableCount: %d", math.ceil(UpdateSize/1024/1024), UpdateTableCount, math.ceil(AllUpdateSize/1024/1024), AllUpdateTableCount))

        local deleteKey = SPECIAL_DELETE_MATRIX_PREF_KEY .. tostring(AppVersionModule.GetAppVersion())
        local isMatrix = ResFileType == RES_FILE_TYPE.MATRIX_FILE
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

        local files
        if NeedLaunchTest then
            files = CS.XFileTool.GetAllFiles(LaunchTestDirDoc .. "/" .. ResFileType)
        else
            files = CS.XFileTool.GetFiles(DocumentFilePath .. "/" .. ResFileType)
        end
        
        local lastVerCount = 0
        local otherCount = 0
        local totalCount = 0

        --是否启用IOS后台下载
        --在启用时，由于IOS校验流程的统一需要，因此文件下载完可能还未校验，需要假设资源是完整的
        --在以上条件下，需要合理估计仍然需要下载的文件大小，因此需要减去对仅未验证的文件的大小
        local isUseIosDownloadService = (CS.XRemoteConfig.DownloadMethod == 0) and AppPathModule.IsIos()

        DownloadedMap = {}
        for i = 0, files.Count - 1 do
            local file = files[i]
            local name = CS.XFileTool.GetFileName(file)
            totalCount = totalCount + 1 

            local isIndex = IsDlcBuild and (string.sub(name,1,5) == INDEX) or (name == INDEX)
            if isIndex then
                goto CONTINUE
            end

            if checkClean then
                if isForceClean or NeedFileSet[name] == nil then
                    CsLog.Debug("[Download] 清理上一版本资源" .. tostring(name) .. ", need:" .. tostring(NeedFileSet[name] ~= nil))
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
            if IsDlcBuild then
                local infoDlc = AllUpdateTable[name]
                if infoDlc then
                    AllUpdateTable[name] = nil
                    AllUpdateTableCount = AllUpdateTableCount - 1
                    AllUpdateSize = AllUpdateSize - infoDlc[3]
                    DownloadedMap[name] = true
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
            CsLog.Debug("[Download] .. other Clean:" .. tostring(file))
            CS.XFileTool.DeleteFile(file)

            :: CONTINUE ::
        end
        
        CsLog.Debug(string.format("[Download] 资源清理 本地总数：%d, 清理上版本数：%d, 其他清理：%d", totalCount, lastVerCount, otherCount))
            
        CsLog.Debug(string.format("[Download] 准备下载，本次需下载数: %d(%dmb)， dlc未下载：%d(%dmb)", 
            UpdateTableCount, math.ceil(UpdateSize/1024/1024), AllUpdateTableCount, math.ceil(AllUpdateSize/1024/1024)))

        if checkClean then
            CsLog.Debug("[Download] 清理上一版本资源完成。")
            CS.UnityEngine.PlayerPrefs.SetInt(deleteKey, 1)
            CS.UnityEngine.PlayerPrefs.Save()
        end

        if IsDlcBuild and isMatrix then
            XLaunchDlcManager.SetDownloadedMap(DownloadedMap)
            CheckFixDlcRecord()
        end

        PrepareDownload()
    end

    local GetDlcMapCountSize = function(map)
        local num = 0
        local size = 0
        for _, info in pairs(map) do
            num = num + 1
            size = size + info[3]
        end
        return num, size
    end
    -- 检查dlc文件是否存在
    CheckFixDlcRecord = function()
        if IsInGame then
            return
        end

        local nums = {}
        local sizes = {}
        if IsDebugBuild then
            -- 总况
            for dlcId, map in pairs(DlcNeedFileMap) do
                local num, size = GetDlcMapCountSize(map)
                nums[dlcId] = num
                sizes[dlcId] = size
            end
        end

        local logTab = {}
        -- 剔除通用
        DlcNeedFileMap[DLC_COMMON_INDEX] = nil
        -- 剔除已下载
        for dlcId, map in pairs(DlcNeedFileMap) do
            local num, num2, num3, size = 0, 0, 0, 0
            for name, info in pairs(map) do
                num2 = num2 + 1
                if DownloadedMap[name] then
                    map[name] = nil
                    num = num + 1
                    size = size + info[3]
                else
                    num3 = num3 + 1
                end
            end
            if IsDebugBuild then
                table.insert(logTab, "dlc " .. dlcId .. ", 已下载数量：" .. num .. "(总" .. num2 .. " - 未下载" .. num3 .. "), 已下载大小：".. math.ceil(size/1024/1024).."mb")
            end
        end
        
        if IsDebugBuild then
            CsLog.Debug("[DLC] ==== dlc检测前剔除 " .. table.concat(logTab, "\n"))
        end

        -- 修正下载记录
        for dlcId, map in pairs(DlcNeedFileMap) do
            local downloaded = XLaunchDlcManager.HasDownloadedDlc(dlcId)
            if downloaded then
                if next(map) then
                    if IsDebugBuild then
                        local num, size = GetDlcMapCountSize(map)
                        CsLog.Error("[DLC]dlc_" .. tostring(dlcId) .. "检测异常:记录为已下载，但缺失本地文件，修正为未下载，需下载数量:" .. num .. "/" .. tostring(nums[dlcId])
                        ..", ".. math.ceil(size/1024/1024) .. "/" .. math.ceil(sizes[dlcId]/1024/1024) .."mb" .. ',' .. size .. "/" .. sizes[dlcId])
                    else
                        CsLog.Error(dlcId .. "记录:[已下载]，但仍需下载，修复为:[未下载]")
                    end
                    XLaunchDlcManager.FixDownloadedDlc(dlcId, false)

                elseif IsDebugBuild then
                    CsLog.Debug("[DLC]dlc_" .. tostring(dlcId) .. "检测ok，全部下载数量：" .. tostring(nums[dlcId]))
                end
            else
                if not next(map) then
                    if IsDebugBuild then
                        CsLog.Error("[DLC]dlc_" .. tostring(dlcId) .. "检测异常:记录为未下载，但已下载完成，修正记录。数量：" .. tostring(nums[dlcId]))
                    else
                        CsLog.Error(dlcId .. "记录[未下载]，但无需下载，修复为[已下载]")
                    end
                    XLaunchDlcManager.FixDownloadedDlc(dlcId, true)

                elseif IsDebugBuild then
                    local num, size = GetDlcMapCountSize(map)
                    CsLog.Debug("[DLC]dlc_" .. tostring(dlcId) .. "检测ok，未下载数量:" .. num .. "/" .. tostring(nums[dlcId])
                        ..", ".. math.ceil(size/1024/1024) .. "/" .. math.ceil(sizes[dlcId]/1024/1024) .."mb")
                end
            end
        end
        CsLog.Debug("[DLC] 检查DLC资源完成。")
    end

    local GetSizeAndUnit = function(size)
        local unit = "KB"
        local num = size / 1024
        if (num > 100) then
            unit = "MB"
            num = num / 1024
        end
        return unit,num
    end

    local InitFullDownload = function()
        XLaunchDlcManager.SetAllLaunchDownloadRecord()
        UpdateTable = AllUpdateTable
        UpdateSize = AllUpdateSize
    end

    local OnDoneSelect = function(isFullDownload)
        XLaunchDlcManager.DoneSelect(CsInfo.Version)
        XLaunchDlcManager.SetIsFullDownload(isFullDownload)
        if isFullDownload then
            InitFullDownload()
        else
            if UpdateTableCount <= 0 then
                OnCompleteResFilesInit()
                return
            end
        end

        DoPrepareDownload()
    end

    PrepareDownload = function()
        CsLog.Debug("PrepareDownload, UpdateTableCount:" .. UpdateTableCount .. ", NeedShowSelect:" .. tostring(NeedShowSelect) .. ", AllUpdateTableCount:" .. AllUpdateTableCount .. ", IsInGame:"..tostring(IsInGame))
        if UpdateTableCount <= 0 and (not NeedShowSelect or AllUpdateTableCount <=0) then
            OnCompleteResFilesInit()
            return
        end

        --todo 如果是dlc打包，显示选择框，选择完重新下载
        if not IsInGame and NeedShowSelect then
            OnNotifyEvent = function(evt, data)
                OnDoneSelect(data[0])
            end
            CsGameEventManager:RegisterEvent(CS.XEventId.EVENT_LAUNCH_DONE_DOWNLOAD_SELECT, OnNotifyEvent)
            CsGameEventManager:Notify(CS.XEventId.EVENT_LAUNCH_SHOW_DOWNLOAD_SELECT,UpdateSize,AllUpdateSize)
        else
            DoPrepareDownload()
        end
    end

    DoPrepareDownload = function()
        -- 分包且禁用，则全部下载
        if IsDlcBuild and IsFullDownloadSelectType() then
            InitFullDownload()
        end

        -- 1:基础资源 2:完整资源
        local downloadMode = XLaunchDlcManager.IsFullDownload() and 2 or 1
        local dict = {["type"] = ResFileType, ["version"] = NewVersion, ["size"] = UpdateSize, ["mode"] = downloadMode }
        dict["app_channel_id"] = CS.XHeroSdkAgent.GetAppChannelId()
        dict["cdn"] = CSUriPrefix:GetFirstCdn() --因为cdn会轮询有多个，所以只能取第一个
        DoRecord(dict, "80011", "StartDownloadNewFiles")
        START_TIME = os.time()

        local unit,num = GetSizeAndUnit(UpdateSize) -- todo updateSize算上launch+matrix，只需launch弹出一次

        if ResFileType == RES_FILE_TYPE.MATRIX_FILE and not IsInGame and not TipsOnce then
            TipsOnce = true
            local sizeTxt = string.format("%0.2f%s", num, unit)
            local envTxt = ""
            local totalTxt = CsApplication.GetText("UpdateTips")
            if UnityApplication.internetReachability == CS.UnityEngine.NetworkReachability.ReachableViaCarrierDataNetwork then
                envTxt = CsApplication.GetText("CarrierTxt")
            else
                envTxt = CsApplication.GetText("WifiTxt")
            end

            local tmpStr = string.format(totalTxt, sizeTxt, envTxt)
            local cancelCB = CsApplication.Exit
            -- CsTool.WaitCoroutine(CsApplication.CoDialog(CsApplication.GetText("Tip"), tmpStr, cancelCB, function()
            --     DownloadFiles()
            -- end))
            CsGameEventManager:Notify(CS.XEventId.EVENT_LAUNCH_DIALOG, tmpStr, cancelCB, function()
                DownloadFiles()
            end)
        else
            DownloadFiles()
        end
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
        local lastProgress = nil
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
                if lastProgress ~= updateProgress and OnProgressCallback then
                    lastProgress = updateProgress
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
                    RemoveEvents()
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
        local lastProgress = nil
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
                if progress and progress ~= math.huge and progress == progress then -- NAN用相等判断
                    CsApplication.SetProgress(progress)
                end
                if lastProgress ~= progress and OnProgressCallback then
                    lastProgress = progress
                    OnProgressCallback(progress)
                end
            elseif manager.StateInt == IosDownloadState.Verifying then
                CS.XGameEventManager.Instance:Notify(CS.XEventId.EVENT_LAUNCH_START_LOADING)
                CsApplication.SetMessage(string.format(CsApplication.GetText("Verifying"), verifier.CurrentCheckCount, verifier.TotalNeedCheckCount)) -- 正在校验中(%d/%d)
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
        if ResFileType == RES_FILE_TYPE.LAUNCH_MODULE then
            for _, info in pairs(UpdateTable) do
                local name = info[1]
                local ext = CS.XFileTool.GetFileExtension(name)
                if string.find(ext, "usm") then
                    CsApplication.SetMessage(CsApplication.GetText("PVDownloading")) -- "PV下载中..."
                    break
                end
            end
        end

        local count = 0
        -- local updateFileText = CsApplication.GetText("UpdateFile")
        local iter, t, key = pairs(UpdateTable)
        local info
        local iterKey = nil
        local Loop
        local useCache = true
        local lastProgress = nil
        local currentUpdateSize = 0
        
        Loop = function()
            key, info = iter(t, iterKey)

            -- print((count + 1) .. "/" .. UpdateTableCount .. "、IsPause :" .. tostring(IsPause))
            if IsPause then
                XLaunchFileModule.ReleaseDownloader()
                return
            end
            if not key then
                CompleteDownload()
                XLaunchFileModule.ReleaseDownloader()
                return
            end
            count = count + 1

            local name = info[1]
            local sha1 = info[2] -- 补丁index中记录的sha1，和下载后文件sha1对比
            local fileSize = info[3]
            local url = string.format("%s/%s/%s/%s", DocumentUrl, NewVersion, ResFileType, name)
            local path = DocumentFilePath .. "/" .. ResFileType .. "/" .. name
            -- CsApplication.SetMessage(updateFileText .. ": " .. name)

            if NeedLaunchTest then
                url = ResFileType .. "/" .. name
                path = LaunchTestDirDoc .. "/" .. ResFileType .. "/" .. name
            end

            local downloader = CS.XUriPrefixDownloader.CreateBySource(DOWNLOAD_SOURCE.DEFAULT, url, path, useCache, sha1, fileSize, TIMEOUT, RETRY, READ_TIMEOUT)
            CurrentDownloader = downloader
            local size = 0

            CsTool.WaitCoroutinePerFrame(downloader:Send(), function(isComplete)
                if not isComplete then
                    --
                    currentUpdateSize = currentUpdateSize + (downloader.CurrentSize - size)
                    size = downloader.CurrentSize
                    local updateProgress = UpdateSize == 0 and 0 or currentUpdateSize / UpdateSize
                    CsApplication.SetProgress(updateProgress)

                    if lastProgress ~= updateProgress and OnProgressCallback then
                        lastProgress = updateProgress
                        -- print("... process:" .. updateProgress .. ", currentUpdateSize/UpdateSize:" ..  math.ceil(currentUpdateSize/1024/1024) .."mb/" .. math.ceil(UpdateSize/1024/1024) .."mb, ".. currentUpdateSize .. "/" .. UpdateSize)
                        OnProgressCallback(updateProgress)
                    end
                else
                    if downloader.State ~= CS.XDownloaderState.Success then
                        if downloader.State == CS.XDownloaderState.Stop then
                            CsLog.Debug("Stop Downloading.")
                            return
                        end
                        local msg = "[Download] error, state error, state: " .. tostring(downloader.State)
                        CsLog.Error(msg)
                        local dict = {}
                        dict.file_name = name
                        dict.file_size = info[3]
                        dict.version = NewVersion
                        dict.type = ResFileType
                        DoRecord(dict, "80007", "XFileManagerDownloadError")
                        local exitCb =  OnExitCallback or CsApplication.Exit
                        local errorCode = IsInGame and "FileManagerInitFileTableInGameDownloadError" or "FileManagerInitFileTableDownloadError"
                        if IsInGame and not CS.XFightInterface.IsOutFight then
                            if exitCb then exitCb() end
                            XLaunchFileModule.PauseDownload()
                            XLaunchFileModule.ReleaseDownloader()
                            return
                        end
                        ShowStartErrorDialog(errorCode, exitCb, function()
                            Loop()
                        end, CsApplication.GetText("Retry")) -- 重试
                        return
                    end
                    if IsDlcBuild then
                        XLaunchDlcManager.SetDownloadedFile(name, true)
                    end
                    currentUpdateSize = currentUpdateSize - size + downloader.Size
                    iterKey = key
                    Loop()
                end
            end)
        end
        Loop()
    end

    local  ParallelDownload = function()
        local lastProgress = nil
        local downloadManager = CS.XNewDownloadManager
        downloadManager.Init()
        downloadManager.Prepare()
        downloadManager.SubDownloadManagers[0]._bufferTime = 150
        downloadManager.SubDownloadManagers[1]._bufferTime = 150

        for _name, info in pairs(UpdateTable) do
            local name = info[1]
            local sha1 = info[2] -- 补丁index中记录的sha1，和下载后文件sha1对比
            local url = string.format("%s/%s/%s/%s", DocumentUrl, NewVersion, ResFileType, name)
            local path = DocumentFilePath .. "/" .. ResFileType .. "/" .. name
            downloadManager.AppendTask(url, path, info[3], sha1)
        end


        local DownloadState = CS.XDownloadManagerState
        local progress = CS.XDownloadProgress
        local exitCb =  OnExitCallback or CsApplication.Exit

        local updateFunc
        updateFunc = function()
            if downloadManager.State == DownloadState.Downloading then
                local p = progress.CurrentDownloadSize / progress.TotalDownloadSize
                    CsApplication.SetProgress(p)
                if lastProgress ~= p and OnProgressCallback then
                    lastProgress = p
                    OnProgressCallback(p)
                end
            elseif downloadManager.State == DownloadState.CompleteError then
                CsTool.RemoveUpdateEvent(updateFunc)
                ShowStartErrorDialog("FileManagerInitFileTableDownloadError", exitCb, function()
                    downloadManager.RePrepareFailedTask()
                    CsGameEventManager:Notify(CS.XEventId.EVENT_LAUNCH_START_DOWNLOAD, progress.TotalDownloadSize)
                    downloadManager.Start()
                    CsTool.AddUpdateEvent(updateFunc)
                end, CsApplication.GetText("Retry")) -- 重试
            elseif downloadManager.State == DownloadState.Complete then
                CsTool.RemoveUpdateEvent(updateFunc)
                downloadManager.Stop()
                if IsDlcBuild then
                    for _, info in pairs(UpdateTable) do
                        XLaunchDlcManager.SetDownloadedFile(info[1], true)
                    end
                end
                
                CompleteDownload()
            else
                return
            end
        end

        CsGameEventManager:Notify(CS.XEventId.EVENT_LAUNCH_START_DOWNLOAD, progress.TotalDownloadSize)
        downloadManager.SetTaskFinish()
        downloadManager.Start()
        CsTool.AddUpdateEvent(updateFunc)
    end

    local AndroidNativeParallelDownload = function()
        local lastProgress = nil
        local downloadManagerAgent = CS.XAndroidDownloadAgent
        downloadManagerAgent.Init()
        downloadManagerAgent.GenerateAndSetCdns();
        downloadManagerAgent.InitManager()


        for _name, info in pairs(UpdateTable) do
            local name = info[1]
            local sha1 = info[2] -- 补丁index中记录的sha1，和下载后文件sha1对比
            local url = string.format("%s/%s/%s/%s", DocumentUrl, NewVersion, ResFileType, name)
            local path = DocumentFilePath .. "/" .. ResFileType .. "/" .. name
            downloadManagerAgent.AppendTask(url, path, info[3], sha1)
        end

        local exitCb =  OnExitCallback or CsApplication.Exit

        local DOWNLOAD_STATE = 2
        local COMPLETE_STATE = 5
        local COMPLETE_ERROR_STATE = 6

        local totalDownloadSize = downloadManagerAgent.GetTotalDownloadSize()

        local updateFunc
        updateFunc = function()
            local currentState = downloadManagerAgent.GetManagerState();
            if currentState == DOWNLOAD_STATE then
                local p = downloadManagerAgent.GetCurrentDownloadSize() / totalDownloadSize
                CsApplication.SetProgress(p)
                if lastProgress ~= p and OnProgressCallback then
                    lastProgress = p
                    OnProgressCallback(p)
                end
            elseif currentState == COMPLETE_ERROR_STATE then
                CsTool.RemoveUpdateEvent(updateFunc)
                ShowStartErrorDialog("FileManagerInitFileTableDownloadError", exitCb, function()
                    downloadManagerAgent.RePrepareFailedTask()
                    totalDownloadSize = downloadManagerAgent.GetTotalDownloadSize()
                    CsGameEventManager:Notify(CS.XEventId.EVENT_LAUNCH_START_DOWNLOAD, totalDownloadSize)
                    downloadManagerAgent.StartDownload()
                    CsTool.AddUpdateEvent(updateFunc)
                end, CsApplication.GetText("Retry")) -- 重试
            elseif currentState == COMPLETE_STATE then
                CsTool.RemoveUpdateEvent(updateFunc)
                downloadManagerAgent.Stop()
                if IsDlcBuild then
                    for _, info in pairs(UpdateTable) do
                        XLaunchDlcManager.SetDownloadedFile(info[1], true)
                    end
                end

                CompleteDownload()
            else
                return
            end
        end

        CsGameEventManager:Notify(CS.XEventId.EVENT_LAUNCH_START_DOWNLOAD, totalDownloadSize)
        downloadManagerAgent.SetTaskFinish()
        downloadManagerAgent.StartDownload()
        CsTool.AddUpdateEvent(updateFunc)
    end


    -- 是否需要播放cg（名字+大版本号）
    local function CheckPlayCG()
        if IsInGame then
            return
        end
        local needCGBtn = (ResFileType == RES_FILE_TYPE.MATRIX_FILE)
        local needPlayCG = false
        local videoUrl = "null"
        if needCGBtn then
            videoUrl = CS.XAudioManager.LaunchVideoAsset
            local hasVideo = (videoUrl ~= "" and videoUrl ~= "null")
            if hasVideo then
                local videoName =  CS.XFileTool.GetFileNameWithoutExtension(videoUrl)
                local newRecord = videoName .. "_" .. tostring(AppVersionModule.GetAppVersion())
                local oldRecord = CS.UnityEngine.PlayerPrefs.GetString(LAUNCH_PLAYED_CG, "")
                if newRecord ~= oldRecord then
                    CS.UnityEngine.PlayerPrefs.SetString(LAUNCH_PLAYED_CG, newRecord)
                    needPlayCG = true
                end
                local bundleName = CS.XResourceManager.GetBundleUrl(videoUrl);
                videoUrl = CS.XBundleManager.GetFile(bundleName)
                if not videoUrl then
                    needCGBtn = false
                else 
                    if CS.UnityEngine.Application.platform == CS.UnityEngine.RuntimePlatform.Android then 
                        local path = videoUrl
                        local streamingAssetPath = CS.UnityEngine.Application.streamingAssetsPath
                        local len = string.len(streamingAssetPath)
                        local prefix = string.sub(videoUrl, 0, len)
                        -- 若pv在包内，对路径修正为 resource/launch/xxx.usm
                        if prefix == streamingAssetPath then
                            videoUrl = string.sub(videoUrl, len + 2)
                        end
                    end
                end
                print("[Audio] Need Play CG, newRecord:" .. tostring(newRecord) .. ", oldRecord:" .. tostring(oldRecord) .. ", videoUrl:" .. tostring(videoUrl))
            else
                needCGBtn = false
            end
            print("[Audio] Need Play CG:" .. tostring(needPlayCG) .. ", hasVideo:" .. tostring(hasVideo) .. ", videoUrl:" .. tostring(videoUrl))
        end
        CsGameEventManager:Notify(CS.XEventId.EVENT_LAUNCH_CG, needCGBtn, needPlayCG, videoUrl)
    end
    
    DownloadFiles = function()
        CsGameEventManager:Notify(CS.XEventId.EVENT_LAUNCH_START_DOWNLOAD, UpdateSize)
        CheckPlayCG()
        
        local DownloadFilesAction = function()
            CsApplication.SetMessage("") -- CsApplication.GetText("GameUpdate")
            CsApplication.SetProgress(0)

            local isUseAndroidDownloadService = (CS.XRemoteConfig.DownloadMethod == 0) and AppPathModule.IsAndroid()
            local isUseIosDownloadService = (CS.XRemoteConfig.DownloadMethod == 0) and AppPathModule.IsIos()
            local useParallel = (CS.XRemoteConfig.ParallelQueueSize ~= nil and CS.XRemoteConfig.ParallelDownload == 1)

            if AppPathModule.IsAndroid() and CS.XRemoteConfig.ParallelDownload == 2 then
                CsLog.Debug("Android原生多线程下载模式")
                AndroidNativeParallelDownload()
                return
            end

            if CS.XRemoteConfig.ParallelQueueSize ~= nil and useParallel and ResFileType == RES_FILE_TYPE.MATRIX_FILE and not IsInGame then
                CsLog.Debug("多线程下载模式")
                --AndroidBackgroundDownload()
                ParallelDownload()
                return
            end

            if isUseAndroidDownloadService and ResFileType == RES_FILE_TYPE.MATRIX_FILE and not IsInGame then
                CsLog.Debug("安卓后台下载模式")
                AndroidBackgroundDownload()
            elseif isUseIosDownloadService and ResFileType == RES_FILE_TYPE.MATRIX_FILE and not IsInGame  then
                CsLog.Debug("IOS后台下载模式")
                IosBackgroundDownload()
            else
                CsLog.Debug("传统下载模式")
                TraditionalDownload()
            end
        end

        DownloadFilesAction()
        -- 如果空间不足的话，直接弹出空间不足提示 追加多15Mb检测，避免缓存移动文件，会额外占用
        -- local checkSize = math.ceil(UpdateSize/1024) + 15*1024*1024
        -- if UpdateSize > 0 and not CS.XAppPlatBridge.DiskSizeEnough(checkSize) then
        --     CsTool.WaitCoroutine(CsApplication.CoDialog(CsApplication.GetText("Tip"),
        --         CsStringEx.Format(CsApplication.GetText("FileManagerDownloadDiskFull"), math.ceil(checkSize/1024)),
        --         CsApplication.Exit, function()
        --             DownloadFilesAction()
        --         end, CsApplication.GetText("Quit")))
        -- else 
        --     DownloadFilesAction()
        -- end
    end

    function XLaunchFileModule.PauseDownload()
        -- 暂停后不立即停止，等当前文件下载完毕后再暂停
        --if CurrentDownloader then
        --    CurrentDownloader:Stop()
        --    CurrentDownloader = nil
        --end
        IsPause = true
        CompleteDownload()
    end
    
    function XLaunchFileModule.ReleaseDownloader()
        CurrentDownloader = nil
        CsGameEventManager:Notify(CS.XEventId.EVENT_LAUNCH_DOWNLOAD_RELEASE)

    end

    function XLaunchFileModule.ResumeDownload()
        IsPause = false
    end

    function XLaunchFileModule.CleanDlcFiles(dlcId)
        if dlcId == DLC_BASE_INDEX or dlcId == DLC_COMMON_INDEX then
            CsLog.Error("[DLC] 清理dlc资源失败 dlcId:" .. tostring(dlcId))
            return
        end
        local dirPath = DocumentFilePath .. "/" .. ResFileType .. "/"
        if NeedLaunchTest then
            dirPath = LaunchTestDirDoc .. "/" .. ResFileType .. "/"
        end
        
        local fileMap = DlcNeedFileMap[dlcId]     
        if not fileMap then
            CsLog.Error("[DLC] 清理dlc资源失败 fileMap is ni, dlcId:" .. tostring(dlcId))
            return
        end

        local count, size = 0, 0
        for name, info in pairs(fileMap) do
            local file = dirPath .. name
            CS.XFileTool.DeleteFile(file)
            XLaunchDlcManager.SetDownloadedFile(name, false)
            count = count + 1
            size = size + info[3]
        end
        if IsDebugBuild then
            CsLog.Debug("[DLC] 清理DLC .." .. dlcId .. "下载资源，数量：" .. count .. "，大小：" .. math.ceil(size/1024/1024) .. "mb")
        end
    end

    -- 启动下载测试
    InitDocumentIndexTest = function()
        local indexPath = LaunchTestDirDoc .. "/" .. ResFileType .. "/" .. INDEX
        print("[DownloadTest] InitDocumentIndexTest: ResFileType: " .. ResFileType .. ", indexPath:" .. indexPath)
        if CS.System.IO.File.Exists(indexPath) then
            -- 本地下载release测试（真机逻辑解析index）
            print("[DownloadTest] 本地下载-release测试（解析index）, IsDlcBuild:" .. tostring(IsDlcBuild))
            if IsDlcBuild then
                DocumentIndexTable, DlcIndexTable = LoadIndexTableWithDlcInfo(indexPath)
            else
                print("[DownloadTest] InitDocumentIndexTest:222")
                DocumentIndexTable = LoadIndexTable(DocumentIndexPath)
            end
        else
            -- 本地下载（随意文件）测试
            print("[DownloadTest] 本地下载-随意文件测试")
            DocumentIndexTable = {}

            local UnityApplication = CS.UnityEngine.Application
            local cdnPath = LaunchTestPath .. "/" .. ResFileType
            local files = CS.XFileTool.GetAllFiles(cdnPath)
            
            local function GetFileSize(path)
                local file, err = io.open(path, "rb")
                if not file then
                    return 0
                end
                local size = file:seek("end")
                file:close()
                return size
            end
            local tab = {}
            for i = 0, files.Count - 1 do
                local file = files[i]
                local name = CS.XFileTool.GetFileName(file)
                if name ~= INDEX then
                    local asset = string.sub(file, #cdnPath + 2)
                    local size = GetFileSize(file)
                    table.insert(tab, "[LaunchTest] " .. tostring(i + 1) .. "、file:" .. tostring(file) .. ", name:" .. tostring(name) .. ", asset:" .. tostring(asset) .. ", size:" .. tostring(size))
                    DocumentIndexTable[asset] = {name, nil, size}
                end    
            end
            if #tab > 0 then
                print(table.concat(tab, "\n"))
            end
        end
    end

    CompleteDownload = function()
        print("CompleteDownload!")
        CsApplication.SetProgress(1)
        local cost_time = os.time() - START_TIME
        local speed = UpdateSize / cost_time
        -- 1:基础资源 2:完整资源
        local downloadMode = XLaunchDlcManager.IsFullDownload() and 2 or 1
        local dict = {["type"] = ResFileType, ["version"] = NewVersion, ["size"] = UpdateSize, ["mode"] = downloadMode, ["cost"] = cost_time, ["speed"] = speed}
        dict["app_channel_id"] = CS.XHeroSdkAgent.GetAppChannelId()
        dict["cdn"] = CSUriPrefix:GetFirstCdn() --因为cdn会轮询有多个，所以只能取第一个
        DoRecord(dict, "80012", "DownloadNewFilesEnd")

        OnCompleteResFilesInit()
    end

    local function ClearData()
        ApplicationIndexTable = nil
        DocumentIndexTable = nil
        CurrentFileTable = nil

        DlcIndexTable = nil
        AllFileTableDlc = nil
        NeedFileSet = nil
        DlcNeedFileMap = nil
        DownloadedMap = nil
    end
    OnCompleteResFilesInit = function()
        if IsInGame then
            if not IsPause then
                XLaunchDlcManager.DoneDownloadInGame()
            end
            ClearData()
            if OnCompleteCallback then
                OnCompleteCallback(IsPause)
            end
            return
        end

        local urlTable = {}
        local appUrlTable = {}
        --local hashTable = {}
        if IsDlcBuild then
            if AllFileTableDlc then
                for asset, info in pairs(AllFileTableDlc) do -- 未剔除包体已有资源，dlc补丁逻辑会访问路径出错
                    local resourcePath = ResourcePathClass()
                    resourcePath.DocumentType = ResourcePathType.Document
                    resourcePath.MatrixType = ResourceTypeToIntDic[ResFileType]
                    resourcePath.ResourceName = info[1]
                    urlTable[asset] = resourcePath
                end
                XLaunchDlcManager.DoneDownloadInLaunch()
            end
        else
            if DocumentIndexTable then
                for asset, info in pairs(DocumentIndexTable) do
                    local resourcePath = ResourcePathClass()
                    resourcePath.DocumentType = ResourcePathType.Document
                    resourcePath.MatrixType = ResourceTypeToIntDic[ResFileType]
                    resourcePath.ResourceName = info[1]
                    urlTable[asset] = resourcePath
                end
            end
        end

        for asset, info in pairs(ApplicationIndexTable) do
            if not urlTable[asset] or HasLocalFiles then -- 包体资源优先于本地测试资源
                local resourcePath = ResourcePathClass()
                resourcePath.DocumentType = ResourcePathType.Application
                resourcePath.MatrixType = ResourceTypeToIntDic[ResFileType]
                resourcePath.ResourceName = info[1]
                urlTable[asset] = resourcePath
            end
        end
        
        ClearData()
        RemoveEvents()

        -- 完成回调
        if OnCompleteCallback then
            OnCompleteCallback(urlTable, nil, NeedUpdate, HasLocalFiles)
        end

        collectgarbage("collect")
    end

    RemoveEvents = function()
        if NeedShowSelect then
            CsGameEventManager:RemoveEvent(CS.XEventId.EVENT_LAUNCH_DONE_DOWNLOAD_SELECT, OnNotifyEvent)
        end
        NeedShowSelect = nil -- 网络下载失败重试时，不再弹选择弹窗
    end

    DoRecord = function(...)
        if IsInGame then
            return
        end
        CS.XRecord.Record(...)
    end
    
    IsFullDownloadSelectType = function() 
        local selectType = CS.XRemoteConfig.LaunchSelectType
        return selectType == nil or selectType == 0
    end

    return XLaunchFileModule
end

return module_creator