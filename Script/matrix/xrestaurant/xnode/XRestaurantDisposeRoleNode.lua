
---@class XRestaurantDisposeRoleNode : XLuaBehaviorNode
---@field AgentProxy XRestaurantCharAgent
local XRestaurantDisposeRoleNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, 
        "RestaurantDisposeRole", CsBehaviorNodeType.Action, true, false)


function XRestaurantDisposeRoleNode:OnEnter()
    self.AgentProxy:DelayRelease()
    self.Node.Status = CsNodeStatus.SUCCESS 
end