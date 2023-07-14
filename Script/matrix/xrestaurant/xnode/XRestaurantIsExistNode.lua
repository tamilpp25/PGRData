
---@class XRestaurantIsExistNode : XLuaBehaviorNode
---@field AgentProxy XRestaurantCharAgent
local XRestaurantIsExistNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode,
        "RestaurantIsExist", CsBehaviorNodeType.Condition, true, false)

function XRestaurantIsExistNode:OnEnter()
    local isExist = self.AgentProxy:DoIsExist()

    if isExist then
        self.Node.Status = CsNodeStatus.SUCCESS
    else
        self.Node.Status = CsNodeStatus.FAILED
    end
end