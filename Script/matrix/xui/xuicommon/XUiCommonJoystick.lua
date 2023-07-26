local RectTransformUtility = CS.UnityEngine.RectTransformUtility
local Mathf = CS.UnityEngine.Mathf
local Vector2 = CS.UnityEngine.Vector2
local XUiCommonJoystick = XClass(nil, "XUiCommonJoystick")

function XUiCommonJoystick:Ctor(gameObject)
    self.GameObject = gameObject
    self.Transform = gameObject.transform
    XTool.InitUiObject(self)
    -- 遥杆范围
    self.JoystickTouchRange = 120
    -- 原始坐标
    self.OriginalPos = self.BackdragTouch.anchoredPosition
    -- 遥杆边缘
    self.JoystickEdge = self.Transform.sizeDelta * 0.5
    -- 是否触发中
    self.IsTrigger = false
    self.TriggerThresholdSqr = 0
    self.IsStart = false
    -- 注册事件
    self:_RegisterUiEvents()
    -- 移动方向更新方法
    self.UpdateMoveDirectionFunc = nil
end

function XUiCommonJoystick:SetData(updateMoveDirectionFunc)
    self.UpdateMoveDirectionFunc = updateMoveDirectionFunc
end

--######################## 私有方法 ########################

function XUiCommonJoystick:_RegisterUiEvents()
    -- 注册遥杆事件
    local uiWeight = self.JoystickScope.gameObject:AddComponent(typeof(CS.XUiWidget))
    uiWeight:AddPointerDownListener(function(eventData)
        self:_OnPointerDown(eventData)
    end)
    uiWeight:AddPointerUpListener(function(eventData)
        self:_OnPointerUp(eventData)
    end)
    uiWeight:AddDragListener(function(eventData)
        self:_OnDrag(eventData)
    end)
end

function XUiCommonJoystick:_TriggerCheck(position)
    if self.IsTrigger then return true end
    if position.sqrMagnitude / self.BackdragTouch.sizeDelta.sqrMagnitude * 4 
        > self.TriggerThresholdSqr then
        self.IsTrigger = true
        return true
    end
    return false
end

function XUiCommonJoystick:_OnPointerDown(eventData)
    local hasValue, position = RectTransformUtility.ScreenPointToLocalPointInRectangle(self.BackdragTouch
        , eventData.position
        , eventData.pressEventCamera)
    if not hasValue then return end
    if self:_TriggerCheck(position) then
        local direction = position.normalized
        self.TouchButton.anchoredPosition = direction * Mathf.Clamp(position.magnitude, 0, self.JoystickTouchRange)
        self.UpdateMoveDirectionFunc(direction)
    end
    self.IsStart = true
end

function XUiCommonJoystick:_OnPointerUp(eventData)
    self.BackdragTouch.anchoredPosition = self.OriginalPos
    self.TouchButton.anchoredPosition = Vector2.zero
    self.IsTrigger = false
    self.IsStart = false
    self.UpdateMoveDirectionFunc(Vector2.zero)
end

function XUiCommonJoystick:_OnDrag(eventData)
    if not self.IsStart then return end
    local hasValue, position = RectTransformUtility.ScreenPointToLocalPointInRectangle(self.BackdragTouch
        , eventData.position
        , eventData.pressEventCamera)
    if not hasValue then return end
    if self:_TriggerCheck(position) then
        local direction = position.normalized
        self.TouchButton.anchoredPosition = direction * Mathf.Clamp(position.magnitude, 0, self.JoystickTouchRange)
        self.UpdateMoveDirectionFunc(direction)
    end
end

return XUiCommonJoystick
