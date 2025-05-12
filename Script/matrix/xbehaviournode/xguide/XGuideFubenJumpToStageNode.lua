---@class XGuideFubenJumpToStageNode : XLuaBehaviorNode 副本跳转
---@field AgentProxy XGuideAgent 引导代理
---@field StageId number 副本关卡id 
local XGuideFubenJumpToStageNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, "GuideFubenJumpToStage", CsBehaviorNodeType.Action, true, false)



--聚焦Ui
function XGuideFubenJumpToStageNode:OnAwake()
    if self.Fields == nil then
        self.Node.Status = CsNodeStatus.ERROR
        return
    end

    if self.Fields["StageId"] == nil then
        self.Node.Status = CsNodeStatus.ERROR
        return
    end

    self.StageId = self.Fields["StageId"]
end

function XGuideFubenJumpToStageNode:OnEnter()
    self.AgentProxy:FubenJumpToStage(self.StageId)
    self.Node.Status = CsNodeStatus.SUCCESS
end