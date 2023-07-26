local XHomeFurnitureCheckRayCastFunitureNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, "HomeFurnitureCheckRayCastFuniture", CsBehaviorNodeType.Decorator, true, true)

function XHomeFurnitureCheckRayCastFunitureNode:OnUpdate(dt)
    local result = self.AgentProxy:CheckRayCastFurnitureNode()

    if not result then
        self.Node.ChildNode:OnReset()
        self.Node.Status = CsNodeStatus.FAILED
        return
    end

    self.Node.ChildNode:OnUpdate(dt)
    self.Node.Status = self.Node.ChildNode.Status
end