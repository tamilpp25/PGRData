---@class XUiFightCaptureV217PanelJoystick : XUiNode 遥感
---@field Parent XUiFightCaptureV217
---@field _Control XFightCaptureV217Control
local XUiPanelJoystick = XClass(XUiNode, "XUiPanelJoystick")
local CsClamp01 = CS.UnityEngine.Mathf.Clamp01
local JoystickTouchRange = CS.XFight.ClientConfig:GetInt("JoystickTouchRange")

local ArrowObjNameEnum = {
    "Up",
    "Left",
    "Down",
    "Right"
}
--触发遥感的最小值
local DIRECTION_MIN = 0.1

function XUiPanelJoystick:OnStart()
    XTool.InitUiObject(self)
    local uiWeight = self.GameObject:AddComponent(typeof(CS.XUiWidget))
    uiWeight:AddDragListener(function(eventData)
        self:OnDown(eventData)
    end)
    uiWeight:AddPointerDownListener(function(eventData)
        self:OnDown(eventData)
    end)
    uiWeight:AddPointerUpListener(function(eventData)
        self:OnPointerUp(eventData)
    end)
end

function XUiPanelJoystick:OnDown(eventData)
    local _, localPoint = CS.UnityEngine.RectTransformUtility.ScreenPointToLocalPointInRectangle(self.BackdragTouch, eventData.position, CS.XUiManager.Instance.UiCamera)
    local direction = localPoint.normalized 
    local moveNormalizedDist = CsClamp01(localPoint.magnitude / JoystickTouchRange)
    direction.x = math.abs(direction.x) > DIRECTION_MIN and direction.x or 0
    direction.y = math.abs(direction.y) > DIRECTION_MIN and direction.y or 0
    self.Parent.CameraController:SetMoveVec(direction, moveNormalizedDist)
    self:RefreshArrowState(direction)
end

function XUiPanelJoystick:OnPointerUp(eventData)
    self.Parent.CameraController:SetMoveVec(Vector2.zero, 0)
    self:RefreshArrowState(Vector2.zero)
end

-- 设置箭头图标状态
---@param direction --Vector2 方向
function XUiPanelJoystick:RefreshArrowState(direction)
    local obj
    local isShowNormal
    for i = 1, 4 do
        isShowNormal = (direction == Vector2.zero) or
                (i == 1 and direction.y < DIRECTION_MIN) or
                (i == 2 and direction.x > -DIRECTION_MIN) or
                (i == 3 and direction.y > -DIRECTION_MIN) or
                (i == 4 and direction.x < DIRECTION_MIN)
        
        obj = self[ArrowObjNameEnum[i]]
        obj:FindTransform("Normal").gameObject:SetActiveEx(isShowNormal)
        obj:FindTransform("Press").gameObject:SetActiveEx(not isShowNormal)
    end
end

return XUiPanelJoystick