local XGuideEndNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, "GuideEnd",CsBehaviorNodeType.Action,true,false)

function XGuideEndNode:OnStart()
    self.GuideId = self.BehaviorTree:GetLocalField("GuideId").Value
end

function XGuideEndNode:OnEnter()
    self.Node.Status = CsNodeStatus.SUCCESS
    CsXGameEventManager.Instance:Notify(XEventId.EVENT_GUIDE_END, self.GuideId)
end

