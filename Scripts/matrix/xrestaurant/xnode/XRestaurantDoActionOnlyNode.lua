
---@class XRestaurantDoActionOnlyNode : XLuaBehaviorNode
---@field AgentProxy XRestaurantCharAgent
local XRestaurantDoActionOnlyNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode,
        "RestaurantDoActionOnly", CsBehaviorNodeType.Action, true, false)

function XRestaurantDoActionOnlyNode:OnAwake()
    if self.Fields == nil then
        self.Node.Status = CsNodeStatus.ERROR
        return
    end

    if self.Fields["ActionId"] == nil or self.Fields["NeedFadeCross"] == nil or self.Fields["CrossDuration"] == nil then
        self.Node.Status = CsNodeStatus.ERROR
        return
    end
    
    self.ActionId = self.Fields["ActionId"]
    self.NeedFadeCross = self.Fields["NeedFadeCross"]
    self.CrossDuration = self.Fields["CrossDuration"]
    
end

function XRestaurantDoActionOnlyNode:OnEnter()
    self.AgentProxy:DoAction(self.ActionId, self.NeedFadeCross, self.CrossDuration)
    self.Node.Status = CsNodeStatus.SUCCESS
end