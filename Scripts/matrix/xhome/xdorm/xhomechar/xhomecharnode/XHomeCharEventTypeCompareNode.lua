local XHomeCharEventTypeCompareNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, "HomeCharEventTypeCompare", CsBehaviorNodeType.Condition, true, false)

function XHomeCharEventTypeCompareNode:OnAwake()
    if self.Fields == nil then
        self.Node.Status = CsNodeStatus.ERROR
        return
    end

    if self.Fields["EventType"] == nil then
        self.Node.Status = CsNodeStatus.ERROR
        return
    end

    self.EventType = self.Fields["EventType"]
end


function XHomeCharEventTypeCompareNode:OnEnter()
    local result = self.AgentProxy:CheckEventCompleted(self.EventType, function(isFailed)
        if not isFailed then
            self.Node.Status = CsNodeStatus.SUCCESS
        else
            self.Node.Status = CsNodeStatus.FAILED
        end
    end)

    if not result then
        self.Node.Status = CsNodeStatus.FAILED
    end
end