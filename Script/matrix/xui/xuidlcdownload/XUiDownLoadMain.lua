local XUiGridDownload = require("XUi/XUiDlcDownload/XUiGrid/XUiGridDownload")

---@class XUiDownLoadMain : XLuaUi
local XUiDownLoadMain = XLuaUiManager.Register(XLuaUi, "UiDownLoadMain")

local SortRoodIds = { 
    XDlcConfig.RoodId.MainLine,
    XDlcConfig.RoodId.BranchLine,
    XDlcConfig.RoodId.Challenge,
    XDlcConfig.RoodId.Other
}

function XUiDownLoadMain:OnAwake()
    self:InitUi()
    self:InitCb()
end

function XUiDownLoadMain:OnStart(rootId, selectId)
    self.DefaultIndex = self:GetTabIndexByRootId(rootId)
    self.DefaultSelectId = selectId
    self:InitView()
end

function XUiDownLoadMain:OnDestroy()
    XEventManager.RemoveEventListener(XEventId.EVENT_DLC_DOWNLOAD_STOP, self.RefreshView, self)
end

function XUiDownLoadMain:InitUi()
    local tab = {}
    for tabIndex, rootId in pairs(SortRoodIds) do
        local btn = tabIndex == 1 and self.BtnTab or XUiHelper.Instantiate(self.BtnTab, self.TabBtnGroup.transform)
        local config = XDlcConfig.GetListConfigById(rootId)
        btn:SetNameByGroup(0, config.Title)
        tab[tabIndex] = btn
    end
    self.TabBtnGroup:Init(tab, function(index)
        self:OnSelectTab(index)
    end)
    
    self.DynamicTable = XDynamicTableNormal.New(self.PanelAchvList)
    self.DynamicTable:SetProxy(XUiGridDownload)
    self.DynamicTable:SetDelegate(self)
    
    self.GridTask.gameObject:SetActiveEx(false)
    
    self.TxtDownloadAll = XUiHelper.GetText("DlcDownloadAll")
    self.TxtDownloadPause = XUiHelper.GetText("DlcDownloadPause")
    
end

function XUiDownLoadMain:InitCb()
    self:BindExitBtns()
    
    self.BtnDownloadAll.CallBack = function() 
        self:OnBtnDownloadAllClick()
    end
    
    self.BtnInfo.CallBack = function() 
        self:OnBtnInfoClick()
    end
end

function XUiDownLoadMain:InitView()

    self.PanelAsset = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, 
            XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)

    self.TabBtnGroup:SelectIndex(self.DefaultIndex)

    if XDataCenter.DlcManager.CheckRedPoint() then
        XDataCenter.DlcManager.ClearRedPoint()
    end
    
    XEventManager.AddEventListener(XEventId.EVENT_DLC_DOWNLOAD_STOP, self.RefreshView, self)
end

function XUiDownLoadMain:OnSelectTab(index)
    if self.TabIndex == index then
        return
    end
    self.TabIndex = index
    self.RootId = self:GetRootIdByTabIndex(index)
    self:RefreshView()
end

function XUiDownLoadMain:RefreshView()
    if XTool.UObjIsNil(self.GameObject) then
        return
    end
    
    if not XTool.IsNumberValid(self.TabIndex)
            or not XTool.IsNumberValid(self.RootId) then
        return
    end

    local config = XDlcConfig.GetListConfigById(self.RootId)
    self.TxtName.text = config.Title
    
    local list = XDataCenter.DlcManager.GetItemList(self.RootId)
    local selectIndex
    if XTool.IsNumberValid(self.DefaultSelectId) then
        for idx, item in ipairs(list or {}) do
            if item:GetId() == self.DefaultSelectId then
                selectIndex = idx
                break
            end
        end
        self.DefaultSelectId = nil
    else
        selectIndex = self:GetDownloadIndex(list)
    end
    self.DataList = list
    self.DynamicTable:SetDataSource(list)
    self.DynamicTable:ReloadDataSync(selectIndex)

    self:RefreshBtnDownAll()
end

function XUiDownLoadMain:OnDynamicTableEvent(evt, index, grid)
    if evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.DataList[index])
    elseif evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self)
    elseif evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RECYCLE then
        grid:Recycle()
    end
end

function XUiDownLoadMain:GetTabIndexByRootId(rootId)
    if not XTool.IsNumberValid(rootId) then
        return 1
    end
    for index, rtId in pairs(SortRoodIds) do
        if rootId == rtId then
            return index
        end
    end
    return 1
end

function XUiDownLoadMain:GetRootIdByTabIndex(tableIndex)
    if not XTool.IsNumberValid(tableIndex) then
        return XDlcConfig.RoodId.MainLine
    end
    for index, rootId in pairs(SortRoodIds) do
        if index == tableIndex then
            return rootId
        end
    end
    return XDlcConfig.RoodId.MainLine
end 

function XUiDownLoadMain:OnBtnDownloadAllClick()
    if XDataCenter.DlcManager.CheckIsDownloadAll() then
        XDataCenter.DlcManager.InterruptDownload()
        self:RefreshBtnDownAll()
        return
    end
    
    local itemList = {}
    if XTool.IsNumberValid(self.RootId) then
        itemList = appendArray(itemList, XDataCenter.DlcManager.GetUnDownloadItemList(self.RootId))
        for _, rootId in ipairs(SortRoodIds) do
            if rootId ~= self.RootId then
                itemList = appendArray(itemList, XDataCenter.DlcManager.GetUnDownloadItemList(rootId))
            end
        end
    else
        for _, rootId in ipairs(SortRoodIds) do
            itemList = appendArray(itemList, XDataCenter.DlcManager.GetUnDownloadItemList(rootId))
        end
    end
    
    XDataCenter.DlcManager.DownloadAllDlc(itemList)
    self:RefreshBtnDownAll()
end

function XUiDownLoadMain:RefreshBtnDownAll()
    --仅基础包时，屏蔽全部下载按钮
    local isOnlyBasic = XDataCenter.DlcManager.CheckIsOnlyBasicPackage()
    if isOnlyBasic then
        self.BtnDownloadAll.gameObject:SetActiveEx(false)
        return
    end
    local itemList = {}
    for _, rootId in ipairs(SortRoodIds) do
        itemList = appendArray(itemList, XDataCenter.DlcManager.GetUnDownloadItemList(rootId))
    end
    --没有需要下载内容
    if XTool.IsTableEmpty(itemList) then
        self.BtnDownloadAll.gameObject:SetActiveEx(false)
        return
    end
    self.BtnDownloadAll.gameObject:SetActiveEx(true)
    local downloadAll = XDataCenter.DlcManager.CheckIsDownloadAll()
    self.BtnDownloadAll:SetNameByGroup(0, downloadAll and self.TxtDownloadPause or self.TxtDownloadAll)
end

function XUiDownLoadMain:OnBtnInfoClick()
    local title = XUiHelper.GetText("DlcDownloadTitle")
    local content = XUiHelper.ReplaceTextNewLine(XUiHelper.GetText("DlcDownloadPreviewTip"))
    XUiManager.UiFubenDialogTip(title, content)
end 

---@param listItem XDLCItem[]
function XUiDownLoadMain:GetDownloadIndex(listItem)
    if XTool.IsTableEmpty(listItem) then
        return
    end
    local index
    for i, item in ipairs(listItem) do
        if item:IsDownloading() or item:IsPause() then
            index = i
            break
        end
    end
    return index
end 