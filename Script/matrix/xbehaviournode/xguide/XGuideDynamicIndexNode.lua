---@class XGuideDynamicIndexNode : XLuaBehaviorNode 索引动态列表（通用）
---@field AgentProxy XGuideAgent
---@field UiName string Ui名称
---@field DynamicName string Curve动态列表名称
---@field IndexKey string 索引的Key
---@field IndexValue string 索引的值
---@field FocusTransform string 聚焦的UI
---@field PassEvent boolean 是否向下传递事件
---@field SizeDelta UnityEngine.Vector2Int 聚焦框大小
---@field Offset UnityEngine.Vector2Int 聚焦框偏移量
---@field PassAll boolean 是否向所有子节点传递事件
local XGuideDynamicIndexNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, "GuideDynamicIndex", CsBehaviorNodeType.Action, true, false)

function XGuideDynamicIndexNode:InitNodeData()
    if not self.Node.Fields then
        self.Fields = nil
        return
    end

    self.Fields = {}

    local fields = self.Node.Fields.Fields

    for _, v in pairs(fields) do
        if v.FieldName == "SizeDelta" or v.FieldName == "Offset" then
            self.Fields[v.FieldName] = v
        else
            self.Fields[v.FieldName] = v.Value
        end
    end
end

--索引动态列表
function XGuideDynamicIndexNode:OnAwake()
    if self.Fields == nil then
        self.Node.Status = CsNodeStatus.ERROR
        return
    end

    if self.Fields["UiName"] == nil or self.Fields["DynamicName"] == nil or self.Fields["IndexValue"] == nil then
        self.Node.Status = CsNodeStatus.ERROR
        return
    end

    self.UiName = self.Fields["UiName"]
    self.DynamicName = self.Fields["DynamicName"]
    self.IndexValue = self.Fields["IndexValue"]
    self.IndexKey = self.Fields["IndexKey"]
    self.FocusTransform = self.Fields["FocusTransform"]
    self.PassEvent = self.Fields["PassEvent"]
    local sizeDelta = self.Fields["SizeDelta"]
    self.SizeDelta = CS.UnityEngine.Vector2(sizeDelta.X, sizeDelta.Y)
    local offset = self.Fields["Offset"]
    if not offset then
        self.Offset = CS.UnityEngine.Vector2.zero
    else
        self.Offset = CS.UnityEngine.Vector2(offset.X, offset.Y)
    end
    self.PassAll = self.Fields["PassAll"]
end

function XGuideDynamicIndexNode:OnEnter()
    self.AgentProxy:IndexDynamicTable(self.UiName, self.DynamicName, self.IndexKey, self.IndexValue, self.FocusTransform, self.PassEvent, self.SizeDelta, self.Offset, self.PassAll)
    self.AgentProxy:NodeBuryingPoint(self.Node.ID)
end

function XGuideDynamicIndexNode:OnGetEvents()
    return { CS.XEventId.EVENT_GUIDE_CLICK_BTNPASS }
end

function XGuideDynamicIndexNode:OnNotify(evt)

    if evt == CS.XEventId.EVENT_GUIDE_CLICK_BTNPASS then
        self.Node.Status = CsNodeStatus.SUCCESS
    end

end
