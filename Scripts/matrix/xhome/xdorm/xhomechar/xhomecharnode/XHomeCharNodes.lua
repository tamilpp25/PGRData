local XHomeCharCheckIsCanDestroy = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, "HomeCharCheckIsCanDestroy", CsBehaviorNodeType.Condition, true, false)

function XHomeCharCheckIsCanDestroy:OnEnter()
    self.EntityId = self.AgentProxy:GetEntityId()
end

function XHomeCharCheckIsCanDestroy:OnGetEvents()
    return { XEventId.EVENT_DORM_ROLE_CAN_DESTROY }
end

function XHomeCharCheckIsCanDestroy:OnNotify(evt, ...)
    local args = { ... }
    if evt == XEventId.EVENT_DORM_ROLE_CAN_DESTROY and args[1] == self.EntityId  then
        
        self.Node.Status = CsNodeStatus.SUCCESS
    end
end

local XHomeCharPlayAlphaAnim = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, "HomeCharPlayAlphaAnim", CsBehaviorNodeType.Action, true, false)

function XHomeCharPlayAlphaAnim:OnEnter()
    self.AgentProxy:PlayAlphaAnim(self.Fields["Alpha"], self.Fields["Time"], function()
        self.Node.Status = CsNodeStatus.SUCCESS    
    end)
end

local XHomeCharDestroy = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, "HomeCharDestroy", CsBehaviorNodeType.Action, true, false)

function XHomeCharDestroy:OnEnter()
    self.AgentProxy:Destroy()
end