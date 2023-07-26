local XHomeFurnitureStateChangeNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, "HomeFurnitureStateChange",CsBehaviorNodeType.Action,true,false)

function XHomeFurnitureStateChangeNode:OnAwake()
    if self.Fields == nil then
        self.Node.Status = CsNodeStatus.ERROR
        return
    end

    if self.Fields["State"] == nil then
        self.Node.Status = CsNodeStatus.ERROR
        return
    end

    self.State = self.Fields["State"]
end


function XHomeFurnitureStateChangeNode:OnEnter()
    self.AgentProxy:ChangeStatus(self.State)
    self.Node.Status = CsNodeStatus.SUCCESS
end

