local XHomeCharSetLongPressTriggerNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, "HomeCharSetLongPressTrigger", CsBehaviorNodeType.Action, true, false)

function XHomeCharSetLongPressTriggerNode:OnAwake()
    if self.Fields == nil then
        self.Node.Status = CsNodeStatus.ERROR
        return
    end

    if self.Fields["Trigger"] == nil then
        self.Node.Status = CsNodeStatus.ERROR
        return
    end

    self.Trigger = self.Fields["Trigger"]
end

function XHomeCharSetLongPressTriggerNode:OnEnter()
    self.AgentProxy:SetCharLongPressTrigger(self.Trigger)
    self.Node.Status = CsNodeStatus.SUCCESS
end
