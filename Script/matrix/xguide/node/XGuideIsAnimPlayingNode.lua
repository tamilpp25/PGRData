
---@class XGuideIsAnimPlayingNode : XLuaBehaviorNode
---@field AgentProxy XGuideAgent
local XGuideIsAnimPlayingNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, "IsAnimPlaying", CsBehaviorNodeType.Condition, true, false)

function XGuideIsAnimPlayingNode:OnAwake()
    if self.Fields == nil then
        self.Node.Status = CsNodeStatus.ERROR
        return
    end

    if self.Fields["UiName"] == nil or self.Fields["AnimName"] == nil then
        self.Node.Status = CsNodeStatus.ERROR
        return
    end
    
    self.UiName = self.Fields["UiName"]
    self.AnimName = self.Fields["AnimName"]
end

function XGuideIsAnimPlayingNode:OnEnter()
    local status = self.AgentProxy:CheckAnimIsPlaying(self.UiName, self.AnimName) 
            and CsNodeStatus.SUCCESS or CsNodeStatus.FAILED
    self.Node.Status = status
end