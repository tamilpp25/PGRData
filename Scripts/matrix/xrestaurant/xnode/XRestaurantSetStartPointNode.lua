
---@class XRestaurantSetStartPointNode : XLuaBehaviorNode
---@field AgentProxy XRestaurantCharAgent
local XRestaurantSetStartPointNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, 
        "RestaurantSetStartPoint", CsBehaviorNodeType.Action, true, false)


function XRestaurantSetStartPointNode:OnEnter()
    self.AgentProxy:DoSetStartPoint()
    self.Node.Status = CsNodeStatus.SUCCESS 
end