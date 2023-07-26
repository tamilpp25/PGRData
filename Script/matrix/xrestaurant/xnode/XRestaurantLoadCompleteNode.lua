
---@class XRestaurantLoadCompleteNode : XLuaBehaviorNode
---@field AgentProxy XRestaurantCharAgent
local XRestaurantLoadCompleteNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, 
        "RestaurantLoadComplete", CsBehaviorNodeType.Action, true, false)


function XRestaurantLoadCompleteNode:OnEnter()
    self.AgentProxy:DoLoadComplete()
    self.Node.Status = CsNodeStatus.SUCCESS 
end