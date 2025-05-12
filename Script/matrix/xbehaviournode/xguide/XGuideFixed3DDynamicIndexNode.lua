---@class XGuideFixed3DDynamicIndexNode : XLuaBehaviorNode 聚焦动态列表（3D）
---@field AgentProxy XGuideAgent
---@field SceneRoot string 3D根节点
---@field Camera string 渲染相机路径
---@field DynamicName string 动态列表相对路径
---@field IndexKey string 索引的Key
---@field IndexValue string 索引的值
---@field PassEvent boolean 是否向下传递事件
---@field AnyClick boolean 任意点击
---@field SizeDelta UnityEngine.Vector2Int 聚焦框大小
---@field Offset UnityEngine.Vector2Int 聚焦框偏移量
local XGuideFixed3DDynamicIndexNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, "GuideFixed3DDynamicIndex", CsBehaviorNodeType.Action, true, false)

function XGuideFixed3DDynamicIndexNode:InitNodeData()
    if not self.Node.Fields then
        self.Fields = nil
        return
    end

    self.Fields = {}

    local fields = self.Node.Fields.Fields

    for _, v in pairs(fields) do
        if v.FieldName == "SizeDelta" then
            self.Fields[v.FieldName] = v
        else
            self.Fields[v.FieldName] = v.Value
        end
    end
end

--索引动态列表
function XGuideFixed3DDynamicIndexNode:OnAwake()
    if self.Fields == nil then
        self.Node.Status = CsNodeStatus.ERROR
        return
    end

    self.SceneRoot = self.Fields["SceneRoot"]
    self.Camera = self.Fields["Camera"]
    self.DynamicName = self.Fields["DynamicName"]
    self.IndexValue = self.Fields["IndexValue"]
    self.IndexKey = self.Fields["IndexKey"]
    self.PassEvent = self.Fields["PassEvent"]
    local sizeDelta = self.Fields["SizeDelta"]
    if not sizeDelta then
        self.SizeDelta = CS.UnityEngine.Vector2.zero
    else
        self.SizeDelta = CS.UnityEngine.Vector2(sizeDelta.X, sizeDelta.Y)
    end
    self.AnyClick = self.Fields["AnyClick"]
    self.Offset = self.Fields["Offset"]
end

function XGuideFixed3DDynamicIndexNode:OnEnter()
    self.AgentProxy:Index3DFixedDynamicTable(self.SceneRoot, self.Camera, self.DynamicName, self.IndexKey, self.IndexValue, self.PassEvent, self.SizeDelta, self.Offset)
    self.AgentProxy:NodeBuryingPoint(self.Node.ID)
end

function XGuideFixed3DDynamicIndexNode:OnGetEvents()
    return { CS.XEventId.EVENT_GUIDE_CLICK_BTNPASS, CS.XEventId.EVENT_GUIDE_ANYCLICK }
end

function XGuideFixed3DDynamicIndexNode:OnNotify(evt)
    if evt == CS.XEventId.EVENT_GUIDE_CLICK_BTNPASS then
        self.Node.Status = CsNodeStatus.SUCCESS
    elseif self.AnyClick and evt == CS.XEventId.EVENT_GUIDE_ANYCLICK then
        self.Node.Status = CsNodeStatus.SUCCESS
    end
end