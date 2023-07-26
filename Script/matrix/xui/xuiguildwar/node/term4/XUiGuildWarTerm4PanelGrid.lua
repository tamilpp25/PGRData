local XUiGuildWarStageDetailEvent = require("XUi/XUiGuildWar/Node/XUiGuildWarStageDetailEvent")

---@class XUiGuildWarTerm4PanelGrid
local XUiGuildWarTerm4PanelGrid = XClass(nil, "XUiGuildWarTerm4PanelGrid")

function XUiGuildWarTerm4PanelGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    XUiHelper.RegisterClickEvent(self, self.Press, self.OnClick)

    ---@type XUiGuildWarStageDetailEvent[]
    self._UiEvent = {}

    ---@type XTerm4BossChildGWNode
    self._Node = false

    self.PanelJn.gameObject:SetActiveEx(false)
end

---@param node XTerm4BossChildGWNode
function XUiGuildWarTerm4PanelGrid:Update(node)
    self._Node = node
    local eventDetails = node:GetAllFightEventDetailConfig()
    for i = 1, #eventDetails do
        local uiEvent = self._UiEvent[i]
        if not uiEvent then
            local ui = XUiHelper.Instantiate(self.PanelJn.gameObject, self.PanelJn.transform.parent.transform)
            uiEvent = XUiGuildWarStageDetailEvent.New(ui)
            self._UiEvent[i] = uiEvent
        end
        local event = eventDetails[i]
        uiEvent:Update(event)
        uiEvent.GameObject:SetActiveEx(true)
    end
    for i = #eventDetails + 1, #self._UiEvent do
        local uiEvent = self._UiEvent[i]
        uiEvent.GameObject:SetActiveEx(false)
    end
end

function XUiGuildWarTerm4PanelGrid:OnClick()
    XEventManager.DispatchEvent(XEventId.EVENT_GUILDWAR_PANDA_UNFOLD_DETAIL, true, self._Node:GetSelfChildIndex())
end

return XUiGuildWarTerm4PanelGrid