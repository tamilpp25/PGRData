
---@class XRestaurantGetActionIdNode : XLuaBehaviorNode
---@field AgentProxy XRestaurantCharAgent
local XRestaurantGetActionIdNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode,
        "RestaurantGetActionId", CsBehaviorNodeType.Action, true, false)

function XRestaurantGetActionIdNode:OnAwake()
    if self.Fields == nil then
        self.Node.Status = CsNodeStatus.ERROR
        return
    end

    if self.Fields["Index"] == nil then
        self.Node.Status = CsNodeStatus.ERROR
        return
    end

    self.Index = self.Fields["Index"]
end

function XRestaurantGetActionIdNode:OnEnter()
    self.AgentProxy:DoGetActionId(self.Index)
    self.Node.Status = CsNodeStatus.SUCCESS
end