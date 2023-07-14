local XHomeFurnitureCheckPointerUpNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, "HomeFurnitureCheckPointerUp", CsBehaviorNodeType.Condition, true, false)

function XHomeFurnitureCheckPointerUpNode:OnGetEvents()
    return { XEventId.EVENT_DORM_FURNITURE_POINTER_UP_SUCCESS }
end

function XHomeFurnitureCheckPointerUpNode:OnEnter()
    self.Id = self.AgentProxy:GetId()
end

function XHomeFurnitureCheckPointerUpNode:OnNotify(evt, ...)
    local args = { ... }

    if evt == XEventId.EVENT_DORM_FURNITURE_POINTER_UP_SUCCESS and args[1] == self.Id then
        self.Node.Status = CsNodeStatus.SUCCESS
    end
end