---@class XGuideFilterIsFold : XLuaBehaviorNode 编队界面筛选器是否展开
---@field UiName string 编队界面Ui名
---@field FilterName string 筛选器物体名
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
    ---@type XCommonCharacterFilterAgency
    local ag = XMVCA:GetAgency(ModuleId.XCommonCharacterFilter)
    local filterTrans = self.AgentProxy:FindTargetFilter(self.UiName, self.FilterName).transform
    local filterProxy = ag:GetFilterProxyByTransfrom(filterTrans)
    local IsFold = filterProxy.IsFold
    if IsFold then
        self.Node.Status = CsNodeStatus.SUCCESS
    else
        self.Node.Status = CsNodeStatus.FAILED
    end
end

