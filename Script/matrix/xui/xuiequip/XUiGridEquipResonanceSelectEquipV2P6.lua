local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiGridEquipResonanceSelectEquipV2P6 = XClass(XUiNode, "XUiGridEquipResonanceSelectEquipV2P6")

function XUiGridEquipResonanceSelectEquipV2P6:OnStart()
    self:SetSelected(false)
end

-- 刷新格子
function XUiGridEquipResonanceSelectEquipV2P6:Refresh(data, isEquip)
    if isEquip then
        self:RefreshEquip(data)
    else
        self:RefreshItem(data)
    end
end

-- 刷新装备
function XUiGridEquipResonanceSelectEquipV2P6:RefreshEquip(id)
    if not self.UiGridEquip then
        local XUiGridEquip = require("XUi/XUiEquip/XUiGridEquip")
        self.UiGridEquip = XUiGridEquip.New(self.GameObject, self.Parent)
    end
    self.UiGridEquip:Refresh(id)
    self.LvText.text = XUiHelper.GetText("EquipLevel")
    self.LvText.gameObject:SetActiveEx(true)
end

-- 刷新道具
function XUiGridEquipResonanceSelectEquipV2P6:RefreshItem(data)
    if not self.UiGridCommon then
        self.LeftUp.gameObject:SetActiveEx(false)
        self.PanelResonance.gameObject:SetActiveEx(false)
        self.UiGridCommon = XUiGridCommon.New(self.Parent, self.Grid256)
    end
    self.UiGridCommon:Refresh(data.TemplateId)

    local ownCnt = XDataCenter.ItemManager.GetCount(data.TemplateId)
    if data.CostCnt == 1 then
        self.LvText.text = XUiHelper.GetText("ItemOwn")
        self.LvText.gameObject:SetActiveEx(true)
        self.TxtLevel.text = tostring(ownCnt)
    else
        self.LvText.gameObject:SetActiveEx(false)
        if ownCnt >= data.CostCnt then
            self.TxtLevel.text = XUiHelper.GetText("ResonanceTokenCost", ownCnt, data.CostCnt)
        else
            self.TxtLevel.text = XUiHelper.GetText("ResonanceTokenCostNoEnough", ownCnt, data.CostCnt)
        end
    end
end

-- 设置选中状态
function XUiGridEquipResonanceSelectEquipV2P6:SetSelected(isSelected)
    self.ImgSelect.gameObject:SetActiveEx(isSelected)
end

return XUiGridEquipResonanceSelectEquipV2P6
