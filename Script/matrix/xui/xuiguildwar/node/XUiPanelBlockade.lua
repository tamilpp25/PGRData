local XUiGuildWarStageDetailEvent = require("XUi/XUiGuildWar/Node/XUiGuildWarStageDetailEvent")

---@class XUiGuildWarPanelBlockade
local XUiPanelBlockade = XClass(nil, "XUiPanelBlockade")

function XUiPanelBlockade:Ctor(ui)
    self._Node = false
    XUiHelper.InitUiClass(self, ui)
    
    self.PanelUiDetail01 = {}
    XTool.InitUiObjectByUi(self.PanelUiDetail01, self.PanelDetail01)

    ---@type XUiGuildWarStageDetailEvent[]
    self._UiEvent = {}
    self.PanelBuf.gameObject:SetActiveEx(false)
end

---@param node XBlockadeGWNode
function XUiPanelBlockade:SetData(node)
    self._Node = node
    self.TxtAreaDetails.text = self._Node:GetDesc()
    self.GameObject:SetActiveEx(true)

    --休战期或死亡则关闭显示
    if not XDataCenter.GuildWarManager.CheckRoundIsInTime() or
            not (node:GetStutesType() == XGuildWarConfig.NodeStatusType.Alive) then
        self.PanelBuf.gameObject:SetActiveEx(false)
        return
    end
    
    local eventDetails = node:GetAllFightEventDetailConfig()
    for i = 1, #eventDetails do
        local uiEvent = self._UiEvent[i]
        if not uiEvent then
            local ui = XUiHelper.Instantiate(self.PanelBuf.gameObject, self.PanelBuf.transform.parent.transform)
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

return XUiPanelBlockade
