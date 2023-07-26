local XHomeFurnitureDoEffectNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, "HomeFurnitureDoEffect",CsBehaviorNodeType.Action,true,false)

function XHomeFurnitureDoEffectNode:OnAwake()
    if self.Fields == nil then
        self.Node.Status = CsNodeStatus.ERROR
        return
    end

    if self.Fields["EffectId"] == nil then
        self.Node.Status = CsNodeStatus.ERROR
        return
    end

    self.EffectId = self.Fields["EffectId"]
end

function XHomeFurnitureDoEffectNode:OnEnter()
    self.AgentProxy:DoEffectNode(self.EffectId)
    self.Node.Status = CsNodeStatus.SUCCESS
end