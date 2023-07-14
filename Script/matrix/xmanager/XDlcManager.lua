--- 占领副本管理器
XDlcManagerCreator = function()
    local XDlcManager = {}

    local AllTitleList = nil
    local AllItemList = nil
    local ItemMap = nil

    local XLaunchDlcManager = nil
    local IsDlcBuild = false

    function XDlcManager.Init()
        XLaunchDlcManager = require("XLaunchDlcManager")
        IsDlcBuild = CS.XInfo.IsDlcBuild
        ItemMap = {}
    end

    ----------- 列表数据 begin-----------
    local DlcItemData = XClass(nil, "DlcItemData")
    function DlcItemData:Ctor(id)
        self._id = id
    end

    function DlcItemData:GetConfig()
        return XDlcConfig.GetListConfigById(self._id)
    end

    function DlcItemData:GetId()
        return self._id
    end
    
    function DlcItemData:GetDlcId()
        return self:GetConfig().PatchConfigIds
    end

    function DlcItemData:GetTitle()
        return self:GetConfig().Title
    end
    
    function DlcItemData:GetDesc()
        local cfg = self:GetConfig()
        if string.IsNilOrEmpty(cfg.Desc) then
            local rootData = XDlcManager.GetItemData(cfg.RootId)
            return rootData:GetDesc()
        end
        return cfg.Desc
    end

    function DlcItemData:HasDownloaded()
        local dlcIds = self:GetDlcId()
        local hasDownloaded = true
        for _, dlcId in ipairs(dlcIds) do
            hasDownloaded = XLaunchDlcManager.HasDownloadedDlc(dlcId)
            if not hasDownloaded then
                break
            end
        end
        return hasDownloaded
    end
    ----------- 列表数据 end-----------

    function XDlcManager.HasDlcList()
        local dlcListConfig = XDlcConfig.GetDlcListConfig()
        return (next(dlcListConfig))
    end
    
    function XDlcManager.GetItemData(id)
        if not ItemMap[id] then
            ItemMap[id] = DlcItemData.New(id)
        end
        return ItemMap[id]
    end

    function XDlcManager.GetAllItemList()
        if not AllItemList then
            AllItemList = {}
            local dlcListConfig = XDlcConfig.GetDlcListConfig()
            local GetItemData = XDlcManager.GetItemData
            for id, config in pairs(dlcListConfig) do
                if config.RootId ~= 0 then
                    local data = GetItemData(id)
                    table.insert(AllItemList, data)
                end
            end
            table.sort(AllItemList, function(a, b)
                return a:GetId() < b:GetId()
            end)
        end
        return AllItemList
    end

    function XDlcManager.GetDownloadSize(dlcIds)
        return XLaunchDlcManager.GetDownloadSize(dlcIds)
    end

    function XDlcManager.DownloadDlc(dlcIds, processCb, doneCb)
        return XLaunchDlcManager.DownloadDlc(dlcIds, processCb, doneCb)
    end

    -- 功能入口检查下载
    function XDlcManager.CheckDownloadForEntry(entryType, entryParam, doneCb)
        if not IsDlcBuild then
            doneCb()
            return
        end

        XLog.Debug("===CheckDownloadForEntry entryType: " .. tostring(entryType) .. ", entryParam: " .. tostring(entryParam))
        local dlcIds = XDlcConfig.GetDlcIdsByEntry(entryType, entryParam)
        XDlcManager.TryDonwloadByIds(dlcIds, doneCb)
    end

    -- 进入关卡时检查下载
    function XDlcManager.CheckDownloadForStage(stageId, doneCb)
        if not IsDlcBuild then
            doneCb()
            return
        end

        XLog.Debug("====== CheckDownloadForStage stageId:" .. tostring(stageId))
        local dlcIds = XDlcConfig.GetDlcIdsByStageId(stageId)
        XDlcManager.TryDonwloadByIds(dlcIds, doneCb)
    end

    function XDlcManager.TryDonwloadByIds(dlcIds, doneCb)
        if not dlcIds then
            doneCb()
            return
        end

        local needDownload = false
        for _, dlcId in pairs(dlcIds) do
            needDownload = XLaunchDlcManager.NeedDownloadDlc(dlcId)
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


    XDlcManager.Init()
    return XDlcManager
end