local XHomeCharCancelInteractBtnShow = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, "HomeCharCancelInteractBtnShow", CsBehaviorNodeType.Action, true, false)

function XHomeCharCancelInteractBtnShow:OnEnter()
    XEventManager.DispatchEvent(XEventId.EVENT_GUILD_DORM_CANCEL_INTERACT_BTN_SHOW, true, self.AgentProxy:GetPlayerId())
    self.Node.Status = CsNodeStatus.SUCCESS
end