local XGuildDormSetCameraParamNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, "GuildDormSetCameraParam", CsBehaviorNodeType.Action, true, false)

function XGuildDormSetCameraParamNode:OnAwake()
    if self.Fields == nil or self.Fields["Distance"] == nil then
        self.Node.Status = CsNodeStatus.ERROR
        return  
    end
end

function XGuildDormSetCameraParamNode:OnEnter()
    self.AgentProxy:SetCameraParam(self.Fields["Distance"])
    self.Node.Status = CsNodeStatus.SUCCESS
end

local XGuildDormResetCameraParamNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, "GuildDormResetCameraParam", CsBehaviorNodeType.Action, true, false)

function XGuildDormResetCameraParamNode:OnEnter()
    self.AgentProxy:ResetCameraParam()
    self.Node.Status = CsNodeStatus.SUCCESS
end