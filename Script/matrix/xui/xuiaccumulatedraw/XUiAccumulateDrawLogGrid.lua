---@class XUiAccumulateDrawLogGrid : XUiNode
---@field TxtRuleTittle UnityEngine.UI.Text
---@field TxtRule UnityEngine.UI.Text
local XUiAccumulateDrawLogGrid = XClass(XUiNode, "XUiAccumulateDrawLogGrid")

--region 生命周期
---@param ruler XAccumulateExpendRuler
function XUiAccumulateDrawLogGrid:OnStart(ruler)
    self:Refresh(ruler)
end

---@param ruler XAccumulateExpendRuler
function XUiAccumulateDrawLogGrid:Refresh(ruler)
    self.TxtRule.text = ruler:GetDesc()
    self.TxtRuleTittle.text = ruler:GetTitle()
end
--endregion

return XUiAccumulateDrawLogGrid
