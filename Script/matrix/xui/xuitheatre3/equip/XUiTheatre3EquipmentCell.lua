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
    self.ImgEquipmentBg.gameObject:SetActiveEx(self._EquipConfig.UseType ~= XEnumConst.THEATRE3.SuitUseType.Backend)
    self.ImgEquipmentBg2.gameObject:SetActiveEx(self._EquipConfig.UseType == XEnumConst.THEATRE3.SuitUseType.Backend)
    if self._EquipConfig.UseType ~= XEnumConst.THEATRE3.SuitUseType.Backend then
        self.ImgEquipment1:SetRawImage(self._EquipConfig.Icon)
        if self.ImgEquipment3 then
            self.ImgEquipment3:SetRawImage(self._EquipConfig.Icon)
        end
    else
        self.ImgEquipment2:SetRawImage(self._EquipConfig.Icon)
        if self.ImgEquipment4 then
            self.ImgEquipment4:SetRawImage(self._EquipConfig.Icon)
        end
    end
    if self.ImgEquipmentBg3 then
        self.ImgEquipmentBg3.gameObject:SetActiveEx(self._EquipConfig.UseType ~= XEnumConst.THEATRE3.SuitUseType.Backend)
    end
    if self.ImgEquipmentBg4 then
        self.ImgEquipmentBg4.gameObject:SetActiveEx(self._EquipConfig.UseType == XEnumConst.THEATRE3.SuitUseType.Backend)
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