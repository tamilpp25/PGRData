---@class XUiLuckyTenantChessBagProp : XUiNode
---@field _Control XLuckyTenantControl
local XUiLuckyTenantChessBagProp = XClass(XUiNode, "XUiLuckyTenantChessBagProp")

function XUiLuckyTenantChessBagProp:OnStart()
    local button = self.Button
    if not button then
        button = self.Transform:GetComponent("XUiButton")
    end
    if button then
        XUiHelper.RegisterClickEvent(self, button, self.OnClick, nil, true)
    end
end

---@param data XUiLuckyTenantChessBagPropData
function XUiLuckyTenantChessBagProp:Update(data)
    self._Data = data
    self.TxtNumScore.text = data.Amount
    self.RImgScoreIcon:SetRawImage(data.Icon)
end

function XUiLuckyTenantChessBagProp:OnClick()
    XEventManager.DispatchEvent(XEventId.EVENT_LUCKY_TENANT_ON_CLICK_REWARD, self._Data, self.Transform.position)
end

return XUiLuckyTenantChessBagProp