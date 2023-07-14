local XHomeCharIsDirectInteract = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, "HomeCharIsDirectInteract", CsBehaviorNodeType.Condition, true, true)

function XHomeCharIsDirectInteract:OnEnter()
    self.PlayerId = self.AgentProxy:GetPlayerId()
end

function XHomeCharIsDirectInteract:OnUpdate(dt)
    local result = self.AgentProxy:CheckIsDirectInteract()
    if result then
        self.Node.Status = CsNodeStatus.SUCCESS
    else
        self.Node.Status = CsNodeStatus.FAILED
    end
end