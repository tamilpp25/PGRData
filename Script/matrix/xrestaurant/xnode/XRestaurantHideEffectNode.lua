
---@class XRestaurantHideEffectNode : XLuaBehaviorNode
---@field AgentProxy XRestaurantCharAgent
local XRestaurantHideEffectNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, 
        "RestaurantHideEffect", CsBehaviorNodeType.Action, true, false)


function XRestaurantHideEffectNode:OnEnter()
    self.AgentProxy:DoHideEffect()
    self.Node.Status = CsNodeStatus.SUCCESS 
end