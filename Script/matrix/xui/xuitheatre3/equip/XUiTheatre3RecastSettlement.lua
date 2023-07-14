local XUiTheatre3EquipmentTip = require("XUi/XUiTheatre3/Equip/XUiTheatre3EquipmentTip")

---@class XUiTheatre3RecastSettlement : XLuaUi
local XUiTheatre3RecastSettlement = XLuaUiManager.Register(XLuaUi, "UiTheatre3RecastSettlement")

function XUiTheatre3RecastSettlement:OnAwake()

end

function XUiTheatre3RecastSettlement:OnStart(srcEquipId, dstEquipId)
    self:RegisterClickEvent(self.BtnClose, self.Close)

    ---@type XUiTheatre3EquipmentTip
    self._TipOld = XUiTheatre3EquipmentTip.New(self.BubbleEquipmentOld, self)
    self._TipOld:SetSelectCallBack(function()
        self._TipNew:CloseEffectDetail()
    end)

    ---@type XUiTheatre3EquipmentTip
    self._TipNew = XUiTheatre3EquipmentTip.New(self.BubbleEquipmentNew, self)
    self._TipNew:SetSelectCallBack(function()
        self._TipOld:CloseEffectDetail()
    end)

    self._TipOld:ShowEquipTip(srcEquipId)
    self._TipNew:ShowEquipTip(dstEquipId)
end

function XUiTheatre3RecastSettlement:OnDestroy()

end

return XUiTheatre3RecastSettlement