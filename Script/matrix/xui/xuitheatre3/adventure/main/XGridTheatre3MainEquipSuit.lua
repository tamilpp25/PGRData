---@class XGridTheatre3MainEquipSuit : XUiNode
---@field _Control XTheatre3Control
local XGridTheatre3MainEquipSuit = XClass(XUiNode, "XGridTheatre3MainEquipSuit")

function XGridTheatre3MainEquipSuit:OnStart()
    self:InitEquipSuit()
end

function XGridTheatre3MainEquipSuit:Refresh(suitId)
    local suitCfg = self._Control:GetSuitById(suitId)
    local equipCfgList = self._Control:GetAllSuitEquip(suitId)
    self.TxtTitle.text = suitCfg.SuitName
    if equipCfgList[1] and not string.IsNilOrEmpty(equipCfgList[1].Icon) then
        self.PanelSetCover:SetRawImage(equipCfgList[1].Icon)
    elseif not string.IsNilOrEmpty(suitCfg.Icon) then
        self.PanelSetCover:SetRawImage(suitCfg.Icon)
    end
    if self.ImgEquipmentBg and self.ImgEquipmentBg.sprite then
        local icon = self._Control:GetClientConfig("EquipUseTypeIcon", suitCfg.UseType)
        if not string.IsNilOrEmpty(icon) then
            self.ImgEquipmentBg:SetSprite(icon)
        end
    end

    for i, SuitEquip in ipairs(self._SuitEquipList) do
        if equipCfgList[i] then
            local isWearEquip = self._Control:IsWearEquip(equipCfgList[i].Id)
            SuitEquip.Transform.gameObject:SetActiveEx(true)
            SuitEquip.Lock.gameObject:SetActiveEx(not isWearEquip)
            SuitEquip.UnLock.gameObject:SetActiveEx(isWearEquip)
        else
            SuitEquip.Transform.gameObject:SetActiveEx(false)
        end
    end
end

function XGridTheatre3MainEquipSuit:InitEquipSuit()
    self._SuitEquipList = { {}, {}, {}, }
    XTool.InitUiObjectByUi(self._SuitEquipList[1], self.UiEquipment1)
    XTool.InitUiObjectByUi(self._SuitEquipList[2], self.UiEquipment2)
    XTool.InitUiObjectByUi(self._SuitEquipList[3], self.UiEquipment3)
end

return XGridTheatre3MainEquipSuit