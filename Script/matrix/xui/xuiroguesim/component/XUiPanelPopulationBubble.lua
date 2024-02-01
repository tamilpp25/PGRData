local XUiPanelRogueSimBaseBubble = require("XUi/XUiRogueSim/Component/XUiPanelRogueSimBaseBubble")
---@class XUiPanelPopulationBubble : XUiPanelRogueSimBaseBubble
---@field private _Control XRogueSimControl
local XUiPanelPopulationBubble = XClass(XUiPanelRogueSimBaseBubble, "XUiPanelPopulationBubble")

function XUiPanelPopulationBubble:OnStart()
    self.CurAlignment = XEnumConst.RogueSim.Alignment.CB
    self:SetAnchorAndPivot()
end

function XUiPanelPopulationBubble:Refresh(targetTransform, id)
    self:SetTransform(targetTransform)
    self.Id = id
    self.TxtDetail.text = self._Control.ResourceSubControl:GetResourceDesc(self.Id)
end

return XUiPanelPopulationBubble
