
---@class XRestaurantRandomPathNode : XLuaBehaviorNode
---@field AgentProxy XRestaurantCharAgent
local XRestaurantRandomPathNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, 
        "RestaurantRandomPath", CsBehaviorNodeType.Action, true, false)


function XRestaurantRandomPathNode:OnEnter()
    self.AgentProxy:DoRandomPath()
    self.Node.Status = CsNodeStatus.SUCCESS 
end