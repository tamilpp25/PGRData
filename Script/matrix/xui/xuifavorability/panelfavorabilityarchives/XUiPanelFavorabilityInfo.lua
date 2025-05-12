local XDynamicTableIrregular = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableIrregular")
local XUiGridLikeInfoItem=require("XUi/XUiFavorability/PanelFavorabilityArchives/XUiGridLikeInfoItem")
local XUiPanelFavorabilityInfo = XClass(XUiNode, "XUiPanelFavorabilityInfo")
local loadGridComplete

function XUiPanelFavorabilityInfo:OnStart(uiRoot)
    self.UiRoot = uiRoot
    self.GridLikeInfoItem.gameObject:SetActiveEx(false)
    self.PanelEmpty.gameObject:SetActiveEx(false)
    self.Content=self.PanelInfoList.transform:Find('Viewport/Content'):GetComponent('RectTransform')

end

function XUiPanelFavorabilityInfo:OnEnable()
    self:RefreshDatas()
end

function XUiPanelFavorabilityInfo:OnDisable()
    self.DynamicTableData:RecycleAllTableGrid()
    loadGridComplete=false
end

function XUiPanelFavorabilityInfo:RefreshDatas()
    local characterId = self.UiRoot:GetCurrFavorabilityCharacter()
    local informations = self._Control:GetCharacterInformationById(characterId)

    self.Toggle = {}

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
        self.DynamicTableData = XDynamicTableIrregular.New(self.PanelInfoList)
        self.DynamicTableData:SetProxy("XUiGridLikeInfoItem", XUiGridLikeInfoItem, self.GridLikeInfoItem.gameObject,self.UiRoot)
        self.DynamicTableData:SetDelegate(self)
    end

    self.DynamicTableData:SetDataSource(self.DataList)
    self.DynamicTableData:ReloadDataASync()

end

function XUiPanelFavorabilityInfo:SortInformation(dataList)
    local characterId = self.UiRoot:GetCurrFavorabilityCharacter()
    for _, dataItem in pairs(dataList) do
        local isUnlock = self._Control:IsInformationUnlock(characterId, dataItem.Id)
        local canUnlock = self._Control:CanInformationUnlock(characterId, dataItem.Id)
        dataItem.priority = 2
        if not isUnlock then
            dataItem.priority = canUnlock and 1 or 3
        end
    end
    table.sort(dataList, function(dataItemA, dataItemB)
        if dataItemA.priority == dataItemB.priority then
            return dataItemA.config.Id < dataItemB.config.Id
        else
            return dataItemA.priority < dataItemB.priority
        end
    end)
end

-- [监听动态列表事件]
function XUiPanelFavorabilityInfo:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then

    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.DataList[index]
        if data ~= nil then
            grid:OnRefresh(self.DataList[index], self.Toggle[data.config.Id])
        end

    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self.CurData = self.DataList[index]
        self:OnDataClick(index, grid)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        if not loadGridComplete then
            if self.Content then
                self.Content.anchoredPosition=Vector2(self.Content.anchoredPosition.x,0)
            end
        end
        loadGridComplete=true
    end
end

-- [点击资料]
function XUiPanelFavorabilityInfo:OnDataClick(index, grid)
    if not self.CurData then return end
    local characterId = self.UiRoot:GetCurrFavorabilityCharacter()
    local isUnlock = self._Control:IsInformationUnlock(characterId, self.CurData.config.Id)
    local canUnlock = self._Control:CanInformationUnlock(characterId, self.CurData.config.Id)
    if isUnlock then
        self.Toggle[self.CurData.config.Id] = self.Toggle[self.CurData.config.Id] or false
        self.Toggle[self.CurData.config.Id] = not self.Toggle[self.CurData.config.Id]
        self.DynamicTableData:ReloadDataASync()
    elseif canUnlock then
        XMVCA.XFavorability:OnUnlockCharacterInfomatin(characterId, self.CurData.config.Id,true)
        XEventManager.DispatchEvent(XEventId.EVENT_FAVORABILITY_INFOUNLOCK)
        grid:HideRedDot()
        self.Toggle[self.CurData.config.Id] = not self.Toggle[self.CurData.config.Id] or false
        self.Toggle[self.CurData.config.Id] = self.Toggle[self.CurData.config.Id]
        self.DynamicTableData:ReloadDataASync()
    else
        -- 提示解锁条件
        XUiManager.TipMsg(self.CurData.config.ConditionDescript)
    end
end

function XUiPanelFavorabilityInfo:SetViewActive(isActive)

    self.Toggle = {}

    if isActive then
        self:Open()
    else
        self:Close()
    end
end

function XUiPanelFavorabilityInfo:OnSelected(isSelected)
    if isSelected then
        self:Open()
    else
        self:Close()
    end
end



return XUiPanelFavorabilityInfo