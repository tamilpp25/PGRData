
---@class XRestaurantIsWorkWithBuffNode : XLuaBehaviorNode
---@field AgentProxy XRestaurantCharAgent
local XRestaurantIsWorkWithBuffNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode,
        "RestaurantIsWorkWithBuff", CsBehaviorNodeType.Condition, true, false)

function XRestaurantIsWorkWithBuffNode:OnEnter()
    local isEqual = self.AgentProxy:DoIsWorkWithBuff()
    if isEqual then
        self.Node.Status = CsNodeStatus.SUCCESS
    else
        self.Node.Status = CsNodeStatus.FAILED
    end
end