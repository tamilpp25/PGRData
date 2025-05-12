---@class XGuideFocusOnChildNode : XLuaBehaviorNode 聚焦子节点
---@field AgentProxy XGuideAgent 引导代理
---@field UiName string Ui名称
---@field Parent string 父节点名称
---@field Index number 子节点下标
---@field AnyClick boolean 任意点击
---@field PassEvent boolean 是否向下传递事件
---@field EulerAngles UnityEngine.Vector3Int 聚焦框旋转角度
---@field SizeDelta UnityEngine.Vector2Int 聚焦框大小（0，0）时采用聚焦物体默认大小
---@field Offset UnityEngine.Vector2Int 聚焦框偏移量
---@field ChildName string 可选参数如果配置了则再往下一层查找 可以配置名称或者相对路径
local XGuideFocusOnChildNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, "GuideFocusOnChild", CsBehaviorNodeType.Action, true, false)

--初始化数据
function XGuideFocusOnChildNode:InitNodeData()

    if not self.Node.Fields then
        self.Fields = nil
        return
    end

    self.Fields = {}

    local fields = self.Node.Fields.Fields
    
    for _, v in pairs(fields) do
        if v.FieldName == "EulerAngles" 
                or v.FieldName == "SizeDelta" 
                or v.FieldName == "Offset" then
            self.Fields[v.FieldName] = v
        else
            self.Fields[v.FieldName] = v.Value
        end
    end
end


--聚焦Ui
function XGuideFocusOnChildNode:OnAwake()
    if self.Fields == nil then
        self.Node.Status = CsNodeStatus.ERROR
        return
    end

    if self.Fields["UiName"] == nil or self.Fields["Parent"] == nil then
        self.Node.Status = CsNodeStatus.ERROR
        return
    end

    self.UiName = self.Fields["UiName"]
    self.Parent = self.Fields["Parent"]
    self.Index = self.Fields["Index"]
    self.AnyClick = self.Fields["AnyClick"]
    self.ChildName = self.Fields["ChildName"]


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

function XGuideFocusOnChildNode:OnEnter()
    self.AgentProxy:FocusOnChild(self.UiName, self.Parent, self.Index, self.EulerAngles, self.PassEvent, 
            self.SizeDelta, self.Offset, self.ChildName)
    self.AgentProxy:NodeBuryingPoint(self.Node.ID)
end

function XGuideFocusOnChildNode:OnGetEvents()
    return { CS.XEventId.EVENT_GUIDE_CLICK_BTNPASS, CS.XEventId.EVENT_GUIDE_ANYCLICK }
end

function XGuideFocusOnChildNode:OnNotify(evt)

    if evt == CS.XEventId.EVENT_GUIDE_CLICK_BTNPASS then
        self.Node.Status = CsNodeStatus.SUCCESS
    elseif self.AnyClick and evt == CS.XEventId.EVENT_GUIDE_ANYCLICK then
        self.Node.Status = CsNodeStatus.SUCCESS
    end

end