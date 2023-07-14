local XHomeFurnitureSaveSuccessNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, "HomeFurnitureSaveSuccess", CsBehaviorNodeType.Condition, true, false)

function XHomeFurnitureSaveSuccessNode:OnGetEvents()
    return { XEventId.EVENT_DORM_FURNITURE_PUT_SUCCESS }
 end

 function XHomeFurnitureSaveSuccessNode:OnEnter()
     self.Id = self.AgentProxy:GetId()
 end

 function XHomeFurnitureSaveSuccessNode:OnNotify(evt,...)
     local args = {...}

     if evt == XEventId.EVENT_DORM_FURNITURE_PUT_SUCCESS and args[1] == self.Id then
        if args[2] then
            self.Node.Status = CsNodeStatus.SUCCESS
        else
            self.Node.Status = CsNodeStatus.FAILED
        end
     end
 end