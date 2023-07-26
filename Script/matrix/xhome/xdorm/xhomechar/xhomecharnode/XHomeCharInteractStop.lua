local XHomeCharInteractStop = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, "HomeCharInteractStop", CsBehaviorNodeType.Condition, true, false)


function XHomeCharInteractStop:OnGetEvents()
    return { XEventId.EVENT_DORM_INTERACT_STOP }
end

function XHomeCharInteractStop:OnEnter()
    self.PlayerId = self.AgentProxy:GetPlayerId()
end

function XHomeCharInteractStop:OnNotify(evt, ...)
    local args = { ... }

    if evt == XEventId.EVENT_DORM_INTERACT_STOP and args[1] == self.PlayerId then
        self.Node.Status = CsNodeStatus.SUCCESS
        if not XTool.UObjIsNil(self.Agent) then
            self.Agent:SetVarDicByKey("InteractStopSuccess", true)
        else
            XLog.Error("行为树节点HomeCharInteractStop Agent为nil PlayerId:" .. self.PlayerId)
        end
    end
end