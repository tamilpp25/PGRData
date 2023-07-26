---@class XGuideFocusOn3DNode : XLuaBehaviorNode
---@field AgentProxy XGuideAgent
local XGuideFocusOn3DNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, "GuideFocusOn3D", CsBehaviorNodeType.Action, true, false)

function XGuideFocusOn3DNode:InitNodeData()

    if not self.Node.Fields then
        self.Fields = nil
        return
    end

    self.Fields = {}

    local fields = self.Node.Fields.Fields

    for _, v in pairs(fields) do
        if v.FieldName == "EulerAngles" or v.FieldName == "SizeDelta" or v.FieldName == "Offset" then
            self.Fields[v.FieldName] = v
        else
            self.Fields[v.FieldName] = v.Value
        end
    end
end

function XGuideFocusOn3DNode:OnAwake()
    if self.Fields == nil then
        self.Node.Status = CsNodeStatus.ERROR
        return
    end

    if self.Fields["SceneRoot"] == nil or self.Fields["Transform"] == nil or self.Fields["Camera"] == nil then
        self.Node.Status = CsNodeStatus.ERROR
        return
    end
    local eulerAngles = self.Fields["EulerAngles"]
    self.EulerAngles = CS.UnityEngine.Vector3(eulerAngles.X, eulerAngles.Y, eulerAngles.Z)
    local sizeDelta = self.Fields["SizeDelta"]
    self.SizeDelta = CS.UnityEngine.Vector2(sizeDelta.X, sizeDelta.Y)
    local offset = self.Fields["Offset"]
    self.Offset = CS.UnityEngine.Vector3(offset.X, offset.Y, offset.Z)
    
    self.Transform = self.Fields["Transform"]
    self.AnyClick = self.Fields["AnyClick"]
    self.Camera = self.Fields["Camera"]
    self.SceneRoot = self.Fields["SceneRoot"]
    self.PassEvent = self.Fields["PassEvent"]
end

function XGuideFocusOn3DNode:OnEnter()
    self.AgentProxy:FocusOn3D(self.SceneRoot, self.Camera, self.Transform, self.EulerAngles, self.PassEvent, self.Offset, self.SizeDelta)
end

function XGuideFocusOn3DNode:OnGetEvents()
    return { CS.XEventId.EVENT_GUIDE_CLICK_BTNPASS, CS.XEventId.EVENT_GUIDE_ANYCLICK }
end 

function XGuideFocusOn3DNode:OnNotify(evt)

    if evt == CS.XEventId.EVENT_GUIDE_CLICK_BTNPASS then
        self.Node.Status = CsNodeStatus.SUCCESS
    elseif self.AnyClick and evt == CS.XEventId.EVENT_GUIDE_ANYCLICK then
        self.Node.Status = CsNodeStatus.SUCCESS
    end
end