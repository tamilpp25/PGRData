
---@class XRestaurantCheckIntNode : XLuaBehaviorNode
---@field AgentProxy XRestaurantCharAgent
local XRestaurantCheckIntNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode,
        "RestaurantCheckInt", CsBehaviorNodeType.Condition, true, false)

function XRestaurantCheckIntNode:OnAwake()
    if self.Fields == nil then
        self.Node.Status = CsNodeStatus.ERROR
        return
    end

    if self.Fields["IntValue"] == nil then
        self.Node.Status = CsNodeStatus.ERROR
        return
    end
    
    self.IntValue = self.Fields["IntValue"]
    
end

function XRestaurantCheckIntNode:OnEnter()
    local isEqual = self.AgentProxy:DoCheckInt(self.IntValue)

    if isEqual then
        self.Node.Status = CsNodeStatus.SUCCESS
    else
        self.Node.Status = CsNodeStatus.FAILED
    end
end