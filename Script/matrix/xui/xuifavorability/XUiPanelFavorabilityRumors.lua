XUiPanelFavorabilityRumors = XClass(nil, "XUiPanelFavorabilityRumors")

function XUiPanelFavorabilityRumors:Ctor(ui, uiRoot, parent)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.UiRoot = uiRoot
    self.Parent = parent

    XTool.InitUiObject(self)
    self.GridLikeRumorItem.gameObject:SetActiveEx(false)
    self.PanelEmpty.gameObject:SetActiveEx(false)
end

function XUiPanelFavorabilityRumors:OnRefresh()
    self:RefreshDatas()
end

function XUiPanelFavorabilityRumors:RefreshDatas()
    local characterId = self.UiRoot:GetCurrFavorabilityCharacter()
    local rumors = XFavorabilityConfigs.GetCharacterRumorsById(characterId)

    if not self.Toggle then
        self.Toggle = {}
    end
    self:UpdateRumorsList(rumors)
end

function XUiPanelFavorabilityRumors:InitDynamicTable()
    self.DynamicTableRumors = XDynamicTableIrregular.New(self.PanelRumorsList)
    self.DynamicTableRumors:SetProxy("XUiGridLikeRumorItem", XUiGridLikeRumorItem, self.GridLikeRumorItem.gameObject)
    self.DynamicTableRumors:SetDelegate(self)
end

function XUiPanelFavorabilityRumors:GetProxyType()
    return "XUiGridLikeRumorItem"
end

function XUiPanelFavorabilityRumors:UpdateRumorsList(rumors)
    if not rumors then
        self.PanelEmpty.gameObject:SetActiveEx(true)
        self.TxtNoDataTip.text = CS.XTextManager.GetText("FavorabilityNoStrangeNewsData")
        self.Rumors = {}
    else
        self.PanelEmpty.gameObject:SetActiveEx(false)
        self:SortRumors(rumors)
        self.Rumors = rumors
    end

    if not self.DynamicTableRumors then
        self:InitDynamicTable()
    end
    self.DynamicTableRumors:SetDataSource(self.Rumors)
    self.DynamicTableRumors:ReloadDataASync()

end

function XUiPanelFavorabilityRumors:SortRumors(rumors)
    -- 已解锁，可解锁，未解锁
    local characterId = self.UiRoot:GetCurrFavorabilityCharacter()
    for _, rumor in pairs(rumors) do
        local isUnlock = XDataCenter.FavorabilityManager.IsRumorUnlock(characterId, rumor.Id)
        local canUnlock = XDataCenter.FavorabilityManager.CanRumorsUnlock(characterId, rumor.UnlockType, rumor.UnlockPara)
        rumor.priority = 2
        if not isUnlock then
            rumor.priority = canUnlock and 1 or 3
        end
    end
    table.sort(rumors, function(rumorA, rumorB)
        if rumorA.priority == rumorB.priority then
            return rumorA.Id < rumorB.Id
        else
            return rumorA.priority < rumorB.priority
        end
    end)
end

-- [监听动态列表事件]
function XUiPanelFavorabilityRumors:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self.UiRoot)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.Rumors[index]
        if data ~= nil then
            grid:OnRefresh(self.Rumors[index], self.Toggle[data.Id])
        end

    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self.CurRumor = self.Rumors[index]
        if not self.CurRumor then return end
        self:OnRumorClick(index, grid)
    end
end

function XUiPanelFavorabilityRumors:ResetOtherItems(index)
    for k, v in pairs(self.Rumors) do
        if index ~= k then
            v.IsToggle = false
        end
    end
end

-- [处理点击事件]
function XUiPanelFavorabilityRumors:OnRumorClick(index, grid)
    local characterId = self.UiRoot:GetCurrFavorabilityCharacter()
    local isUnlock = XDataCenter.FavorabilityManager.IsRumorUnlock(characterId, self.CurRumor.Id)
    local canUnlock = XDataCenter.FavorabilityManager.CanRumorsUnlock(characterId, self.CurRumor.UnlockType, self.CurRumor.UnlockPara)

    if isUnlock then
        self.Toggle[self.CurRumor.Id] = self.Toggle[self.CurRumor.Id] or false
        self.Toggle[self.CurRumor.Id] = not self.Toggle[self.CurRumor.Id]
        self.DynamicTableRumors:ReloadDataASync()
    elseif canUnlock then
        grid:HideRedDot()
        XDataCenter.FavorabilityManager.OnUnlockCharacterRumor(characterId, self.CurRumor.Id)
        XEventManager.DispatchEvent(XEventId.EVENT_FAVORABILITY_RUMERUNLOCK)

        self.Toggle[self.CurRumor.Id] = self.Toggle[self.CurRumor.Id] or false
        self.Toggle[self.CurRumor.Id] = not self.Toggle[self.CurRumor.Id]
        self.DynamicTableRumors:ReloadDataASync()
    else
        XUiManager.TipMsg(self.CurRumor.ConditionDescript)
    end
end

function XUiPanelFavorabilityRumors:SetViewActive(isActive)
    self.Toggle = {}
    self.GameObject:SetActive(isActive)
    if isActive then
        self:RefreshDatas()
    end
end

function XUiPanelFavorabilityRumors:OnSelected(isSelected)
    self.GameObject:SetActive(isSelected)
    if isSelected then
        self:RefreshDatas()
    end
end



return XUiPanelFavorabilityRumors