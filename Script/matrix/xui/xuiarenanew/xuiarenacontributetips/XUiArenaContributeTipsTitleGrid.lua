---@class XUiArenaContributeTipsTitleGrid : XUiNode
---@field TxtTitle UnityEngine.UI.Text
---@field TxtTips UnityEngine.UI.Text
---@field _Control XArenaControl
local XUiArenaContributeTipsTitleGrid = XClass(XUiNode, "XUiArenaContributeTipsTitleGrid")

function XUiArenaContributeTipsTitleGrid:Refresh(title, tips)
    self.TxtTitle.text = title
    self.TxtTips.text = tips
end

return XUiArenaContributeTipsTitleGrid