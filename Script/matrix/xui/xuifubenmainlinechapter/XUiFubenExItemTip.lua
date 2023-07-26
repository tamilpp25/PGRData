local XUiFubenExItemTip = XLuaUiManager.Register(XLuaUi, "UiFubenExItemTip")

function XUiFubenExItemTip:OnStart(base)
    self.Base = base
    self:SetButtonCallBack()
    self:InitDynamicTable()
    self:SetItemCount()
end

function XUiFubenExItemTip:OnEnable()
    self:SetupDynamicTable()
end

function XUiFubenExItemTip:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelItemList)
    self.DynamicTable:SetProxy(XUiGridExploreItem)
    self.DynamicTable:SetDelegate(self)
    self.PanelItemPortrait.gameObject:SetActiveEx(false)
end

function XUiFubenExItemTip:SetupDynamicTable()
    self.PageDatas = XDataCenter.FubenMainLineManager.GetChapterExploreItemList(self.Base.MainChapterId)
    self.DynamicTable:SetDataSource(self.PageDatas)
    self.DynamicTable:ReloadDataSync(1)
end

function XUiFubenExItemTip:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:UpdateGrid(self.PageDatas[index], self, index)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:UpdateGrid(self.PageDatas[index], self)
    end
end

function XUiFubenExItemTip:SetButtonCallBack()
    self.BtnClose.CallBack = function()
        self:OnBtCloseClick()
    end
end

function XUiFubenExItemTip:SetItemData(itemId)
    local info = XFubenMainLineConfigs.GetExploreItemCfgById(itemId)
    if (info ~= nil) then
        self.RImgPlayerIcon:SetRawImage(info.Icon)
        self.TxtHeadName.text = info.Name
        self.TxtDesc.text = info.Desc
        self.TxtCondition.text = info.Hint
        self.SelectCharacterId = itemId
    end
end

function XUiFubenExItemTip:SetItemCount()
    local itemMaxCount = XDataCenter.FubenMainLineManager.GetChapterExploreItemMaxCount(self.Base.MainChapterId)
    local itemCurCount = #XDataCenter.FubenMainLineManager.GetChapterExploreItemList(self.Base.MainChapterId)
    self.TextNum.text = string.format("%d/%d", itemCurCount, itemMaxCount)
end

function XUiFubenExItemTip:OnBtCloseClick()
    self:Close()
end