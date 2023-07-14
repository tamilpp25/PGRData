local XHomePlayFurnitureEffectNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, "HomeCharPlayFurnitureEffect", CsBehaviorNodeType.Action, true, false)

function XHomePlayFurnitureEffectNode:OnAwake()
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

function XHomePlayFurnitureEffectNode:OnEnter()
    if self.AgentProxy:PlayFurnitureEffect(self.EffectId) then
        self.Node.Status = CsNodeStatus.SUCCESS
    end
end