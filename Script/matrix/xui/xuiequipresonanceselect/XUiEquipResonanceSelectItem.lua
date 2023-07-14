local XUiEquipResonanceSelectItem = XLuaUiManager.Register(XLuaUi, "UiEquipResonanceSelectItem")

local ITEM_TYPE = {
    DEFAULT = 1,
    SELECT = 2
}

function XUiEquipResonanceSelectItem:OnAwake()
    self:AutoAddListener()
end

function XUiEquipResonanceSelectItem:OnStart(equipId, confirmCb)
    self.EquipId = equipId
    self.ConfirmCb = confirmCb

    self:InitDynamicTable()
end

function XUiEquipResonanceSelectItem:OnEnable(equipId)
    self.EquipId = equipId or self.EquipId
    self:Update()
end

--@region 绑定事件

function XUiEquipResonanceSelectItem:AutoAddListener()
    self:RegisterClickEvent(self.BtnConfirm, self.OnBtnConfirmClick)
    self:RegisterClickEvent(self.BtnClose, self.OnBtnCloseClick)
    self:RegisterClickEvent(self.Btncancel, self.OnBtnCloseClick)
end

function XUiEquipResonanceSelectItem:OnBtnCloseClick()
    self:Close()
end

function XUiEquipResonanceSelectItem:OnBtnConfirmClick()
    if self.ConfirmCb then
        self.ConfirmCb(self.SelectItemId)
    end
    self.SelectItemId = nil
    self:Close()
end

--@endregion

function XUiEquipResonanceSelectItem:InitDynamicTable()
    self.DynamicTableA = XDynamicTableNormal.New(self.PanelScrollA)
    self.DynamicTableA:SetDelegate(self)
    self.DynamicTableA:SetProxy(XUiGridCommon)
    self.DynamicTableA:SetDynamicEventDelegate(function (event, index, grid)
        self:OnDynamicTableEvent(event, index, grid, ITEM_TYPE.DEFAULT)
    end)

    self.DynamicTableB = XDynamicTableNormal.New(self.PanelScrollB)
    self.DynamicTableB:SetDelegate(self)
    self.DynamicTableB:SetProxy(XUiGridCommon)
    self.DynamicTableB:SetDynamicEventDelegate(function (event, index, grid)
        self:OnDynamicTableEvent(event, index, grid, ITEM_TYPE.SELECT)
    end)
end

function XUiEquipResonanceSelectItem:Update()
    local templateId = XDataCenter.EquipManager.GetEquipTemplateId(self.EquipId)
    local quality = XDataCenter.EquipManager.GetEquipQuality(templateId)

    self.TextTitle1.text = CS.XTextManager.GetText("EquipResonanceSelectItemTitle", quality)
    self.TextTitleShadow1.text = CS.XTextManager.GetText("EquipResonanceSelectItemTitle", quality)

    self.BtnConfirm:SetDisable(self.SelectItemId == nil, false)
    self:UpdateEquipGridList()
end

function XUiEquipResonanceSelectItem:UpdateEquipGridList()
    local consumeItemId = XDataCenter.EquipManager.GetResonanceConsumeItemId(self.EquipId)
    local consumeSelectSkillItemId = XDataCenter.EquipManager.GetResonanceConsumeSelectSkillItemId(self.EquipId)

    self.ListA = {consumeItemId}
    self.ListB = {consumeSelectSkillItemId}

    if consumeItemId then
        self.DynamicTableA:SetDataSource(self.ListA)
        self.DynamicTableA:ReloadDataSync()
        self.PanelScrollA.gameObject:SetActiveEx(true)
    else
        self.PanelScrollA.gameObject:SetActiveEx(false)
    end

    if consumeSelectSkillItemId then
        self.DynamicTableB:SetDataSource(self.ListB)
        self.DynamicTableB:ReloadDataSync()
        self.PanelScrollB.gameObject:SetActiveEx(true)
    else
        self.PanelScrollB.gameObject:SetActiveEx(false)
    end
end

function XUiEquipResonanceSelectItem:OnDynamicTableEvent(event, index, grid, type)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local itemId = self:GetListByType(type)[index]
        if not itemId then
            return
        end
        local haveCount = XDataCenter.ItemManager.GetCount(itemId)

        grid:Refresh(itemId)
        grid.ImgSelect.gameObject:SetActiveEx(self.SelectItemId == itemId)
        grid.TxtCount.text = CS.XTextManager.GetText("ShopGridCommonCount", haveCount)
        grid.TxtCount.gameObject:SetActiveEx(true)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        local itemId = self:GetListByType(type)[index]
        if self:IsEnough(itemId, type) then
            self.SelectItemId = itemId
            self:Update()
        else
            XUiManager.TipMsg(CS.XTextManager.GetText("EquipResonanceNoEnough"))
            return
        end
    end
end

function XUiEquipResonanceSelectItem:GetListByType(type)
    if type == ITEM_TYPE.DEFAULT then
        return self.ListA
    elseif type == ITEM_TYPE.SELECT then
        return self.ListB
    end
end

function XUiEquipResonanceSelectItem:IsEnough(itemId, type)
    local haveCount = XDataCenter.ItemManager.GetCount(itemId)

    if type == ITEM_TYPE.DEFAULT then
        return haveCount >= XDataCenter.EquipManager.GetResonanceConsumeItemCount(self.EquipId)
    elseif type == ITEM_TYPE.SELECT then
        return haveCount >= XDataCenter.EquipManager.GetResonanceConsumeSelectSkillItemCount(self.EquipId)
    end
end