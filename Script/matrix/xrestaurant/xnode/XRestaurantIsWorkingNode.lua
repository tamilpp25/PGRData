
---@class XRestaurantIsWorkingNode : XLuaBehaviorNode
---@field AgentProxy XRestaurantCharAgent
local XRestaurantIsWorkingNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode,
        "RestaurantIsWorking", CsBehaviorNodeType.Condition, true, false)

function XRestaurantIsWorkingNode:OnEnter()
    local isWorking = self.AgentProxy:DoIsWorking()

    if isWorking then
        self.Node.Status = CsNodeStatus.SUCCESS
    else
        self.Node.Status = CsNodeStatus.FAILED
    end
end