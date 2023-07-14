
---@class XRestaurantDoActionIndexNode : XLuaBehaviorNode
---@field AgentProxy XRestaurantCharAgent
local XRestaurantDoActionIndexNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode,
        "RestaurantDoActionIndex", CsBehaviorNodeType.Action, true, true)

function XRestaurantDoActionIndexNode:OnAwake()
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
    self.NeedReplaySameAnimation = self.Fields["NeedReplaySameAnimation"]
    self.Duration = 0;
    self.RunningTime = 0;
 
end

function XRestaurantDoActionIndexNode:OnEnter()
    if not self.AgentProxy:CheckPlayRepeat(self.Index, self.NeedReplaySameAnimation) then
        self.Node.Status = CsNodeStatus.SUCCESS
        return
    end
    self.RunningTime = 0
    self.Duration = self.AgentProxy:GetActionDuration(self.Index)
    self.AgentProxy:DoActionIndex(self.Index, self.NeedFadeCross, self.CrossDuration)
end

function XRestaurantDoActionIndexNode:OnUpdate(dt)
    self.RunningTime = self.RunningTime + dt
    if self.RunningTime >= self.Duration then
        self.Node.Status = CsNodeStatus.SUCCESS
    end
end

function XRestaurantDoActionIndexNode:OnReset()
    self.RunningTime = 0
end