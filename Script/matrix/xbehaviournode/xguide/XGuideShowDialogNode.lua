---@class XGuideShowDialogNode : XLuaBehaviorNode 显示引导对话框
---@field AgentProxy XGuideAgent 引导代理
---@field Image string 头像资源路径
---@field Name string 昵称
---@field Content string 对话内容
---@field Pos number 对话框显示位置:0-左上角;1-右上角;2-自定义
---@field UiName string 界面名称，停靠位置为自定义时必填
---@field GridName string 界面节点名称，停靠位置为自定义时必填
---@field Position UnityEngine.Vector2Int 相对节点位置，停靠位置为自定义时必填
local XGuideShowDialogNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, "GuideShowDialog", CsBehaviorNodeType.Action, true, false)

function XGuideShowDialogNode:InitNodeData()
    if not self.Node.Fields then
        self.Fields = nil
        return
    end

    self.Fields = {}

    local fields = self.Node.Fields.Fields

    for _, v in pairs(fields) do
        if v.FieldName == "Position" then
            self.Fields[v.FieldName] = v
        else
            self.Fields[v.FieldName] = v.Value
        end
    end
end

--显示对话头像
function XGuideShowDialogNode:OnAwake()
    if self.Fields == nil then
        self.Node.Status = CsNodeStatus.ERROR
        return
    end

    if self.Fields["Image"] == nil or self.Fields["Name"] == nil or self.Fields["Content"] == nil then
        self.Node.Status = CsNodeStatus.ERROR
        return
    end

    self.ImageString = self.Fields["Image"]
    self.RoleName = self.Fields["Name"]
    self.Content = self.Fields["Content"]
    self.Pos = self.Fields["Pos"]
    self.UiName = self.Fields["UiName"]
    self.GridName = self.Fields["GridName"]
    local position = self.Fields["Position"]
    self.Position = CS.UnityEngine.Vector2(position.X, position.Y)
end

function XGuideShowDialogNode:OnEnter()
    self.AgentProxy:ShowDialog(self.ImageString, self.RoleName, self.Content, self.Pos, self.UiName, self.GridName, self.Position)
    self.Node.Status = CsNodeStatus.SUCCESS
end