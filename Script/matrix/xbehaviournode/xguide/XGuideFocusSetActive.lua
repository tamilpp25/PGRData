---@class XGuideFocusSetActive : XLuaBehaviorNode 节点显隐
---@field AgentProxy XGuideAgent 引导代理
---@field UiName string Ui名称
---@field GameObject string 节点名称
---@field Active boolean 是否显示
local XGuideFocusSetActive = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, "SetActive", CsBehaviorNodeType.Action, true, false)

--节点显隐的条件
function XGuideFocusSetActive:OnAwake()
    if self.Fields == nil then
        self.Node.Status = CsNodeStatus.ERROR
        return
    end

    self.UiName = self.Fields["UiName"]
    self.GameObject = self.Fields["GameObject"]
    self.Active = self.Fields["Active"]
end

function XGuideFocusSetActive:OnEnter()
    local ts = self.AgentProxy:FindTransformInUi(self.UiName, self.GameObject)
    ts.gameObject:SetActiveEx(self.Active)
    
    self.Node.Status = CsNodeStatus.SUCCESS
end
