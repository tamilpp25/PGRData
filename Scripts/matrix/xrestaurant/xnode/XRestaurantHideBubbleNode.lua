
---@class XRestaurantHideBubbleNode : XLuaBehaviorNode
---@field AgentProxy XRestaurantCharAgent
local XRestaurantHideBubbleNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, 
        "RestaurantHideBubble", CsBehaviorNodeType.Action, true, false)


function XRestaurantHideBubbleNode:OnEnter()
    self.AgentProxy:DoHideBubble()
    self.Node.Status = CsNodeStatus.SUCCESS 
end