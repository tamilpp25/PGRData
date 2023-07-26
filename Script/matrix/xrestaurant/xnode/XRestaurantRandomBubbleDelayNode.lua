
---@class XRestaurantRandomBubbleDelayNode : XLuaBehaviorNode
---@field AgentProxy XRestaurantCharAgent
local XRestaurantRandomBubbleDelayNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, 
        "RestaurantRandomBubbleDelay", CsBehaviorNodeType.Action, true, false)

function XRestaurantRandomBubbleDelayNode:OnAwake()
    if self.Fields == nil then
        self.Node.Status = CsNodeStatus.ERROR
        return
    end

    if self.Fields["Max"] == nil or self.Fields["Min"] == nil then
        self.Node.Status = CsNodeStatus.ERROR
        return
    end
    
    self.Delay = math.random(self.Fields["Min"], self.Fields["Max"])
end


function XRestaurantRandomBubbleDelayNode:OnEnter()
    if self.AgentProxy:IsShowDelayBubble() then
        self.Node.Status = CsNodeStatus.SUCCESS
        return
    end
    self.AgentProxy:DoRandomBubbleDelay(self.Delay)
    self.Node.Status = CsNodeStatus.SUCCESS 
end