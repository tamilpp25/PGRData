local XGuildDormFurniturePlayEffectNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, "GuildDormFurniturePlayEffect", CsBehaviorNodeType.Action, true, false)

function XGuildDormFurniturePlayEffectNode:OnAwake()
    if self.Fields == nil or self.Fields["EffectId"] == nil then
        self.Node.Status = CsNodeStatus.ERROR
        return
    end
    self.EffectId = self.Fields["EffectId"]
    local x = self.Fields["X"] or 0
    local y = self.Fields["Y"] or 0
    local z = self.Fields["Z"] or 0
    self.LocalPosition = Vector3(x, y, z)
    self.SpecialNode = self.Fields["SpecialNode"] or false
    self.SpecialNodeName = self.Fields["SpecialNodeName"] or "SpecialFx"
end

function XGuildDormFurniturePlayEffectNode:OnEnter()
    self.AgentProxy:FurniturePlayEffect(self.EffectId, self.LocalPosition, self.SpecialNode, self.SpecialNodeName)
    self.Node.Status = CsNodeStatus.SUCCESS
end

local XGuildDormFurnitureHideEffectNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, "GuildDormFurnitureHideEffect", CsBehaviorNodeType.Action, true, false)

function XGuildDormFurnitureHideEffectNode:OnAwake()
    if self.Fields == nil or self.Fields["EffectIds"] == nil then
        self.Node.Status = CsNodeStatus.ERROR
        return
    end
    self.EffectIds = self.Fields["EffectIds"]
end

function XGuildDormFurnitureHideEffectNode:OnEnter()
    self.AgentProxy:FurnitureHideEffect(self.EffectIds)
    self.Node.Status = CsNodeStatus.SUCCESS
end