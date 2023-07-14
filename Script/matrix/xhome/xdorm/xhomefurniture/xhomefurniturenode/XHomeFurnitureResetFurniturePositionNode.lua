local XHomeFurnitureResetFurniturePositionNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, "HomeFurnitureResetFurniturePosition", CsBehaviorNodeType.Action, true, false)

function XHomeFurnitureResetFurniturePositionNode:OnEnter()
    self.AgentProxy:ResetFurnituePistionNode()
    self.Node.Status = CsNodeStatus.SUCCESS
end