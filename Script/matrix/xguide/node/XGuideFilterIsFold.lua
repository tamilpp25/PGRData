local XGuideFilterIsFold = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, "GuideFilterIsFold", CsBehaviorNodeType.Condition, true, false)

function XGuideFilterIsFold:OnAwake()
    if self.Fields == nil then
        self.Node.Status = CsNodeStatus.ERROR
        return
    end

    self.UiName = self.Fields["UiName"]
    self.FilterName = self.Fields["FilterName"]
end

function XGuideFilterIsFold:OnEnter()
    ---@type XCommonCharacterFiltAgency
    local ag = XMVCA:GetAgency(ModuleId.XCommonCharacterFilt)
    local filterTrans = self.AgentProxy:FindTargetFilter(self.UiName, self.FilterName).transform
    local filterProxy = ag:GetFilterProxyByTransfrom(filterTrans)
    local IsFold = filterProxy.IsFold
    if IsFold then
        self.Node.Status = CsNodeStatus.SUCCESS
    else
        self.Node.Status = CsNodeStatus.FAILED
    end
end

