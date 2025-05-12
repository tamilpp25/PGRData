---@class XUiTheatre3PanelEquipFightResult : XUiNode
---@field _Control XTheatre3Control
---@field SetGrid UnityEngine.Transform
---@field GridResult UnityEngine.Transform
---@field Parent XUiTheatre3FightResult
local XUiTheatre3PanelEquipFightResult = XClass(XUiNode, "XUiTheatre3PanelEquipFightResult")

function XUiTheatre3PanelEquipFightResult:OnStart()
    local XUiTheatre3GridFightResult = require("XUi/XUiTheatre3/Adventure/FightResult/XUiTheatre3GridFightResult")
    ---@type XUiTheatre3GridFightResult
    self._GridFightResult = XUiTheatre3GridFightResult.New(self.GridResult, self)
    
    local XUiTheatre3GridFightEquip = require("XUi/XUiTheatre3/Adventure/FightResult/XUiTheatre3GridFightEquip")
    ---@type XUiTheatre3GridFightEquip
    self._GridEquipSuit = XUiTheatre3GridFightEquip.New(self.SetGrid, self)
end

function XUiTheatre3PanelEquipFightResult:Refresh(slotId, equipSuitId)
    self:UpdateEquipSuit(slotId, equipSuitId)
    self:UpdateFightResult(slotId, equipSuitId)
end

--region Ui - EquipSuit
function XUiTheatre3PanelEquipFightResult:UpdateEquipSuit(slotId, equipSuitId)
    self._GridEquipSuit:Refresh(slotId, equipSuitId)
end
--endregion

--region Ui - FightResult
function XUiTheatre3PanelEquipFightResult:UpdateFightResult(slotId, equipSuitId)
    self._GridFightResult:RefreshByEquipSuitId(slotId, equipSuitId)
end
--endregion

return XUiTheatre3PanelEquipFightResult