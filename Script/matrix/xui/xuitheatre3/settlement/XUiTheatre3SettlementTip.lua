local XUiTheatre3SettlementCell = require("XUi/XUiTheatre3/Settlement/XUiTheatre3SettlementCell")

---@class XUiTheatre3SettlementTip : XLuaUi 藏品Tip
---@field _Control XTheatre3Control
local XUiTheatre3SettlementTip = XLuaUiManager.Register(XLuaUi, "UiTheatre3SettlementTip")

function XUiTheatre3SettlementTip:OnAwake()
    self:RegisterClickEvent(self.BtnMask, self.Close)
end

function XUiTheatre3SettlementTip:OnStart(param)
    self._ItemId = param.itemId
    self._ItemConfig = self._Control:GetItemConfigById(self._ItemId)
    self:Init()
    self:SetPosition(param.worldPos)
end

function XUiTheatre3SettlementTip:OnDestroy()

end

function XUiTheatre3SettlementTip:Init()
    ---@type XUiTheatre3SettlementCell
    self._Settlement = XUiTheatre3SettlementCell.New(self.ItemGrid, self)
    self._Settlement:SetData(self._ItemId)
    self.TxtName.text = self._ItemConfig.Name
    self.TxtDetails.text = self._ItemConfig.Description
    self.TxtTitle.text = XUiHelper.GetText("Theatre3SettlementTipTitle")
    CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.BubbleProp)
end

function XUiTheatre3SettlementTip:SetPosition(worldPos)
    if not worldPos then
        return
    end
    local tipWidth = self.BubbleProp.sizeDelta.x
    local tipHeight = self.BubbleProp.sizeDelta.y
    local pos = self.BubbleProp.parent.worldToLocalMatrix:MultiplyPoint(worldPos)
    pos.x = pos.x + tipWidth / 2
    if pos.x + tipWidth / 2 > self.Ui.Transform.rect.width / 2 then
        pos.x = self.Ui.Transform.rect.width / 2 - tipWidth / 2
    end
    if tipHeight - pos.y > self.Ui.Transform.rect.height / 2 then
        pos.y = tipHeight - self.Ui.Transform.rect.height / 2
    end
    self.BubbleProp.localPosition = pos
end

return XUiTheatre3SettlementTip