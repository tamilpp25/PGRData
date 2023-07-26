local XHomeCharStateChangeNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, "HomeCharStateChange",CsBehaviorNodeType.Action,true,false)

function XHomeCharStateChangeNode:OnAwake()
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


function XHomeCharStateChangeNode:OnEnter()
    if self.AgentProxy.Role then --工会
        local isIgnore=not XDataCenter.GuildDormManager.CheckNpcIsStatic(self.AgentProxy.Role.RefreshId)
        self.AgentProxy:ChangeStatus(self.State,isIgnore)
    else --宿舍
        self.AgentProxy:ChangeStatus(self.State)
    end
    
    self.Node.Status = CsNodeStatus.SUCCESS
end

