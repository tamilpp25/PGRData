local XUiTheatre3EquipmentCell = require("XUi/XUiTheatre3/Equip/XUiTheatre3EquipmentCell")

---@class XUiTheatre3EquipmentDesc : XUiNode 装备描述
---@field Parent XUiTheatre3EquipmentChoose
---@field _Control XTheatre3Control
local XUiTheatre3EquipmentDesc = XClass(XUiNode, "XUiTheatre3EquipmentDesc")

function XUiTheatre3EquipmentDesc:OnStart()

end

---@param equipConfig XTableTheatre3Equip
function XUiTheatre3EquipmentDesc:SetEquipId(equipConfig, curEquipId, slotId)
    self._EquipId = equipConfig.Id
    if not self._Equipment then
        ---@type XUiTheatre3EquipmentCell
        self._Equipment = XUiTheatre3EquipmentCell.New(self.UiEquipment, self.Parent, self._EquipId)
    else
        self._Equipment:ShowEquip(self._EquipId)
    end

    local isCur = self._EquipId == curEquipId
    self.ImgNowBg.gameObject:SetActiveEx(isCur)
    self.TagNow.gameObject:SetActiveEx(isCur)
    self.TxtDetails.text = XUiHelper.ReplaceUnicodeSpace(XUiHelper.ReplaceTextNewLine(XUiHelper.FormatText(equipConfig.EffectDesc, equipConfig.TraitName)))

    local wearer = self._Control:GetEquipBelong(self._EquipId)
    local isMine = wearer == slotId
    self.TagEquipped.gameObject:SetActiveEx(isMine)
    self._Equipment:SetState(wearer == -1 or not isMine)
    self._Equipment:AddClick(function()
        self._Control:OpenEquipmentTipByAlign(self._EquipId, nil, nil, nil, self.UiEquipment)
    end)
end

return XUiTheatre3EquipmentDesc