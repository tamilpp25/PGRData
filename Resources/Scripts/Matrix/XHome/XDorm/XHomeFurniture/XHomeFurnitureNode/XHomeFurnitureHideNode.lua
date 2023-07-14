local XHomeFurnitureHideNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, "HomeFurnitureHide", CsBehaviorNodeType.Action, true, false)

function XHomeFurnitureHideNode:OnEnter()
    self.AgentProxy:HideFurnitureNode()
    self.Node.Status = CsNodeStatus.SUCCESS
end