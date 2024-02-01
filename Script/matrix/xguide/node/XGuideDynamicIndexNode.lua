---@class XGuideDynamicIndexNode : XLuaBehaviorNode
---@field AgentProxy XGuideAgent
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

---@class XGuideCurveDynamicIndexNode : XLuaBehaviorNode
---@field AgentProxy XGuideAgent
local XGuideCurveDynamicIndexNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, "GuideCurveDynamicIndex", CsBehaviorNodeType.Action, true, false)

function XGuideCurveDynamicIndexNode:InitNodeData()
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
function XGuideCurveDynamicIndexNode:OnAwake()
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
    if not sizeDelta then
        self.SizeDelta = CS.UnityEngine.Vector2.zero
    else
        self.SizeDelta = CS.UnityEngine.Vector2(sizeDelta.X, sizeDelta.Y)
    end

    local offset = self.Fields["Offset"]
    if not offset then
        self.Offset = CS.UnityEngine.Vector2.zero
    else
        self.Offset = CS.UnityEngine.Vector2(offset.X, offset.Y)
    end
    self.PassAll = self.Fields["PassAll"]
end

function XGuideCurveDynamicIndexNode:OnEnter()
    self.AgentProxy:IndexCurveDynamicTable(self.UiName, self.DynamicName, self.IndexKey, self.IndexValue, self.FocusTransform, self.PassEvent, self.SizeDelta)
    self.AgentProxy:NodeBuryingPoint(self.Node.ID)
end

function XGuideCurveDynamicIndexNode:OnGetEvents()
    return { CS.XEventId.EVENT_GUIDE_CLICK_BTNPASS }
end

function XGuideCurveDynamicIndexNode:OnNotify(evt)
    if evt == CS.XEventId.EVENT_GUIDE_CLICK_BTNPASS then
        self.Node.Status = CsNodeStatus.SUCCESS
    end
end


--- 3D动态列表
---@class XGuideFixed3DDynamicIndexNode : XLuaBehaviorNode
---@field AgentProxy XGuideAgent
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
