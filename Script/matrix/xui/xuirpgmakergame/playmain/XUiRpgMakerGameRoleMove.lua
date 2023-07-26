local XUiRpgMakerGameRoleMove = XClass(XLuaBehaviour, "XUiRpgMakerGameRoleMove")

local Platform = CS.UnityEngine.Application.platform
local RuntimePlatform = CS.UnityEngine.RuntimePlatform
local Input = CS.UnityEngine.Input
local EventSystemCurrent = CS.UnityEngine.EventSystems.EventSystem.current
local Vector3 = CS.UnityEngine.Vector3

--拖拽类型
local DragTouchPhase = {
    None = 0,
    BeginDrag = 1,
    OnDrag = 2,
    EndDrag = 3
}

--手指点击类型
local TouchPhase = {
    Began = CS.UnityEngine.TouchPhase.Began,
    Moved = CS.UnityEngine.TouchPhase.Moved,
    Stationary = CS.UnityEngine.TouchPhase.Stationary,
    Ended = CS.UnityEngine.TouchPhase.Ended,
    Canceled = CS.UnityEngine.TouchPhase.Canceled
}

--控制角色移动
function XUiRpgMakerGameRoleMove:Ctor(uiRoot, ui, beginDragCb, onDragCb, endDragCb)
    self.BeginDragCb = beginDragCb
    self.OnDragCb = onDragCb
    self.EndDragCb = endDragCb

    self.TouchType = DragTouchPhase.None
    self.TouchPosition = CS.UnityEngine.Vector3.zero
    self.OldVector = CS.UnityEngine.Vector3.zero
    self.IsLockByUi = false     --触碰到UI锁定
    self.IsIgnoreUi = false     --点击场景对象时，忽略触碰到事件对象上
end

function XUiRpgMakerGameRoleMove:Update()
    if XTool.UObjIsNil(self.Transform) or not self.GameObject.activeSelf then
        return
    end

    if (Input.GetMouseButtonDown(0) or (Input.touchCount > 0 and Input.GetTouch(0).phase == TouchPhase.Began)) then
        if Platform == RuntimePlatform.WindowsEditor or Platform == RuntimePlatform.WindowsPlayer then
            self.IsLockByUi = EventSystemCurrent and EventSystemCurrent:IsPointerOverGameObject()
        else
            self.IsLockByUi = EventSystemCurrent and EventSystemCurrent:IsPointerOverGameObject(Input.GetTouch(0).fingerId)
        end
    end

    if (Input.GetMouseButtonUp(0) or (Input.touchCount > 0 and Input.GetTouch(0).phase == TouchPhase.Ended)) then
        self.IsLockByUi = false
    end

    if not self.IsIgnoreUi and self.IsLockByUi then
        return
    end

    self:UpdateOp()
end

function XUiRpgMakerGameRoleMove:UpdateOp()
    if Platform == RuntimePlatform.WindowsEditor or Platform == RuntimePlatform.WindowsPlayer then
        self:PCUpdate()
    else
        self:PhoneUpdate()
    end
end

function XUiRpgMakerGameRoleMove:PCUpdate()
    if DragTouchPhase.EndDrag == self.TouchType then
        self.TouchType = DragTouchPhase.None
    end

    if DragTouchPhase.BeginDrag == self.TouchType then
        self.TouchType = DragTouchPhase.OnDrag
    end

    if Input.GetMouseButtonDown(0) then
        self.TouchType = DragTouchPhase.BeginDrag
        self.TouchPosition = Input.mousePosition
    end

    if DragTouchPhase.OnDrag == self.TouchType then
        self.TouchPosition = Input.mousePosition
    end

    if Input.GetMouseButtonUp(0) then
        self.TouchType = DragTouchPhase.EndDrag
        self.TouchPosition = Input.mousePosition
    end

    self:UpdateSinglePointerDrag()
end

function XUiRpgMakerGameRoleMove:PhoneUpdate()
    if Input.touchCount <= 0 then
        return
    end

    local touch = Input.GetTouch(0)
    if touch.phase == TouchPhase.Began then
        self.TouchType = DragTouchPhase.BeginDrag
        self.TouchPosition = Vector3(touch.position.x, touch.position.y, 0)
    end

    if touch.phase == TouchPhase.Moved then
        self.TouchType = DragTouchPhase.OnDrag
        self.TouchPosition = Vector3(touch.position.x, touch.position.y, 0)
    end

    if touch.phase == TouchPhase.Ended then
        self.TouchType = DragTouchPhase.EndDrag
        self.TouchPosition = Vector3(touch.position.x, touch.position.y, 0)
    end

    self:UpdateSinglePointerDrag()
end

function XUiRpgMakerGameRoleMove:UpdateSinglePointerDrag()
    if self.TouchType == DragTouchPhase.BeginDrag then
        self.OldVector = self.TouchPosition
        if self.BeginDragCb then
            self.BeginDragCb(self.TouchPosition)
        end
    end

    self.NewVector = self.TouchPosition
    if self.TouchType == DragTouchPhase.OnDrag then
        if self.OnDragCb then
            self.OnDragCb(self.TouchPosition)
        end
    end

    if self.TouchType == DragTouchPhase.EndDrag then
        if self.EndDragCb then
            self.EndDragCb(self.TouchPosition)
        end
    end
end

function XUiRpgMakerGameRoleMove:SetIsIgnoreUi(isIgnoreUi)
    self.IsIgnoreUi = isIgnoreUi
end

return XUiRpgMakerGameRoleMove