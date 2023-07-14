local XHomeFurnitureChangeFurniturePositionNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, "HomeFurnitureChangeFurniturePosition", CsBehaviorNodeType.Action, true, false)

function XHomeFurnitureChangeFurniturePositionNode:OnEnter()
    if self.AgentProxy:ChangeFurnituePositionNode() then
        self.Node.Status = CsNodeStatus.SUCCESS
    else
        self.Node.Status = CsNodeStatus.FAILED
    end
end