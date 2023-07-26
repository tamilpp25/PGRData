
---@class XRestaurantDoActionIndexOnlyNode : XLuaBehaviorNode
---@field AgentProxy XRestaurantCharAgent
local XRestaurantDoActionIndexOnlyNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode,
        "RestaurantDoActionIndexOnly", CsBehaviorNodeType.Action, true, false)

function XRestaurantDoActionIndexOnlyNode:OnAwake()
    if self.Fields == nil then
        self.Node.Status = CsNodeStatus.ERROR
        return
    end

    if self.Fields["Index"] == nil or self.Fields["NeedFadeCross"] == nil or self.Fields["CrossDuration"] == nil then
        self.Node.Status = CsNodeStatus.ERROR
        return
    end
    
    self.Index = self.Fields["Index"]
    self.NeedFadeCross = self.Fields["NeedFadeCross"]
    self.CrossDuration = self.Fields["CrossDuration"]
    
end

function XRestaurantDoActionIndexOnlyNode:OnEnter()
    self.AgentProxy:DoActionIndex(self.Index, self.NeedFadeCross, self.CrossDuration)
    self.Node.Status = CsNodeStatus.SUCCESS
end