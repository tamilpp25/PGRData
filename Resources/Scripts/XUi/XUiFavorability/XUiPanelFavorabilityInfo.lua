XUiPanelFavorabilityInfo = XClass(nil, "XUiPanelFavorabilityInfo")

function XUiPanelFavorabilityInfo:Ctor(ui, uiRoot, parent)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.UiRoot = uiRoot
    self.Parent = parent
    XTool.InitUiObject(self)
    self.GridLikeInfoItem.gameObject:SetActiveEx(false)
    self.PanelEmpty.gameObject:SetActiveEx(false)
end

function XUiPanelFavorabilityInfo:OnRefresh()
    -- 动画加这里
    self:RefreshDatas()
end

function XUiPanelFavorabilityInfo:RefreshDatas()
    local characterId = self.UiRoot:GetCurrFavorabilityCharacter()
    local informations = XFavorabilityConfigs.GetCharacterInformationById(characterId)

    if not self.Toggle then
        local toggle = {}

        self.Toggle = toggle

    end

    self:UpdateDataList(informations)
end

function XUiPanelFavorabilityInfo:GetProxyType()
    return "XUiGridLikeInfoItem"
end

function XUiPanelFavorabilityInfo:UpdateDataList(dataList)
    if not dataList or next(dataList) == nil then
        self.PanelEmpty.gameObject:SetActiveEx(true)
        self.TxtNoDataTip.text = CS.XTextManager.GetText("FavorabilityNoInfoData")
        self.DataList = {}
    else
        self.PanelEmpty.gameObject:SetActiveEx(false)
        self:SortInformation(dataList)
        self.DataList = dataList
    end



    if not self.DynamicTableData then
        self.DynamicTableData = XDynamicTableIrregular.New(self.PanelDataList)
        self.DynamicTableData:SetProxy("XUiGridLikeInfoItem", XUiGridLikeInfoItem, self.GridLikeInfoItem.gameObject)
        self.DynamicTableData:SetDelegate(self)
    end

    self.DynamicTableData:SetDataSource(self.DataList)
    self.DynamicTableData:ReloadDataASync()

end

function XUiPanelFavorabilityInfo:SortInformation(dataList)
    local characterId = self.UiRoot:GetCurrFavorabilityCharacter()
    for _, dataItem in pairs(dataList) do
        local isUnlock = XDataCenter.FavorabilityManager.IsInformationUnlock(characterId, dataItem.Id)
        local canUnlock = XDataCenter.FavorabilityManager.CanInformationUnlock(characterId, dataItem.Id)
        dataItem.priority = 2
        if not isUnlock then
            dataItem.priority = canUnlock and 1 or 3
        end
    end
    table.sort(dataList, function(dataItemA, dataItemB)
        if dataItemA.priority == dataItemB.priority then
            return dataItemA.Id < dataItemB.Id
        else
            return dataItemA.priority < dataItemB.priority
        end
    end)
end

-- [监听动态列表事件]
function XUiPanelFavorabilityInfo:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self.UiRoot)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.DataList[index]
        if data ~= nil then
            grid:OnRefresh(self.DataList[index], self.Toggle[data.Id])
        end

    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self.CurData = self.DataList[index]
        self:OnDataClick(index, grid)
    end
end

-- [点击资料]
function XUiPanelFavorabilityInfo:OnDataClick(index, grid)
    if not self.CurData then return end
    local characterId = self.UiRoot:GetCurrFavorabilityCharacter()
    local isUnlock = XDataCenter.FavorabilityManager.IsInformationUnlock(characterId, self.CurData.Id)
    local canUnlock = XDataCenter.FavorabilityManager.CanInformationUnlock(characterId, self.CurData.Id)
    if isUnlock then
        self.Toggle[self.CurData.Id] = self.Toggle[self.CurData.Id] or false
        self.Toggle[self.CurData.Id] = not self.Toggle[self.CurData.Id]
        self.DynamicTableData:ReloadDataASync()
    elseif canUnlock then
        XDataCenter.FavorabilityManager.OnUnlockCharacterInfomatin(characterId, self.CurData.Id)
        XEventManager.DispatchEvent(XEventId.EVENT_FAVORABILITY_INFOUNLOCK)
        grid:HideRedDot()
        self.Toggle[self.CurData.Id] = not self.Toggle[self.CurData.Id] or false
        self.Toggle[self.CurData.Id] = self.Toggle[self.CurData.Id]
        self.DynamicTableData:ReloadDataASync()
    else
        -- 提示解锁条件
        XUiManager.TipMsg(self.CurData.ConditionDescript)
    end
end

function XUiPanelFavorabilityInfo:SetViewActive(isActive)

    self.Toggle = {}

    self.GameObject:SetActive(isActive)
    if isActive then
        self:RefreshDatas()
    end
end

function XUiPanelFavorabilityInfo:OnSelected(isSelected)
    self.GameObject:SetActive(isSelected)
    if isSelected then
        self:RefreshDatas()
    end
end



return XUiPanelFavorabilityInfo