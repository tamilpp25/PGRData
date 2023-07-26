
---@class XRestaurantSetRedPointNode : XLuaBehaviorNode
---@field AgentProxy XRestaurantCharAgent
local XRestaurantSetRedPointNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, 
        "RestaurantSetRedPoint", CsBehaviorNodeType.Action, true, false)


function XRestaurantSetRedPointNode:OnEnter()
    self.AgentProxy:DoSetRedPoint()
    self.Node.Status = CsNodeStatus.SUCCESS 
end