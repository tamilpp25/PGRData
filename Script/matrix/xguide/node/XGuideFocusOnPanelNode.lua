---@class XGuideFocusOnPanelNode : XLuaBehaviorNode
---@field AgentProxy XGuideAgent
local XGuideFocusOnPanelNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, "GuideFocusOn", CsBehaviorNodeType.Action, true, false)

--初始化数据
function XGuideFocusOnPanelNode:InitNodeData()

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


--聚焦Ui
function XGuideFocusOnPanelNode:OnAwake()
    if self.Fields == nil then
        self.Node.Status = CsNodeStatus.ERROR
        return
    end

    if self.Fields["UiName"] == nil or self.Fields["Transform"] == nil then
        self.Node.Status = CsNodeStatus.ERROR
        return
    end

    self.UiName = self.Fields["UiName"]
    self.Transform = self.Fields["Transform"]
    self.AnyClick = self.Fields["AnyClick"]


    local eulerAngles = self.Fields["EulerAngles"]
    self.EulerAngles = CS.UnityEngine.Vector3(eulerAngles.X, eulerAngles.Y, eulerAngles.Z)
    self.PassEvent = self.Fields["PassEvent"]
    local sizeDelta = self.Fields["SizeDelta"]
    self.SizeDelta = CS.UnityEngine.Vector2(sizeDelta.X, sizeDelta.Y)
    local offset = self.Fields["Offset"]
    if not offset then
        self.Offset = CS.UnityEngine.Vector2.zero
    else
        self.Offset = CS.UnityEngine.Vector2(offset.X, offset.Y)
    end
end

function XGuideFocusOnPanelNode:OnEnter()
    self.AgentProxy:FocusOn(self.UiName, self.Transform, self.EulerAngles, self.PassEvent, self.SizeDelta, self.Offset)

end

function XGuideFocusOnPanelNode:OnGetEvents()
    return { CS.XEventId.EVENT_GUIDE_CLICK_BTNPASS, CS.XEventId.EVENT_GUIDE_ANYCLICK }
end

function XGuideFocusOnPanelNode:OnNotify(evt)

    if evt == CS.XEventId.EVENT_GUIDE_CLICK_BTNPASS then
        self.Node.Status = CsNodeStatus.SUCCESS
    elseif self.AnyClick and evt == CS.XEventId.EVENT_GUIDE_ANYCLICK then
        self.Node.Status = CsNodeStatus.SUCCESS
    end

end