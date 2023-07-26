--- 资源分包管理器
XDlcManagerCreator = function()
    ---@class XDlcManager
    local XDlcManager = {}

    local XDLCItem = require("XEntity/XDLC/XDLCItem")

    local AllTitleList = nil
    local AllItemList = nil
    local ItemMap = nil

    ---@type XLaunchDlcManager
    local XLaunchDlcManager = nil
    local IsDlcBuild = false
    local IsDebugBuild = CS.XApplication.Debug
    local DlcIndexInfo = nil

    local STATE_DOWNLOAD_READY = "STATE_DOWNLOAD_READY" -- 可开始下载
    local STATE_DOWNLOAD_ING = "STATE_DOWNLOAD_ING" -- 下载中
    local STATE_DOWNLOAD_PAUSE = "STATE_DOWNLOAD_PAUSE" -- 暂停下载

    local DLC_BASE_INDEX = 0 -- 基础资源包索引
    local DLC_COMMON_INDEX = -1 -- 通用资源包索引

    local PreEnterFightCallback
    local OnExitFight
    local DownloadState = STATE_DOWNLOAD_READY

    ---@type XLaunchFileModule
    local FileModule = nil
    local CurrentProcessCb = nil
    local CurrentDoneCb = nil
    local CurrentDlcListId = nil

    local DownloadRedPointMap = nil
    local RedPointKey = "DLC_DOWNLOAD_RED_POINT_KEY"
    local DownloadAllTimer
    local IsDownloadAll = false
    local IsInterruptDownload = false --打断全部下载
    
    local DoRecord = function(dlcListId)
        if not XLaunchDlcManager then
            return
        end
        local dlcItem = XDlcManager.GetItemData(dlcListId)
        local dict = {}
        dict["version"] = XLaunchDlcManager.GetVersionmodule().GetNewLaunchModuleVersion()
        dict["size"] = dlcItem and dlcItem:GetTotalSize() or 0
        dict["id"] = dlcListId
        dict["download_all"] = IsDownloadAll
        CS.XRecord.Record(dict, "80031", "DLCDownloadComplete")
    end

    function XDlcManager.Init()
        IsDlcBuild = CS.XInfo.IsDlcBuild
        if not IsDlcBuild then
            return
        end
        XLaunchDlcManager = require("XLaunchDlcManager")
        ---@type table<number, XDLCItem>
        ItemMap = {}
        XDlcManager.InitRedPoint()
        DlcIndexInfo = XLaunchDlcManager.GetIndexInfo()
        -- XLog.Debug("=====DlcIndexInfo = XLaunchDlcManager.GetIndexInfo()" .. tostring(DlcIndexInfo), DlcIndexInfo)
        DownloadState = STATE_DOWNLOAD_READY
        XEventManager.AddEventListener(XEventId.EVENT_PRE_ENTER_FIGHT, XDlcManager.OnPreEnterFight)
        CS.XGameEventManager.Instance:RegisterEvent(XEventId.EVENT_FIGHT_EXIT, XDlcManager.OnExitFight)
        CS.XGameEventManager.Instance:RegisterEvent(XEventId.EVENT_DLC_FIGHT_ENTER, XDlcManager.OnPreEnterFight)
        CS.XGameEventManager.Instance:RegisterEvent(XEventId.EVENT_DLC_FIGHT_EXIT, XDlcManager.OnExitFight)
    end

    --region   ------------------RedPoint start-------------------
    function XDlcManager.InitRedPoint()
        DownloadRedPointMap = XSaveTool.GetData(RedPointKey)
        if not DownloadRedPointMap then
            DownloadRedPointMap = {}
        end
    end

    function XDlcManager.ClearRedPoint()
        DownloadRedPointMap = {}
        XSaveTool.RemoveData(RedPointKey)
    end

    function XDlcManager.CheckRedPoint()
        if not XDlcManager.CheckIsOpen() then
            return false
        end
        for _, state in pairs(DownloadRedPointMap or {}) do
            if state then
                return true
            end
        end
        return false
    end

    function XDlcManager.MarkRedPoint(dlcListId, state)
        DownloadRedPointMap[dlcListId] = state
        XSaveTool.SaveData(RedPointKey, DownloadRedPointMap)
    end
    --endregion------------------RedPoint finish------------------

    function XDlcManager.CheckIsOpen()
        local CanDownloadDLC = CS.XRemoteConfig.LaunchSelectType and CS.XRemoteConfig.LaunchSelectType ~= 0
        return IsDlcBuild and XDlcManager.HasDlcList() and CanDownloadDLC and not XUiManager.IsHideFunc
    end
    
    --仅可选基础包
    function XDlcManager.CheckIsOnlyBasicPackage()
        -- 0：默认禁用下载选择； 1：启用（可选基础或全量）； 2：启用（仅可选基础，暂用于xf测试）
        return CS.XRemoteConfig.LaunchSelectType == 2
    end

    function XDlcManager.HasDlcList()
        local dlcListConfig = XDlcConfig.GetDlcListConfig()
        return (next(dlcListConfig))
    end

    function XDlcManager.GetLaunchDlcManager()
        return XLaunchDlcManager
    end

    function XDlcManager.CheckIsDownloading()
        return DownloadState == STATE_DOWNLOAD_ING
    end

    --- 下载入口是否开放
    ---@param entryType number
    ---@param entryParam number 可为0
    ---@return boolean
    --------------------------
    function XDlcManager.CheckNeedDownload(entryType, entryParam)
        if not XTool.IsNumberValid(entryType) then
            return false
        end
        
        if not XDlcManager.CheckIsOpen() then
            return false
        end

        local dlcListId = XDlcConfig.GetDlcListIdByEntry(entryType, entryParam)
        if not XTool.IsNumberValid(dlcListId) then
            return false
        end

        local itemData = XDlcManager.GetItemData(dlcListId)
        return not itemData:IsComplete()
    end

    --- 获取Dlc列表数据
    ---@param id number dlcListId
    ---@return XDLCItem
    --------------------------
    function XDlcManager.GetItemData(id)
        local item = ItemMap[id]
        if not item then
            item = XDLCItem.New(id)
            local config = XDlcConfig.GetListConfigById(id)
            local validDlcIdList = {}
            for _, dlcId in ipairs(config.PatchConfigIds) do
                if DlcIndexInfo[dlcId] then
                    table.insert(validDlcIdList, dlcId)
                end
            end
            if #validDlcIdList <= 0 then
                XLog.Warning("[DLC] init dlc list skipped Id:" .. id .. " not has dlc patch. PatchConfigIds:" .. table.concat(config.PatchConfigIds, ","))
            end
            item:SetValidDlcIds(validDlcIdList)
            ItemMap[id] = item
        end
        return ItemMap[id]
    end

    function XDlcManager.GetAllItemList()
        if not AllItemList then
            AllItemList = {}
            local dlcListConfig = XDlcConfig.GetDlcListConfig()
            for id, config in pairs(dlcListConfig) do
                if config.RootId ~= 0 then
                    local item = XDlcManager.GetItemData(id)
                    table.insert(AllItemList, item)
                end
            end
            table.sort(AllItemList, function(a, b)
                return a:GetId() < b:GetId()
            end)
        end
        return AllItemList
    end

    --- 获取 Dlc列表
    ---@param rootId number 根节点id
    ---@return XDLCItem[]
    --------------------------
    function XDlcManager.GetItemList(rootId)
        local dlcListIds = XDlcConfig.GetDlcListIdsByRootId(rootId) or {}
        ---@type XDLCItem[]
        local list = {}
        for _, dlcId in pairs(dlcListIds) do
            local item = XDlcManager.GetItemData(dlcId)
            if XDlcManager.FilterItem(item) then
                table.insert(list, item)
            end
        end

        table.sort(list, function(a, b)
            local downloadA = a:IsComplete()
            local downloadB = b:IsComplete()
            if downloadA ~= downloadB then
                return downloadB
            end
            return a:GetId() < b:GetId()
        end)

        return list
    end

    --- 获取未下载完的Dlc列表
    ---@param rootId number 根节点id
    ---@return XDLCItem[]
    --------------------------
    function XDlcManager.GetUnDownloadItemList(rootId)
        local dlcListIds = XDlcConfig.GetDlcListIdsByRootId(rootId) or {}
        ---@type XDLCItem[]
        local list = {}
        for _, dlcId in pairs(dlcListIds) do
            local item = XDlcManager.GetItemData(dlcId)
            if not item:IsComplete() and XDlcManager.FilterItem(item) then
                table.insert(list, item)
            end
        end

        table.sort(list, function(a, b)
            return a:GetId() < b:GetId()
        end)
        
        return list
    end
    
    --- 过滤没有独立资源的包
    ---@param item XDLCItem
    ---@return boolean
    --------------------------
    function XDlcManager.FilterItem(item)
        if not item then
            return false
        end

        if XDlcManager.GetTotalDownloadSize(item:GetValidDlcIds()) <= 0 then
            XLog.Debug(string.format("[DLC] 分包<%s>没有独立资源，请检查DlcList.tab! Id = %s", item:GetTitle(), tostring(item:GetId())))
            return false
        end
        
        return true
    end

    function XDlcManager.GetDlcSizeStr(dlcIds)
        return XDlcManager.GetDownloadedSizeStr(dlcIds) .. "/" .. XDlcManager.GetTotalSizeStr(dlcIds)
    end

    function XDlcManager.GetDownloadedSizeStr(dlcIds)
        local downloadedSize = XDlcManager.GetDownloadedSize(dlcIds)
        local num, unit = XDlcConfig.GetSizeAndUnit(downloadedSize)
        return num .. unit
    end

    function XDlcManager.GetTotalSizeStr(dlcIds)
        local totalSize = XDlcManager.GetTotalDownloadSize(dlcIds)
        local numTotal, unitTotal = XDlcConfig.GetSizeAndUnit(totalSize)
        return numTotal .. unitTotal
    end
    
    --- 下载全部DLC内容
    ---@param itemList XDLCItem[]
    ---@return void
    --------------------------
    function XDlcManager.DownloadAllDlc(itemList, singleCb, allFinishCb)
        itemList = itemList or {}
        local index, count = 1, #itemList
        if index > count then
            return
        end

        if XDlcManager.CheckIsDownloading() then
            XUiManager.TipText("DlcDownloadIsProgress")
            return
        end
        IsInterruptDownload = false
        IsDownloadAll = true
        
        local downloadItem
        
        DownloadAllTimer = XScheduleManager.ScheduleForever(function()
            if index > count or IsInterruptDownload then
                IsDownloadAll = false
                --移除定时器
                if DownloadAllTimer then
                    XScheduleManager.UnSchedule(DownloadAllTimer)
                    DownloadAllTimer = nil
                end
                --全部下载完
                if index >= count then
                    if allFinishCb then allFinishCb() end
                end
                --暂停正在下载
                local item = XDlcManager.GetDownloadingItem()
                if item then
                    item:Pause()
                end
                return
            end

            if DownloadState == STATE_DOWNLOAD_ING then
                return
            end
            --提示上一个已经下载完
            if downloadItem and downloadItem:IsComplete() then
                XUiManager.PopupLeftTip(XUiHelper.GetText("DlcDownloadCompleteTitle"), downloadItem:GetTitle())
            end
            downloadItem = itemList[index]
            if downloadItem then
                downloadItem:TryDownload()
            end
            if singleCb then singleCb() end
            index = index + 1
        end, 10, 0)
    end
    
    function XDlcManager.InterruptDownload()
        IsDownloadAll = false
        IsInterruptDownload = true
    end
    
    function XDlcManager.CheckIsDownloadAll()
        return IsDownloadAll
    end

    function XDlcManager.DownloadDlcByListId(listId, progressCb, doneCb)
        --单任务下载模式
        if DownloadState == STATE_DOWNLOAD_ING then
            XUiManager.TipText("DlcDownloadIsProgress")
            return
        end
        local newDoneCb = function(isPause)
            print("newDoneCb: isPause:" .. tostring(isPause))
            if doneCb then
                doneCb()
            end
            if not isPause then
                XDlcManager.ResetDownloadState(isPause)
                XDlcManager.MarkRedPoint(listId, false)
                DoRecord(listId)
            end
            XEventManager.DispatchEvent(XEventId.EVENT_DLC_DOWNLOAD_STOP)
        end
        
        local exitCb = function() 
            local itemData = XDlcManager.GetItemData(CurrentDlcListId)
            if itemData then
                itemData:Pause()
            end
        end
        
        --上个资源未下载完，点击了暂停，需要恢复暂停状态
        if XTool.IsNumberValid(CurrentDlcListId) and CurrentDlcListId ~= listId then
            FileModule.ResumeDownload()
            CurrentProcessCb = nil
            CurrentDoneCb = nil
        end
        local dlcItem = XDlcManager.GetItemData(listId)
        local dlcIds = dlcItem:GetValidDlcIds()
        CurrentDlcListId = listId
        CurrentProcessCb = progressCb
        CurrentDoneCb = doneCb

        DownloadState = STATE_DOWNLOAD_ING
        
        XDlcManager.MarkRedPoint(listId, true)
        XLaunchDlcManager.DownloadDlc(dlcIds, progressCb, newDoneCb, exitCb)
    end

    function XDlcManager.IsCurDlcListId(listId)
        return CurrentDlcListId == listId
    end

    -- 开始下载后，设置下载模块（XLaunchFileModule）
    function XDlcManager.SetFileModule(fileModule)
        if FileModule ~= fileModule then
            fileModule.ResumeDownload()
        end
        FileModule = fileModule
    end

    function XDlcManager.OnPreEnterFight()
        --没有正在下载的任务
        if DownloadState ~= STATE_DOWNLOAD_ING then
            return
        end
        XDlcManager.PauseDownloadDlc()
    end

    function XDlcManager.OnExitFight()
        --没有需要恢复的任务
        if DownloadState ~= STATE_DOWNLOAD_PAUSE then
            return
        end
        XDlcManager.ResumeDownloadDlc()
    end

    function XDlcManager.PauseDownloadDlc()
        if DownloadState ~= STATE_DOWNLOAD_ING then
            XLog.Error("[DLC] PauseDownloadDlc Error, DownloadState ~= STATE_DOWNLOAD_ING")
            return
        end
        DownloadState = STATE_DOWNLOAD_PAUSE
        FileModule.PauseDownload()
    end

    function XDlcManager.ResumeDownloadDlc()
        if DownloadState ~= STATE_DOWNLOAD_PAUSE then
            XLog.Error("[DLC] ResumeDownloadDlc Error, DownloadState ~= STATE_DOWNLOAD_PAUSE")
            return
        end
        DownloadState = STATE_DOWNLOAD_READY
        FileModule.ResumeDownload()
        XDlcManager.DownloadDlcByListId(CurrentDlcListId, CurrentProcessCb, CurrentDoneCb)
    end

    function XDlcManager.ResetDownloadState(isPause)
        FileModule = nil
        CurrentDlcListId = nil
        CurrentProcessCb = nil
        CurrentDoneCb = nil
        DownloadState = STATE_DOWNLOAD_READY
    end
    
    --- 通用正在下载提示
    --------------------------
    function XDlcManager.TipDownloading()
        if not (XDlcManager.CheckIsDownloading() and XTool.IsNumberValid(CurrentDlcListId)) then
            return
        end
        local itemData = XDlcManager.GetItemData(CurrentDlcListId)
        if not itemData then
            return
        end
        local tip = itemData and itemData:GetTitle() or "nil"
        XUiManager.TipMsg(XUiHelper.GetText("DlcDownloadingTips", tip))
    end
    
    --- 获取正在下载的分包
    ---@return XDLCItem
    --------------------------
    function XDlcManager.GetDownloadingItem()
        if not (XDlcManager.CheckIsDownloading() and XTool.IsNumberValid(CurrentDlcListId)) then
            return
        end
        
        return XDlcManager.GetItemData(CurrentDlcListId)
    end

    -- 功能入口检查下载
    function XDlcManager.CheckDownloadForEntry(entryType, entryParam, doneCb)
        if not XDlcManager.CheckIsOpen() then
            if doneCb then doneCb() end
            return
        end

        local dlcListId = XDlcConfig.GetDlcListIdByEntry(entryType, entryParam)
        XDlcManager.TryDownloadByListId(dlcListId, nil, doneCb)
    end

    -- 进入关卡时检查下载
    function XDlcManager.CheckDownloadForStage(stageId, doneCb)
        if not XDlcManager.CheckIsOpen() then
            if doneCb then doneCb() end
            return 
        end

        local dlcListIds = XDlcConfig.GetDlcListIdByStageId(stageId)
        if XTool.IsTableEmpty(dlcListIds) then
            if doneCb then doneCb() end
            return
        end

        local temDlcListId
        local downloaded = false
        for _, dlcListId in ipairs(dlcListIds or {}) do
            local itemData = XDlcManager.GetItemData(dlcListId)
            --当前关卡已有分包下载完成
            if itemData:IsComplete() then
                downloaded = true
                break
            end
            temDlcListId = dlcListId
        end

        if downloaded then
            if doneCb then doneCb() end
            return
        end

        XDlcManager.TryDownloadByListId(temDlcListId, nil, doneCb)
    end

    function XDlcManager.TryDonwloadByIds(dlcIds, doneCb)
        if not dlcIds then
            doneCb()
            return
        end

        local needDownload = false
        for _, dlcId in pairs(dlcIds) do
            needDownload = XLaunchDlcManager.CheckGameNeedDownload(dlcId)
            if needDownload then
                break
            end
        end
        if needDownload then
            XLuaUiManager.Open("UiDownload", function()
                XLaunchDlcManager.DownloadDlc(dlcIds, nil, doneCb)
            end)
        else
            doneCb()
        end
    end

    --- 尝试下载Dlc资源
    ---@param dlcListId number DlcList.tab的Id
    ---@param progressCb function 进度改变回调
    ---@param doneCb function 下载完成回调
    ---@param beginCb function 下载开始回调
    ---@return void
    --------------------------
    function XDlcManager.TryDownloadByListId(dlcListId, progressCb, doneCb, beginCb)
        --未传参
        if not XTool.IsNumberValid(dlcListId) then
            if doneCb then
                doneCb()
            end
            return
        end
        local itemData = XDlcManager.GetItemData(dlcListId)
        --已经下载完
        if itemData:IsComplete() then
            if doneCb then
                doneCb()
            end
            return
        end
        local jumpCb = function()
            XLuaUiManager.Open("UiDownLoadMain", itemData:GetRootId(), itemData:GetId())
        end

        local downloadCb = function()
            if XDlcManager.CheckIsDownloading() then
                XDlcManager.TipDownloading()
                return
            end
            if beginCb then beginCb() end
            itemData:TryDownload(progressCb, doneCb)
        end
        local content = XUiHelper.GetText("DlcDownloadContentAndSizeTip", itemData:GetTitle(), itemData:GetTotalSizeWithUnit())
        local subContent = ""
        if CS.UnityEngine.Application.internetReachability == CS.UnityEngine.NetworkReachability.ReachableViaCarrierDataNetwork then
            subContent = XUiHelper.GetText("CellularNetworkDownloadTip")
        end
        XUiManager.DialogDownload(XUiHelper.GetText("DlcDownloadTitle"), content, subContent, downloadCb, jumpCb)
    end

    function XDlcManager.TryDownloadByEntryTypeAndParam(entryType, entryParam, progressCb, doneCb, beginCb)
        local dlcListId = XDlcConfig.GetDlcListIdByEntry(entryType, entryParam)
        if not XTool.IsNumberValid(dlcListId) then
            return
        end
        XDlcManager.TryDownloadByListId(dlcListId, progressCb, doneCb, beginCb)
    end

    -- 清理dlc资源（不包括基础及通用）
    function XDlcManager.CleanDlcFiles(dlcId, cb)
        if dlcId == DLC_BASE_INDEX or dlcId == DLC_COMMON_INDEX then
            XLog.Error("[DLC] 清理dlc资源失败 dlcId:" .. tostring(dlcId))
            if cb then
                cb(false, 0)
            end
            return
        end

        local PathModule = XLaunchDlcManager.GetPathmodule()
        local DocFileModule = XLaunchDlcManager.GetFilemodule()
        local VersionModule = XLaunchDlcManager.GetVersionmodule()

        local DocumentFilePath = PathModule.GetDocumentFilePath()
        local ResFileType = RES_FILE_TYPE.MATRIX_FILE
        local NeedLaunchTest = CS.XResourceManager.NeedLaunchTest
        local dirPath = DocumentFilePath .. "/" .. ResFileType .. "/"
        if NeedLaunchTest then
            dirPath = DocFileModule.LaunchTestDirDoc .. "/" .. ResFileType .. "/"
        end

        local indexInfo = DlcIndexInfo[dlcId]
        if indexInfo == nil then
            XLog.Error("[DLC] 清理dlc资源失败 indexInfo is nil, dlcId:" .. tostring(dlcId))
            if cb then
                cb(false, 0)
            end
            return
        end

        local commonInfo = DlcIndexInfo[DLC_COMMON_INDEX]
        local baseInfo = DlcIndexInfo[DLC_BASE_INDEX]

        local count, size = 0, 0
        local logTab = {}
        for assetPath, info in pairs(indexInfo) do
            if not baseInfo[assetPath] and not commonInfo[assetPath] then
                local file = dirPath .. info[1]
                if CS.System.IO.File.Exists(file) then
                    CS.XFileTool.DeleteFile(file)
                    XLaunchDlcManager.SetDownloadedFile(info[1], false)
                    table.insert(logTab, info[1])
                    count = count + 1
                    size = size + info[3]
                end
            elseif IsDebugBuild then
                table.insert(logTab, info[1] .. "保留，base:" .. tostring(baseInfo[assetPath] ~= nil) .. ", common:" .. tostring(commonInfo[assetPath] ~= nil))
            end
        end

        if IsDebugBuild then
            XLog.Debug("[DLC] 清理DLC .." .. dlcId .. "下载资源，数量：" .. count .. "，大小：" .. math.ceil(size/1024/1024) .. "mb. " .. table.concat(logTab, "\n"))
        end
        XLaunchDlcManager.SetDlcDownloadedRecord(dlcId, false)
        if cb then
            cb(true, size)
        end
    end

    --=======资源索引接口begin
    -- local DlcSizeDic = {}
    -- local DlcCommonSizeDic = {}

    -- 获取dlc总大小（独占, 通用）
    -- commonTab 可选，收集记录，当多次调用时保证一个通用资源仅统计一次
    local _GetTotalDownloadSize = function(dlcId, commonTab)
        local size = 0
        local indexInfo = DlcIndexInfo[dlcId]
        if indexInfo == nil then
            XLog.Error("indexInfo == nil dlcId:" .. tostring(dlcId))
            return 0, 0
        end
        local commonSize = 0
        if dlcId == DLC_COMMON_INDEX then
            for assetPath, info in pairs(indexInfo) do
                size = size + info[3]
            end
        else
            -- 区分通用资源
            local commonInfo = DlcIndexInfo[DLC_COMMON_INDEX]
            local baseInfo = DlcIndexInfo[DLC_BASE_INDEX]
            for assetPath, info in pairs(indexInfo) do
                if not baseInfo[assetPath] then -- 基础包资源不需统计
                    if not commonInfo[assetPath] then
                        size = size + info[3]
                    else
                        if commonTab then
                            if not commonTab[assetPath] then
                                commonTab[assetPath] = true
                                commonSize = commonSize + info[3]
                            end
                        else
                            commonSize = commonSize + info[3]
                        end
                    end
                end
            end
        end
        return size, commonSize
    end

    -- 获取dlc已下载大小（独占, 通用）
    --  commonTab 可选，收集记录，当多次调用时保证一个通用资源仅统计一次
    local _GetDownloadedSize = function(dlcId, commonTab)
        local indexInfo = DlcIndexInfo[dlcId]
        if indexInfo == nil then
            XLog.Error("indexInfo == nil dlcId:" .. tostring(dlcId))
            return 0, 0
        end
        local size = 0
        local commonSize = 0
        local commonInfo = DlcIndexInfo[DLC_COMMON_INDEX]
        local baseInfo = DlcIndexInfo[DLC_BASE_INDEX] -- 基础包资源不需统计
        for assetPath, info in pairs(indexInfo) do
            if not baseInfo[assetPath] and XLaunchDlcManager.IsNameDownloaded(info[1]) then
                if not commonInfo[assetPath] then
                    size = size + info[3]
                else
                    if commonTab then
                        if not commonTab[assetPath] then
                            commonTab[assetPath] = true
                            commonSize = commonSize + info[3]
                        end
                    else
                        commonSize = commonSize + info[3]
                    end
                end
            end
        end
        return size, commonSize
    end

    -- 已下载大小
    XDlcManager.GetDownloadedSize = function(dlcIds)
        local size = 0
        local commonSize = 0
        local commmonTab = {}
        local tab = {}
        for _, dlcId in pairs(dlcIds) do
            local dlcSize, cSize = _GetDownloadedSize(dlcId, commmonTab)
            size = size + dlcSize
            commonSize = commonSize + cSize
            -- table.insert(tab, dlcId .. ", size:" .. (math.ceil(dlcSize/1024/1024))  .. "mb, common:" .. (math.ceil(cSize/1024/1024)) .. "mb")
        end
        -- XLog.Debug("[Download] GetDownloadedSize("  .. table.concat(dlcIds,",") .. ") size:" .. (math.ceil((size+commonSize)/1024/1024)) .. "mb = dlc:" .. (math.ceil(size/1024/1024)) .. "mb + common:" .. (math.ceil(commonSize/1024/1024)) .. "mb\n" .. table.concat(tab, "\n"))
        return size + commonSize
    end

    -- 总下载大小
    XDlcManager.GetTotalDownloadSize = function(dlcIds)
        local size = 0
        local commonSize = 0
        local tab = {}
        local commmonTab = {}
        for _, dlcId in pairs(dlcIds) do
            local dlcSize, cSize = _GetTotalDownloadSize(dlcId, commmonTab)
            size = size + dlcSize
            commonSize = commonSize + cSize
            -- table.insert(tab, dlcId .. ", size:" .. (math.ceil(dlcSize/1024/1024)) .. "mb" .. ", common Size:" .. (math.ceil(cSize/1024/1024)) .. "mb")
        end
        -- XLog.Debug("[Download] GetTotalDownloadSize("  .. table.concat(dlcIds,",") .. ") size:" .. (math.ceil((size+commonSize)/1024/1024)) .. "mb = dlc:" .. (math.ceil(size/1024/1024)) .. "mb + common:" .. (math.ceil(commonSize/1024/1024)) .. "mb\n" .. table.concat(tab, "\n"))
        return size + commonSize
    end

    -- test
    XDlcManager.GetDownloadSizeById = function(dlcId)
        local size, commonSize = _GetTotalDownloadSize(dlcId, {}, 0)
        return size
    end

    XDlcManager.GetAllDlcId = function(dlcId)
        local idList = {}
        for dlcId, _ in pairs(DlcIndexInfo) do
            table.insert(idList, dlcId)
        end
        return idList
    end

    function XDlcManager.PrintAllDownloadSize()
    do return end
        local idMap = {}
        for _, itemData in ipairs(XDlcManager.GetAllItemList()) do
            for _, id in ipairs(itemData:GetDlcIdList()) do
                if not idMap[id] then
                    idMap[id] = 0
                end
            end
        end

        for patchId, _ in pairs(idMap) do
            local size = XDlcManager.GetDownloadSizeById(patchId)
            idMap[patchId] = math.ceil(size / 1024 / 1024) .. "(mb)"
        end
        XLog.Debug("[DLC] >>>>下载分类的资源包大小情况：", idMap)

        local idMap = {}
        for i, patchId in pairs(XDlcManager.GetAllDlcId()) do
            local size = XDlcManager.GetDownloadSizeById(patchId)
            idMap[patchId] = math.ceil(size / 1024 / 1024) .. "(mb)"
        end
        XLog.Debug("[DLC] >>>>所有资源包大小情况：", idMap)

        
        local commonInfo = DlcIndexInfo[DLC_COMMON_INDEX]
        for k, v in pairs(commonInfo) do
            XLog.Debug(" === Common, k:" .. k .. ',v:' .. v[1] .. ", " .. v[2] .. ", " .. v[3])
            break
        end
    end
    --========资源索引接口end

    XDlcManager.Init()
    return XDlcManager
end