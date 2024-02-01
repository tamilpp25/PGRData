local XGuideFilterTagEqual = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, "GuideFilterTagEqual", CsBehaviorNodeType.Condition, true, false)

function XGuideFilterTagEqual:OnAwake()
    if self.Fields == nil then
        self.Node.Status = CsNodeStatus.ERROR
        return
    end

    self.UiName = self.Fields["UiName"]
    self.FilterName = self.Fields["FilterName"]
    self.TagName = self.Fields["TagName"]
end

function XGuideFilterTagEqual:OnEnter()
    local filterTrans = self.AgentProxy:FindTargetFilter(self.UiName, self.FilterName).transform
    local filterProxy = XMVCA.XCommonCharacterFilter:GetFilterProxyByTransfrom(filterTrans)
    local curTagName = filterProxy:GetCurSelectTagName()
    local IsEqual = curTagName == self.TagName
    if IsEqual then
        self.Node.Status = CsNodeStatus.SUCCESS
    else
        self.Node.Status = CsNodeStatus.FAILED
    end
end

