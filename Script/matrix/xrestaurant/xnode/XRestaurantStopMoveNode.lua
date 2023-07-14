
---@class XRestaurantStopMoveNode : XLuaBehaviorNode
---@field AgentProxy XRestaurantCharAgent
local XRestaurantStopMoveNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, 
        "RestaurantStopMove", CsBehaviorNodeType.Action, true, false)


function XRestaurantStopMoveNode:OnEnter()
    self.AgentProxy:DoStopMove()
    self.Node.Status = CsNodeStatus.SUCCESS 
end