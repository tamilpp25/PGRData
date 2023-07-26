local XGuideShowMaskNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, "GuideIsBlockRayCast", CsBehaviorNodeType.Action, true, false)
--显示对话头像
function XGuideShowMaskNode:OnAwake()


    if self.Fields == nil then
        self.Node.Status = CsNodeStatus.ERROR
        return
    end


    if self.Fields["IsShowMask"] == nil or self.Fields["IsBlockRayCast"] == nil then
        self.Node.Status = CsNodeStatus.ERROR
        return
    end

    self.IsShowMask = self.Fields["IsShowMask"]
    self.IsBlockRayCast = self.Fields["IsBlockRayCast"]
end

function XGuideShowMaskNode:OnEnter()
    self.AgentProxy:ShowMaskNew(self.IsShowMask, self.IsBlockRayCast)
    self.Node.Status = CsNodeStatus.SUCCESS
end