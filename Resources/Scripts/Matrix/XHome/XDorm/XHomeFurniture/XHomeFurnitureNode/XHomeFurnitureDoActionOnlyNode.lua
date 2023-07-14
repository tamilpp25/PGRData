local XHomeFurnitureDoActionOnlyNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, "HomeFurnitureDoActionOnly",CsBehaviorNodeType.Action,true,false)

function XHomeFurnitureDoActionOnlyNode:OnAwake()
    if self.Fields == nil then
        self.Node.Status = CsNodeStatus.ERROR
        return
    end

    if self.Fields["ActionId"] == nil then
        self.Node.Status = CsNodeStatus.ERROR
        return
    end

    self.ActionId = self.Fields["ActionId"]
    self.CrossDuration = self.Fields["CrossDuration"]
    self.NeedFadeCross = self.Fields["NeedFadeCross"]
end

function XHomeFurnitureDoActionOnlyNode:OnEnter()
    self.AgentProxy:DoActionNode(self.ActionId,self.NeedFadeCross,self.CrossDuration)
    self.Node.Status = CsNodeStatus.SUCCESS
end