local XGuildDormCheckTimeNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, "GuildDormCheckTime", CsBehaviorNodeType.Condition, true, false)

function XGuildDormCheckTimeNode:OnAwake()
    if self.Fields == nil or self.Fields["StartTime"] == nil or self.Fields["EndTime"] == nil then
        self.Node.Status = CsNodeStatus.ERROR
        return
    end
    
    local H = 3600
    self.StartTimestamp = self.Fields["StartTime"] * H
    self.EndTimestamp = self.Fields["EndTime"] * H
end

function XGuildDormCheckTimeNode:OnEnter()
    local currentTimestamp = XTime.GetServerNowTimestamp() - XTime.GetTodayTime()
    if currentTimestamp >= self.StartTimestamp and currentTimestamp < self.EndTimestamp then
        self.Node.Status = CsNodeStatus.SUCCESS
    else
        self.Node.Status = CsNodeStatus.FAILED
    end
end