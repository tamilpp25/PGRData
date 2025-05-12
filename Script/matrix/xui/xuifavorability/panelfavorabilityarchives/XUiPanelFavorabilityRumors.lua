local XDynamicTableIrregular = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableIrregular")
local XUiGridLikeRumorItem=require("XUi/XUiFavorability/PanelFavorabilityArchives/XUiGridLikeRumorItem")
local XUiPanelFavorabilityRumors = XClass(XUiNode, "XUiPanelFavorabilityRumors")
local loadGridComplete

function XUiPanelFavorabilityRumors:OnStart(uiRoot)
    self.UiRoot = uiRoot
    self.GridLikeRumorItem.gameObject:SetActiveEx(false)
    self.PanelEmpty.gameObject:SetActiveEx(false)
end

function XUiPanelFavorabilityRumors:OnEnable()
    self:RefreshDatas()
end

function XUiPanelFavorabilityRumors:OnDisable()
    self.DynamicTableRumors:RecycleAllTableGrid()
    loadGridComplete=false
end

function XUiPanelFavorabilityRumors:RefreshDatas()
    local characterId = self.UiRoot:GetCurrFavorabilityCharacter()
    local rumors = self._Control:GetCharacterRumorsById(characterId)
    local rumorsPriority=self._Control:GetCharacterRumorsPriority()
    self.Toggle = {}
    self:UpdateRumorsList(rumors,rumorsPriority)
end

function XUiPanelFavorabilityRumors:InitDynamicTable()
    self.DynamicTableRumors = XDynamicTableIrregular.New(self.PanelRumorsList)
    self.DynamicTableRumors:SetProxy("XUiGridLikeRumorItem", XUiGridLikeRumorItem, self.GridLikeRumorItem.gameObject,self.UiRoot)
    self.DynamicTableRumors:SetDelegate(self)
end

function XUiPanelFavorabilityRumors:GetProxyType()
    return "XUiGridLikeRumorItem"
end

function XUiPanelFavorabilityRumors:UpdateRumorsList(rumors,rumorsPriority)
    if not rumors then
        self.PanelEmpty.gameObject:SetActiveEx(true)
        self.TxtNoDataTip.text = CS.XTextManager.GetText("FavorabilityNoStrangeNewsData")
        self.Rumors = {}
    else
        self.PanelEmpty.gameObject:SetActiveEx(false)
        self:SortRumors(rumors,rumorsPriority)
        self.Rumors = rumors
    end

    if not self.DynamicTableRumors then
        self:InitDynamicTable()
    end
    self.DynamicTableRumors:SetDataSource(self.Rumors)
    self.DynamicTableRumors:ReloadDataASync(1)

end

function XUiPanelFavorabilityRumors:SortRumors(rumors,rumorsPriority)
    -- 已解锁，可解锁，未解锁
    local characterId = self.UiRoot:GetCurrFavorabilityCharacter()
    for _, rumor in pairs(rumors) do
        local isUnlock = XMVCA.XFavorability:IsRumorUnlock(characterId, rumor.Id)
        local canUnlock = XMVCA.XFavorability:CanRumorsUnlock(characterId, rumor.UnlockType, rumor.UnlockPara)
        rumorsPriority[rumor.Id] = 2
        if not isUnlock then
            rumorsPriority[rumor.Id] = canUnlock and 1 or 3
        end
    end

    table.sort(rumors, function(rumorA, rumorB)
        if rumorsPriority[rumorA.Id] == rumorsPriority[rumorB.Id] then
            return rumorA.Id < rumorB.Id
        else
            return rumorsPriority[rumorA.Id] < rumorsPriority[rumorB.Id]
        end
    end)
end

-- [监听动态列表事件]
function XUiPanelFavorabilityRumors:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then

    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Open()
        local data = self.Rumors[index]
        if data ~= nil then
            grid:OnRefresh(self.Rumors[index], self.Toggle[data.Id])
        end

    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self.CurRumor = self.Rumors[index]
        if not self.CurRumor then return end
        self:OnRumorClick(index, grid)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        loadGridComplete=true
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RECYCLE then
        grid:Close()    
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
    local isUnlock = XMVCA.XFavorability:IsRumorUnlock(characterId, self.CurRumor.Id)
    local canUnlock = XMVCA.XFavorability:CanRumorsUnlock(characterId, self.CurRumor.UnlockType, self.CurRumor.UnlockPara)

    if isUnlock then
        self.Toggle[self.CurRumor.Id] = self.Toggle[self.CurRumor.Id] or false
        self.Toggle[self.CurRumor.Id] = not self.Toggle[self.CurRumor.Id]
        self.DynamicTableRumors:ReloadDataASync()
    elseif canUnlock then
        grid:HideRedDot()
        XMVCA.XFavorability:OnUnlockCharacterRumor(characterId, self.CurRumor.Id,true)
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
    if isActive then
        self:Open()
    else
        self:Close()
    end
end

function XUiPanelFavorabilityRumors:OnSelected(isSelected)
    if isSelected then
        self:Open()
    else
        self:Close()
    end
end



return XUiPanelFavorabilityRumors