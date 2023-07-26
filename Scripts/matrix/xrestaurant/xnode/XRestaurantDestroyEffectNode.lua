
---@class XRestaurantDestroyEffectNode : XLuaBehaviorNode
---@field AgentProxy XRestaurantCharAgent
local XRestaurantDestroyEffectNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, 
        "RestaurantDestroyEffect", CsBehaviorNodeType.Action, true, false)


function XRestaurantDestroyEffectNode:OnEnter()
    self.AgentProxy:DoDestroyEffect()
    self.Node.Status = CsNodeStatus.SUCCESS 
end