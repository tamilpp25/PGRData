local XHomeCharPlayFurnitureActionNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, "HomeCharPlayFurnitureAction", CsBehaviorNodeType.Action, true, false)

function XHomeCharPlayFurnitureActionNode:OnAwake()
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
    self.NeedReplaySameAnimation = self.Fields["NeedReplaySameAnimation"]
end

function XHomeCharPlayFurnitureActionNode:OnEnter()
    if self.AgentProxy:PlayFurnitureAction(self.ActionId, self.NeedFadeCross, self.CrossDuration, self.NeedReplaySameAnimation) then
        self.Node.Status = CsNodeStatus.SUCCESS
    end
end