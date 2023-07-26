
local XHomeCharTurnToFurnitureStayPos = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, "HomeCharTurnToFurnitureStayPos", CsBehaviorNodeType.Action, true, false)

function XHomeCharTurnToFurnitureStayPos:OnEnter()
    self.AgentProxy:TurnToFurnitureStayPos(function()
        self.Node.Status = CsNodeStatus.SUCCESS
    end, self.Fields["IsSlerp"], self.Fields["IsSetPosition"])
end
