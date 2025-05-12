---@class XUiPanelPurchaseRandomBaseDesc: XUiNode
local XUiPanelPurchaseRandomBaseDesc = XClass(XUiNode, 'XUiPanelPurchaseRandomBaseDesc')

function XUiPanelPurchaseRandomBaseDesc:OnStart()
    self.Title.text = XUiHelper.ReadTextWithNewLine('PurchaseRandomSelectTitle')
    self.TxtRule.text = XUiHelper.ReadTextWithNewLine('PurchaseRandomSelectDesc')
end

return XUiPanelPurchaseRandomBaseDesc