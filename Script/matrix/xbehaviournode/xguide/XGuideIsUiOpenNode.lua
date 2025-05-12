---@class XGuideIsUiOpenNode : XLuaBehaviorNode Ui界面是否打开
---@field UiName string 界面名称
---@field RequireOnTop boolean 界面是否需要置顶
local XGuideIsUiOpenNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, "IsUiOpen", CsBehaviorNodeType.Condition, true, false)

function XGuideIsUiOpenNode:OnAwake()
    if self.Fields == nil then
        self.Node.Status = CsNodeStatus.ERROR
        return
    end

    if self.Fields["UiName"] == nil then
        self.Node.Status = CsNodeStatus.ERROR
        return
    end

    self.UiName = self.Fields["UiName"]
    self.RequireOnTop = self.Fields["RequireOnTop"]
end

function XGuideIsUiOpenNode:OnEnter()
    if self.AgentProxy:IsUiShowAndOnTop(self.UiName, self.RequireOnTop) then
        self.Node.Status = CsNodeStatus.SUCCESS
    else
        self.Node.Status = CsNodeStatus.FAILED
    end
end
