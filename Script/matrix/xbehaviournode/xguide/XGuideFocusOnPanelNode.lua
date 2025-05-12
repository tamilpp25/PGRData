---@class XGuideFocusOnPanelNode : XLuaBehaviorNode 聚焦2DUi界面
---@field AgentProxy XGuideAgent
---@field UiName string Ui名称
---@field Transform string 聚焦节点名称
---@field AnyClick boolean 任意点击
---@field PassEvent boolean 是否向下传递事件
---@field EulerAngles UnityEngine.Vector3Int 聚焦框旋转角度
---@field SizeDelta UnityEngine.Vector2Int 聚焦框大小（0，0）时采用聚焦物体默认大小
---@field Offset UnityEngine.Vector2Int 聚焦框偏移量
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
    self.AgentProxy:NodeBuryingPoint(self.Node.ID)
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