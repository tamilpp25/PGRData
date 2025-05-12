---@class IsGameObjectActiveNode : XLuaBehaviorNode 检测节点是否显示
---@field UiName string Ui界面名称
---@field GameObject string 界面节点名称
local IsGameObjectActiveNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, "IsGameObjectActive", CsBehaviorNodeType.Condition, true, false)

function IsGameObjectActiveNode:OnAwake()
    if self.Fields == nil then
        self.Node.Status = CsNodeStatus.ERROR
        return
    end

    if self.Fields["UiName"] == nil then
        self.Node.Status = CsNodeStatus.ERROR
        return
    end

    self.UiName = self.Fields["UiName"]
    self.GameObject = self.Fields["GameObject"]
end

function IsGameObjectActiveNode:OnEnter()
    if self.AgentProxy:IsUiActive(self.UiName, self.GameObject) then
        self.Node.Status = CsNodeStatus.SUCCESS
    else
        self.Node.Status = CsNodeStatus.FAILED
    end
end
