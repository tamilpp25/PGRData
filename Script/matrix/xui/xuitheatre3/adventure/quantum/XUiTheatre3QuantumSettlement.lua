---@class XUiTheatre3QuantumSettlement : XLuaUi
---@field _Control XTheatre3Control
local XUiTheatre3QuantumSettlement = XLuaUiManager.Register(XLuaUi, "UiTheatre3QuantumSettlement")

function XUiTheatre3QuantumSettlement:OnAwake()
    self:AddBtnListener()
end

function XUiTheatre3QuantumSettlement:OnStart(suitId, closeCb)
    local XUiTheatre3PanelQuantumSuit = require("XUi/XUiTheatre3/Adventure/Quantum/XUiTheatre3PanelQuantumSuit")
    self._CloseCb = closeCb
    ---@type XUiTheatre3PanelQuantumSuit
    self._TipOld = XUiTheatre3PanelQuantumSuit.New(self.BubbleEquipmentOld, self, suitId, 1, false)
    ---@type XUiTheatre3PanelQuantumSuit
    self._TipNew = XUiTheatre3PanelQuantumSuit.New(self.BubbleEquipmentNew, self, suitId, 2, true)
    
    self._TipOld:UpdateSuitDesc(true)
    self._TipNew:UpdateSuitDesc(true)
    ---@type XUiTheatre3PanelQuantumSuit[]
    self._GridSuitList = {
        self._TipOld,
        self._TipNew
    }
end

function XUiTheatre3QuantumSettlement:OnSuitSelects(index)
    for i, grid in ipairs(self._GridSuitList) do
        grid:UpdateSelect(index == i, true)
    end
end

--region Ui - BtnListener
function XUiTheatre3QuantumSettlement:AddBtnListener()
    self:RegisterClickEvent(self.BtnClose, self.OnBtnCloseClick)
end

function XUiTheatre3QuantumSettlement:OnBtnCloseClick()
    self:Close()
    if self._CloseCb then
        self._CloseCb()
    end
end
--endregion

return XUiTheatre3QuantumSettlement