local XHomeCharEventRewardNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, "HomeCharEventReward", CsBehaviorNodeType.Action, true, false)

function XHomeCharEventRewardNode:OnEnter()
    local isWaitCb = self.AgentProxy:ShowEventReward(function()
        self.Node.Status = CsNodeStatus.SUCCESS
    end)
    if not isWaitCb then
        self.Node.Status = CsNodeStatus.SUCCESS
    end
end