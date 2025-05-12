---@class XUiGridRulePanel
local XUiGridRulePanel = XClass(XUiNode, "XUiGridRulePanel")

function XUiGridRulePanel:Refresh(title, text)
    self.TxtRuleTittle.text = XUiHelper.ConvertLineBreakSymbol(title)
    self.TxtRule.text = XUiHelper.ConvertLineBreakSymbol(text)
end

return XUiGridRulePanel