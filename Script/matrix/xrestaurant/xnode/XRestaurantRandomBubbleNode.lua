
---@class XRestaurantRandomBubbleNode : XLuaBehaviorNode
---@field AgentProxy XRestaurantCharAgent
local XRestaurantRandomBubbleNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, 
        "RestaurantRandomBubble", CsBehaviorNodeType.Action, true, false)


function XRestaurantRandomBubbleNode:OnEnter()
    self.AgentProxy:DoRandomBubble()
    self.Node.Status = CsNodeStatus.SUCCESS 
end