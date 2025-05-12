---@class XUiVideoPreloadDownloadTip : XLuaUi
local XUiVideoPreloadDownloadTip = XLuaUiManager.Register(XLuaUi, "UiVideoPreloadDownloadTip")
function XUiVideoPreloadDownloadTip:OnAwake()
    self.IsOnCompleteThenEnterFight = false
    self.ResIdDic = {}
    self:InitButton()
    self:InitDynamicTable()
    XEventManager.AddEventListener(XEventId.EVENT_RES_UPDATE, self.OnDownloadProgressUpdate, self)
    XEventManager.AddEventListener(XEventId.EVENT_RES_COMPLETE, self.OnResDownloadComplete, self)
end 

function XUiVideoPreloadDownloadTip:InitButton()
    XUiHelper.RegisterClickEvent(self, self.BtnDownloadAll, self.OnBtnDownloadAllClick) -- 立即下载
    XUiHelper.RegisterClickEvent(self, self.BtnUiDownLoadMain, self.OnBtnUiDownLoadMainClick)
    XUiHelper.RegisterClickEvent(self, self.BtnSkip, self.OnBtnSkipClick)
    XUiHelper.RegisterClickEvent(self, self.BtnSetStateToggle, self.OnBtnSetStateToggleClick)
    XUiHelper.RegisterClickEvent(self, self.BtnTanchuangClose, self.OnBtnTanchuangCloseClick)
end 

function XUiVideoPreloadDownloadTip:OnBtnDownloadAllClick()
    if self.IsOnCompleteThenEnterFight then
        return
    end

    for k, resId in ipairs(self.ResIdList) do
        XMVCA.XSubPackage:AddResToDownload(resId)
    end
    self.BtnDownloadAll:SetDisable(true)
    self.IsOnCompleteThenEnterFight = true
end

function XUiVideoPreloadDownloadTip:OnBtnUiDownLoadMainClick()
    XLuaUiManager.Open("UiDownLoadMain", self.SubpackageGroupId)
end

function XUiVideoPreloadDownloadTip:OnBtnSkipClick()
    self:Close()
    if self.EnterFightCb then
        self.EnterFightCb()
    end
end

function XUiVideoPreloadDownloadTip:OnBtnSetStateToggleClick()
end

function XUiVideoPreloadDownloadTip:OnBtnTanchuangCloseClick()
    if self.IsOnCompleteThenEnterFight then
        XLuaUiManager.Open("UiDialog", nil, XUiHelper.GetText("UiVideoPreloadDownloadTipExitConfirm"), XUiManager.DialogType.Normal, nil, function ()
            self:Close()
        end)
    else
        self:Close()
    end
end

function XUiVideoPreloadDownloadTip:InitDynamicTable()
    local XUiGridDownload = require("XUi/XUiSubPackage/XUiGrid/XUiGridVideoTipDownload")
    self.DynamicTable = XUiHelper.DynamicTableNormal(self, self.DownloadList, XUiGridDownload)
    self.DynamicTable:SetProxy(XUiGridDownload)
    self.DynamicTable:SetDelegate(self)
    self.DynamicTable:GetGrid().gameObject:SetActiveEx(false)
end

function XUiVideoPreloadDownloadTip:OnStart(resIdList, enterFightCb)
    self.ResIdList = resIdList
    self.EnterFightCb = enterFightCb
end

function XUiVideoPreloadDownloadTip:OnEnable()
    self:RefreshDynamicTable()

    -- 刷新按钮状态
    local isResDownloading = false
    for _, resId in ipairs(self.ResIdList) do
        local resItem = XMVCA.XSubPackage:GetResourceItem(resId)
        if resItem:GetState() == XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.DOWNLOADING then
            isResDownloading = true
            break
        end
    end
    self.BtnDownloadAll:SetDisable(isResDownloading)
    self.IsOnCompleteThenEnterFight = isResDownloading
end

function XUiVideoPreloadDownloadTip:OnDownloadProgressUpdate(resId, progress)
    local grid = self.ResIdDic[resId]
    if grid then
        grid:RefreshProgress(progress)
    end
end

function XUiVideoPreloadDownloadTip:RefreshDynamicTable()
    self.DynamicTable:SetDataSource(self.ResIdList)
    self.DynamicTable:ReloadDataSync()
end

function XUiVideoPreloadDownloadTip:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        local resId = self.ResIdList[index]
        self.ResIdDic[resId] = grid
        grid:SetInitData(resId)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local resId = self.ResIdList[index]
        local resItem = XMVCA.XSubPackage:GetResourceItem(resId)
        grid:RefreshProgress(resItem:GetProgress())
    end
end

function XUiVideoPreloadDownloadTip:OnResDownloadComplete()
    if not self.IsOnCompleteThenEnterFight then
        return
    end

    local isAllComplete = true
    for _, resId in ipairs(self.ResIdList) do
        local resItem = XMVCA.XSubPackage:GetResourceItem(resId)
        if resItem:GetState() ~= XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.COMPLETE then
            isAllComplete = false
            break
        end
    end

    -- 所有的Res下载都完成
    if not isAllComplete then
        return
    end

    self:Close()
    if self.EnterFightCb then
        self.EnterFightCb()
    end
end

function XUiVideoPreloadDownloadTip:OnDestroy()
    XEventManager.RemoveEventListener(XEventId.EVENT_RES_UPDATE, self.OnDownloadProgressUpdate, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_RES_COMPLETE, self.OnResDownloadComplete, self)

    local toggleState = self.BtnSetStateToggle:GetToggleState()
    XMVCA.XSubPackage:SetDefaultSkipVideoPreloadDownloadTip(toggleState)
end