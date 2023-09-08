local XUiGridEquip = require("XUi/XUiEquip/XUiGridEquipResonanceSelectEquipV2P6")
local TabIndex = {
    Equip = 1,
    Item = 2,
}

local XUiEquipResonanceSelectEquipV2P6 = XLuaUiManager.Register(XLuaUi, "UiEquipResonanceSelectEquipV2P6")

function XUiEquipResonanceSelectEquipV2P6:OnAwake()
    self.GridEquip.gameObject:SetActiveEx(false)
    self:SetButtonCallBack()
    self:InitTabGroup()
    self:InitDynamicTable()
end

function XUiEquipResonanceSelectEquipV2P6:OnStart(equipId, confirmCb)
    self.EquipId = equipId
    self.ConfirmCb = confirmCb
    self.TemplateId = XDataCenter.EquipManager.GetEquipTemplateId(equipId)
    self.IsWeapon = XDataCenter.EquipManager.IsWeaponByTemplateId(self.TemplateId)
    self.SelectEquipId = nil
    self.SelectItemId = nil
end

function XUiEquipResonanceSelectEquipV2P6:OnEnable()
    -- 按钮名称
    local btnName = self.IsWeapon and XUiHelper.GetText("TypeWeapon") or XUiHelper.GetText("TypeWafer")
    self.BtnTabEquip:SetNameByGroup(0, btnName)

    -- 装备列表
    self.EquipIdList = XDataCenter.EquipManager.GetResonanceCanEatEquipIds(self.EquipId)
    XTool.ReverseList(self.EquipIdList) --这个UI要初始升序

    -- 道具列表
    self.ItemIdList = {}
    local consumeItemId = XDataCenter.EquipManager.GetResonanceConsumeItemId(self.EquipId)
    local consumeSelectSkillItemId = XDataCenter.EquipManager.GetResonanceConsumeSelectSkillItemId(self.EquipId)
    if consumeItemId then
        local count = XDataCenter.ItemManager.GetCount(consumeItemId)
        if count > 0 then
            table.insert(self.ItemIdList, consumeItemId)
        end
    end
    if consumeSelectSkillItemId then
        local count = XDataCenter.ItemManager.GetCount(consumeSelectSkillItemId)
        if count > 0 then
            table.insert(self.ItemIdList, consumeSelectSkillItemId)
        end
    end

    self.PanelTabList:SelectIndex(TabIndex.Equip)
end

function XUiEquipResonanceSelectEquipV2P6:SetButtonCallBack()
    self:RegisterClickEvent(self.BtnConfirm, self.OnBtnConfirmClick)
    self:RegisterClickEvent(self.BtnClose, self.OnBtnCloseClick)
    self:RegisterClickEvent(self.Btncancel, self.OnBtnCloseClick)
end

function XUiEquipResonanceSelectEquipV2P6:OnBtnCloseClick()
    self:Close()
end

function XUiEquipResonanceSelectEquipV2P6:OnBtnConfirmClick()
    if self.ConfirmCb and (self.SelectEquipId or self.SelectItemId) then
        self.ConfirmCb(self.SelectEquipId, self.SelectItemId)
    end
    self:Close()
end

function XUiEquipResonanceSelectEquipV2P6:InitTabGroup()
    self.TabGroup = {
        self.BtnTabEquip,
        self.BtnTabItem,
    }

    self.PanelTabList:Init(self.TabGroup, function(tabIndex)
        self:OnClickTab(tabIndex)
    end)
end

function XUiEquipResonanceSelectEquipV2P6:OnClickTab(index)
    if self.CurTabIndex == index then
        return
    end

    self.CurTabIndex = index
    self.SelectEquipId = nil
    self.SelectItemId = nil
    self:UpdateBtnConfirm()
    self:PlayAnimation("QieHuan")

    if index == TabIndex.Equip then
        self:UpdateEquipGridList()
    else
        self:UpdateItemGridList()
    end
end

function XUiEquipResonanceSelectEquipV2P6:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelEquipScroll)
    self.DynamicTable:SetDelegate(self)
    self.DynamicTable:SetProxy(XUiGridEquip, self)
end

function XUiEquipResonanceSelectEquipV2P6:UpdateEquipGridList()
    self.DynamicTable:SetDataSource(self.EquipIdList)
    self.DynamicTable:ReloadDataASync()

    local isEmpty = self.EquipIdList == nil or #self.EquipIdList == 0
    self.PanelEquipScroll.gameObject:SetActiveEx(not isEmpty)
    self.PanelNoEquip.gameObject:SetActive(isEmpty)
    if isEmpty then
        if self.IsWeapon then
            self.TxtNoEquip.text = CS.XTextManager.GetText("EquipResonanceNoWeaponTip")
        else
            self.TxtNoEquip.text = CS.XTextManager.GetText("EquipResonanceNoAwarenessTip")
        end
    end
end

function XUiEquipResonanceSelectEquipV2P6:UpdateItemGridList()
    self.DynamicTable:SetDataSource(self.ItemIdList)
    self.DynamicTable:ReloadDataASync()

    local isEmpty = self.ItemIdList == nil or #self.ItemIdList == 0
    self.PanelEquipScroll.gameObject:SetActiveEx(not isEmpty)
    self.PanelNoEquip.gameObject:SetActive(isEmpty)
    if isEmpty then
        self.TxtNoEquip.text = CS.XTextManager.GetText("EquipResonanceNoItemTip")
    end
end

function XUiEquipResonanceSelectEquipV2P6:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:SetSelected(false)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local id = self.CurTabIndex == TabIndex.Equip and self.EquipIdList[index] or self.ItemIdList[index]
        local isEquip = self.CurTabIndex == TabIndex.Equip
        grid:Refresh(self, id, isEquip)

        local isSelected = self.SelectEquipId == id or self.SelectItemId == id
        if isSelected then
            self.LastSelectGrid = grid
        end
        grid:SetSelected(isSelected)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        if self.LastSelectGrid then
            self.LastSelectGrid:SetSelected(false)
        end

        if self.CurTabIndex == TabIndex.Equip then
            self.SelectEquipId = self.EquipIdList[index]
            self.SelectItemId = nil
        else
            self.SelectItemId = self.ItemIdList[index]
            self.SelectEquipId = nil
        end

        self.LastSelectGrid = grid
        self.LastSelectGrid:SetSelected(true)
        self:UpdateBtnConfirm()
    end
end

function XUiEquipResonanceSelectEquipV2P6:GetGridIdByIndex(index)
    if self.CurTabIndex == TabIndex.Equip then
        local equipId = self.EquipIdList[index]
        return equipId
    else
        local itemId = self.ItemIdList[index]
        return itemId
    end
end

-- 刷新确定按钮
function XUiEquipResonanceSelectEquipV2P6:UpdateBtnConfirm()
    local isSelect = self.SelectEquipId or self.SelectItemId
    self.BtnConfirm:SetDisable(not isSelect)
end

return XUiEquipResonanceSelectEquipV2P6
