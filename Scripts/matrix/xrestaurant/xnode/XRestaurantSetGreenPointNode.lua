
---@class XRestaurantSetGreenPointNode : XLuaBehaviorNode
---@field AgentProxy XRestaurantCharAgent
local XRestaurantSetGreenPointNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, 
        "RestaurantSetGreenPoint", CsBehaviorNodeType.Action, true, false)


function XRestaurantSetGreenPointNode:OnEnter()
    self.AgentProxy:DoSetGreenPoint()
    self.Node.Status = CsNodeStatus.SUCCESS 
end