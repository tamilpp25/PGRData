---@class XGuideFocusOnScrollRectNode : XLuaBehaviorNode 滚动列表节点锁定
---@field AgentProxy XGuideAgent 引导代理
---@field UiName string Ui名称
---@field ScrollRect string 滚动列表名称
---@field TargetName string 锁定节点名称
local XGuideFocusOnScrollRectNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, "GuideFocusOnScrollRect", CsBehaviorNodeType.Action, true, false)


--聚焦Ui
function XGuideFocusOnScrollRectNode:OnAwake()
    if self.Fields == nil then
        self.Node.Status = CsNodeStatus.ERROR
        return
    end

    self.UiName = self.Fields["UiName"]
    self.TargetName = self.Fields["TargetName"]
    self.ScrollRect = self.Fields["ScrollRect"]
end

function XGuideFocusOnScrollRectNode:OnEnter()
    if self.AgentProxy:FocuOnScrollRect(self.UiName, self.ScrollRect, self.TargetName) then
        self.Node.Status = CsNodeStatus.SUCCESS
    else
        self.Node.Status = CsNodeStatus.FAILED
    end
end