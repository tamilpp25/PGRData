---@class XGuideHideDialogNode : XLuaBehaviorNode 隐藏引导对话框
local XGuideHideDialogNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, "GuideHideDialog",CsBehaviorNodeType.Action,true,false)
--隐藏对话头像
function XGuideHideDialogNode:OnEnter()
    self.AgentProxy:HideDialog()
    self.Node.Status = CsNodeStatus.SUCCESS
end

