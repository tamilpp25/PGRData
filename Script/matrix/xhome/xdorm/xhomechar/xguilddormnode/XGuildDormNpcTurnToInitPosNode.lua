local XGuildDormNpcTurnToInitPosNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, "GuildDormNpcTurnToInitPos", CsBehaviorNodeType.Action, true, false)

function XGuildDormNpcTurnToInitPosNode:OnAwake()
    if self.Fields == nil or self.Fields["IsSlerp"] == nil or self.Fields["IsSetPosition"] == nil then
        self.Node.Status = CsNodeStatus.ERROR
        return
    end

    self.IsSlerp = self.Fields["IsSlerp"]
    self.IsSetPosition = self.Fields["IsSetPosition"]
end

function XGuildDormNpcTurnToInitPosNode:OnEnter()
    if self.AgentProxy:TurnToInitPos(self.IsSetPosition, self.IsSlerp) then
        self.Node.Status = CsNodeStatus.SUCCESS
    end
end