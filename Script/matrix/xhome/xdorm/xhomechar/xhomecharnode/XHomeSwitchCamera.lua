
local XHomeSwitchCamera = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, "HomeSwitchCamera", CsBehaviorNodeType.Action, true, false)

function XHomeSwitchCamera:OnEnter()
    self.AgentProxy:SwitchCamera(function()
        self.Node.Status = CsNodeStatus.SUCCESS
    end)
end


local XHomeResetCamera = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, "HomeResetCamera", CsBehaviorNodeType.Action, true, false)

function XHomeResetCamera:OnEnter()
    self.AgentProxy:ResetCamera(function()
        self.Node.Status = CsNodeStatus.SUCCESS
    end)
end
