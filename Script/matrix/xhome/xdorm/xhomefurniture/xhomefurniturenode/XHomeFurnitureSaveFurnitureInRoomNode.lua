local XHomeFurnitureSaveFurnitureInRoomNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, "HomeFurnitureSaveFurnitureInRoom", CsBehaviorNodeType.Action, true, false)

function XHomeFurnitureSaveFurnitureInRoomNode:OnEnter()
    self.AgentProxy:SaveFurnitureInRoomNode()
    self.Node.Status = CsNodeStatus.SUCCESS
end