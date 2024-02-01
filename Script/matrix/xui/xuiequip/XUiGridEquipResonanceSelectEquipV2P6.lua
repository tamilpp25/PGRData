local XUiGridEquip = require("XUi/XUiEquip/XUiGridEquip")

local XUiGridEquipResonanceSelectEquipV2P6 = XClass(nil, "XUiGridEquipResonanceSelectEquipV2P6")

function XUiGridEquipResonanceSelectEquipV2P6:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

function XUiGridEquipResonanceSelectEquipV2P6:Refresh(parent, id, isEquip)
    self.Parent = parent
    self.Id = id
    self.IsEquip = isEquip

    if isEquip then
        if not self.UiGridEquip then
            self.UiGridEquip = XUiGridEquip.New(self.GameObject, self.Parent)
        end
        self.UiGridEquip:Refresh(self.Id)
        self.LvText.text = XUiHelper.GetText("EquipLevel")
    else
        if not self.UiGridCommon then
            self.UiGridCommon = XUiGridCommon.New(self.Parent, self.Grid256)
        end
        local itemInfo = {}
        itemInfo.TemplateId = self.Id
        itemInfo.Count = XDataCenter.ItemManager.GetCount(self.Id)
        self.UiGridCommon:Refresh(itemInfo)

        self.LeftUp.gameObject:SetActiveEx(false)
        self.PanelResonance.gameObject:SetActiveEx(false)
        self.LvText.text = XUiHelper.GetText("ItemOwn")
        self.TxtLevel.text = tostring(itemInfo.Count)
    end
end

function XUiGridEquipResonanceSelectEquipV2P6:SetSelected(isSelected)
    self.ImgSelect.gameObject:SetActiveEx(isSelected)
end

return XUiGridEquipResonanceSelectEquipV2P6
