local XGuideDispatchEvent = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, "GuideDispatchEvent", CsBehaviorNodeType.Action, true, false)

function XGuideDispatchEvent:OnAwake()
    if self.Fields == nil then
        self.Node.Status = CsNodeStatus.ERROR
        return
    end
    if self.Fields["EventId"] == nil then
        self.Node.Status = CsNodeStatus.ERROR
        return
    end
    self.EventId = self.Fields["EventId"]
end

function XGuideDispatchEvent:OnEnter()
    XEventManager.DispatchEvent(self.EventId)
    self.Node.Status = CsNodeStatus.SUCCESS
end