local XUiTheatre3EquipmentCharacter = require("XUi/XUiTheatre3/Equip/XUiTheatre3EquipmentCharacter")
local XUiTheatre3EquipmentTip = require("XUi/XUiTheatre3/Equip/XUiTheatre3EquipmentTip")

---@class XUiTheatre3MoveTarget : XLuaUi
---@field _Control XTheatre3Control
local XUiTheatre3MoveTarget = XLuaUiManager.Register(XLuaUi, "UiTheatre3MoveTarget")

function XUiTheatre3MoveTarget:OnAwake()

end

function XUiTheatre3MoveTarget:OnStart(suitId)
    self._SuitId = suitId
    self:InitCompnent()
end

function XUiTheatre3MoveTarget:OnDestroy()

end

function XUiTheatre3MoveTarget:InitCompnent()
    self._TopController = XUiHelper.NewPanelTopControl(self, self.TopControlWhite)
    self._Character1 = XUiTheatre3EquipmentCharacter.New(self.CharacterGrid1, self)
    self._Character2 = XUiTheatre3EquipmentCharacter.New(self.CharacterGrid2, self)
    self._Character3 = XUiTheatre3EquipmentCharacter.New(self.CharacterGrid3, self)
    ---@type XUiTheatre3EquipmentTip
    self._Tip = XUiTheatre3EquipmentTip.New(self.BubbleEquipment, self)
    self._Tip:ShowSuitDetailTip(self._SuitId, "切换", function()
        XLuaUiManager.Open("UiTheatre3SetBag")
    end)

    local tabs = {}
    table.insert(tabs, self.CharacterGrid1:GetComponent("XUiButton"))
    table.insert(tabs, self.CharacterGrid2:GetComponent("XUiButton"))
    table.insert(tabs, self.CharacterGrid3:GetComponent("XUiButton"))
    self.CharacterTab:Init(tabs, function(index)
        self:OnSelectCharacter(index)
    end)
    self.CharacterTab:SelectIndex(1)

    self.BtnEnterB:SetNameByGroup(0, "交换套装")
    self.BtnEnterB.CallBack = handler(self, self.ExchangeSuit)
end

function XUiTheatre3MoveTarget:OnSelectCharacter(index)

end

function XUiTheatre3MoveTarget:ExchangeSuit()
    XLuaUiManager.Open("UiTheatre3SetBag", { isExchangeSuit = true })
end

return XUiTheatre3MoveTarget