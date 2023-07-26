local XHomeCharTalkEnd = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, "HomeCharTalkEnd", CsBehaviorNodeType.Condition, true, false)

function XHomeCharTalkEnd:OnGetEvents()
    return { XEventId.EVENT_DORM_TALK_END }
end

function XHomeCharTalkEnd:OnNotify(evt, ...)
    local args = { ... }
    if evt == XEventId.EVENT_DORM_TALK_END then
        self.Node.Status = CsNodeStatus.SUCCESS
    end
end

local XHomeCharPlayTalkSystem = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, "HomeCharPlayTalkSystem", CsBehaviorNodeType.Action, true, false)

function XHomeCharPlayTalkSystem:OnEnter()
    self.AgentProxy:PlayTalkSystem(self.Fields["TalkId"])
    self.Node.Status = CsNodeStatus.SUCCESS
end