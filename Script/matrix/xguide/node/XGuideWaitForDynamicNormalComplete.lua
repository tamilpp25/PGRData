
---@class XGuideWaitForDynamicNormalComplete : XLuaBehaviorNode
---@field AgentProxy XGuideAgent
local XGuideWaitForDynamicNormalComplete = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, "GuideWaitForDynamicNormalComplete", CsBehaviorNodeType.Action, true, false)

--索引动态列表
function XGuideWaitForDynamicNormalComplete:OnAwake()
    if self.Fields == nil then
        self.Node.Status = CsNodeStatus.ERROR
        return
    end

    self.UiName = self.Fields["UiName"]
    self.DynamicName = self.Fields["DynamicName"]
end

function XGuideWaitForDynamicNormalComplete:OnEnter()
    local trans = self.AgentProxy:FindTargetFilter(self.UiName, self.DynamicName).transform
    self.TargetGameObject = trans.gameObject
end

function XGuideWaitForDynamicNormalComplete:OnGetEvents()
    return { CS.XEventId.DYNAMIC_GRID_RELOAD_COMPLETED }
end

function XGuideWaitForDynamicNormalComplete:OnNotify(evt, ...)
    if evt == CS.XEventId.DYNAMIC_GRID_RELOAD_COMPLETED then
        local arg = {...}
        if arg[1] == self.TargetGameObject then
            self.Node.Status = CsNodeStatus.SUCCESS
        end
    end
end