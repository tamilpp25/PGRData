---@class XUiTheatre3EquipmentCell : XUiNode 装备
---@field Parent XUiTheatre3EquipmentChoose
---@field _Control XTheatre3Control
local XUiTheatre3EquipmentCell = XClass(XUiNode, "XUiTheatre3EquipmentCell")

function XUiTheatre3EquipmentCell:OnStart(id)
    if id then
        self:ShowEquip(id)
    end
    -- 默认隐藏
    self.EquipmentGrid:ShowReddot(false)
end

function XUiTheatre3EquipmentCell:ShowEquip(id)
    self._EquipConfig = self._Control:GetEquipById(id)
    self.TxtNum.text = XTool.ConvertRomanNumberString(self._EquipConfig.PosType)
    self.ImgEquipmentBg.gameObject:SetActiveEx(self._EquipConfig.UseType == 1)
    self.ImgEquipmentBg2.gameObject:SetActiveEx(self._EquipConfig.UseType == 2)
    if self._EquipConfig.UseType == 1 then
        self.ImgEquipment1:SetRawImage(self._EquipConfig.Icon)
    else
        self.ImgEquipment2:SetRawImage(self._EquipConfig.Icon)
    end
end

function XUiTheatre3EquipmentCell:AddClick(handle)
    self.EquipmentGrid.CallBack = handle
end

function XUiTheatre3EquipmentCell:SetState(isDisabled)
    self.EquipmentGrid:SetButtonState(isDisabled and CS.UiButtonState.Disable or CS.UiButtonState.Normal)
end

function XUiTheatre3EquipmentCell:RefreshRedPoint(isRedPoint)
    self.EquipmentGrid:ShowReddot(isRedPoint)
end

return XUiTheatre3EquipmentCell