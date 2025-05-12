---@class XUiTheatre3GridFightEquip : XUiNode
---@field _Control XTheatre3Control
---@field Parent XUiTheatre3PanelEquipFightResult
local XUiTheatre3GridFightEquip = XClass(XUiNode, "XUiTheatre3GridFightEquip")

function XUiTheatre3GridFightEquip:Refresh(slotId, equipSuitId)
    self.SlotId = slotId == nil and self._Control:GetSuitBelong(equipSuitId) or slotId
    self.SuitConfig = self._Control:GetSuitById(equipSuitId)
    self.TxtName.text = self.SuitConfig.SuitName
    self.RImgSet:SetRawImage(self.SuitConfig.Icon)
    self.ImgType1.gameObject:SetActiveEx(self.SuitConfig.UseType ~= XEnumConst.THEATRE3.SuitUseType.Backend)
    self.ImgType2.gameObject:SetActiveEx(self.SuitConfig.UseType == XEnumConst.THEATRE3.SuitUseType.Backend)
    self:ShowSuitAllPos()
end

function XUiTheatre3GridFightEquip:ShowSuitAllPos()
    if not self.SuitConfig then
        return
    end
    local equips = self._Control:GetAllSuitEquip(self.SuitConfig.Id)
    local poolName = "Theatre3Suit" .. self.Transform:GetInstanceID()
    ---@param data XTableTheatre3Equip
    self.Parent.Parent:RefreshTemplateGrids(self.GridNumber, equips, self.GridNumber.parent, nil, poolName, function(grid, data)
        grid.BgType1.gameObject:SetActiveEx(data.UseType == 1)
        grid.BgType2.gameObject:SetActiveEx(data.UseType == 2)
        grid.TxtNum.text = XTool.ConvertRomanNumberString(data.PosType)
        grid.BgDisable.gameObject:SetActiveEx(not self._Control:IsWearEquip(data.Id))
    end)
end

return XUiTheatre3GridFightEquip