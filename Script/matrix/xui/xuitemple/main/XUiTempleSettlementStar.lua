---@class XUiTempleSettlementStar : XUiNode
---@field _Control XTempleControl
local XUiTempleSettlementStar = XClass(XUiNode, "")

---@param data XTempleGameControlSettleStar
function XUiTempleSettlementStar:Update(data)
    if not data then
        self:Close()
    else
        self:Open()
    end
    if data.IsOn then
        self.PanelOn.gameObject:SetActiveEx(true)
        self.PanelOff.gameObject:SetActiveEx(false)
        self.TxtTargetOn.text = data.Text
    else
        self.PanelOn.gameObject:SetActiveEx(false)
        self.PanelOff.gameObject:SetActiveEx(true)
        self.TxtTargetOff.text = XTool.RemoveRichText(data.Text)
    end
end

return XUiTempleSettlementStar