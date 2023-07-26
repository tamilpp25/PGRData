local XGuildDormNpcForwardToPlayerNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, "GuildDormNpcForwardToPlayer", CsBehaviorNodeType.Action, true, false)

function XGuildDormNpcForwardToPlayerNode:OnAwake()
    if self.Fields == nil or self.Fields["Direction"] == nil then
        self.Node.Status = CsNodeStatus.ERROR
        return
    end
    
    self.Direction = self.Fields["Direction"]
end

function XGuildDormNpcForwardToPlayerNode:OnEnter()
    if self.AgentProxy:SetForwardToPlayer(self.Direction) then
        self.Node.Status = CsNodeStatus.SUCCESS
    end
end