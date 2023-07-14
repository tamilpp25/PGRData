local XUiDoomsdayDragZoomProxy = XClass(nil,"XUiDoomsdayDragZoomProxy")
local Input = CS.UnityEngine.Input
local CSVector3 = CS.UnityEngine.Vector3
local CSVector2 = CS.UnityEngine.Vector2
local CSMathf = CS.UnityEngine.Mathf
local TouchPhase = CS.UnityEngine.TouchPhase
---@type UnityEngine.Touch
local oldTouch1,oldTouch2
function XUiDoomsdayDragZoomProxy:Ctor(proxy)
    ---@type UnityEngine.UI.XDragZoomComponent
    self.Proxy = proxy
    ---@type UnityEngine.RectTransform
    self.Target = self.Proxy.target
    ---@type UnityEngine.RectTransform
    self.Area = self.Proxy.area
    self.AreaPos = self.Area.anchoredPosition
    self.AreaSize = self.Area.sizeDelta
    self.TargetSize = self.Target.sizeDelta
    self.Proxy.moveFixHandler = function(eventData) 
        self:MoveBehaviour(eventData)
    end
    self.Proxy.mouseZoomFixHandler = function()
        self:TouchZoom()
        self:MouseZoom()    
    end
    self.Proxy.zoomFixHandler = function() 
    end
end

---@param eventData UnityEngine.EventSystems.PointerEventData
function XUiDoomsdayDragZoomProxy:MoveBehaviour(eventData)
    if Input.touchCount ==1 or Input.GetMouseButton(0) then
        local pos = self.Target.anchoredPosition
        pos.x = pos.x + eventData.delta.x 
        pos.y = pos.y + eventData.delta.y
        pos.x = CSMathf.Clamp(pos.x, self.AreaPos.x - self.AreaSize.x / 2 + self.TargetSize.x / 2, self.AreaPos.x + self.AreaSize.x / 2 - self.TargetSize.x / 2)
        pos.y = CSMathf.Clamp(pos.y, self.AreaPos.y - self.AreaSize.y / 2 + self.TargetSize.y / 2, self.AreaPos.y + self.AreaSize.y / 2 - self.TargetSize.y / 2)
        self.Target.anchoredPosition = pos
    end
end

function XUiDoomsdayDragZoomProxy:MouseZoom()

    if Input.GetAxis("Mouse ScrollWheel") ~= 0 then
        local direction = Input.GetAxis("Mouse ScrollWheel") > 0 and 1 or -1
        local scale = self.Proxy.target.localScale

        scale.x = CSMathf.Clamp(scale.x + direction * self.Proxy.zoomSpeed, self.Proxy.minScale, self.Proxy.maxScale)
        scale.y = CSMathf.Clamp(scale.y + direction * self.Proxy.zoomSpeed, self.Proxy.minScale, self.Proxy.maxScale)
        scale.z = CSMathf.Clamp(scale.z + direction * self.Proxy.zoomSpeed, self.Proxy.minScale, self.Proxy.maxScale)
        self.Proxy.target.localScale = scale
        self.Proxy.area.localScale = scale
        
    else
        self.Target.pivot = self.Proxy.defaultPivot
    end
end

function XUiDoomsdayDragZoomProxy:TouchZoom()
    if Input.touchCount < 2 then
        return
    end
    local newTouch1 = Input.GetTouch(0)
    local newTouch2 = Input.GetTouch(1)

    if newTouch2.phase == TouchPhase.Began then
        oldTouch1 = newTouch1
        oldTouch2 = newTouch2
        return
    end
    if (not oldTouch1) or (not oldTouch2) then
        return
    end
    local oldDistance = CSVector2.Distance(oldTouch1.position,oldTouch2.position)
    local newDistance = CSVector2.Distance(newTouch1.position,newTouch2.position)
    local offset = newDistance - oldDistance
    local newScale = self.Target.localScale
    newScale.x = CSMathf.Clamp(newScale.x + offset * self.Proxy.zoomSpeed, self.Proxy.minScale, self.Proxy.maxScale)
    newScale.y = CSMathf.Clamp(newScale.y + offset * self.Proxy.zoomSpeed, self.Proxy.minScale, self.Proxy.maxScale)
    newScale.z = CSMathf.Clamp(newScale.z + offset * self.Proxy.zoomSpeed, self.Proxy.minScale, self.Proxy.maxScale)
    self.Target.localScale = newScale
    self.Area.localScale = newScale
    
    oldTouch1 = newTouch1
    oldTouch2 = newTouch2
    
    --if Input.touchCount == 2 then
    --if touch1.phase == TouchPhase.Began and touch2.phase == TouchPhase.Began then
    --    self.Proxy.preDistance = CSVector2.Distance(touch1.position,touch2.position)
    --    local midPoint = (touch1.position + touch2.position) / 2;
    --    local newTargetPivot = self:GetChangePivot(midPoint,self.Target)
    --    local newAreaPivot = self:GetChangePivot(midPoint,self.Area)
    --    self.Target.pivot = newTargetPivot
    --    self.Area.pivot = newAreaPivot
    --end
    --
    --if touch1.phase == TouchPhase.Moved and touch2.phase == TouchPhase.Moved then
    --    local newDistance = CSVector2.Distance(touch1.position,touch2.position)
    --    self.Proxy.currDistance = newDistance - self.Proxy.preDistance
    --    local newScale = self.Target.localScale
    --    newScale.x = CSMathf.Clamp(newScale.x + self.Proxy.currDistance * zoomSpeed,self.Proxy.minScale,self.Proxy.maxScale)
    --    newScale.y= CSMathf.Clamp(newScale.y + self.Proxy.currDistance * zoomSpeed,self.Proxy.minScale,self.Proxy.maxScale)
    --    newScale.z = CSMathf.Clamp(newScale.z + self.Proxy.currDistance * zoomSpeed,self.Proxy.minScale,self.Proxy.maxScale)
    --    self.Target.localScale = newScale
    --    self.Area.localScale = newScale
    --end
    --
    --if touch1.phase == TouchPhase.Ended or touch2.phase == TouchPhase.Ended then
    --    self.Target.pivot = self.Proxy.defaultPivot
    --    self.Area.pivot = self.Proxy.defaultPivot
    --end
    --end
    end

---@param touchMidPos UnityEngine.Vector2
---@param targetRectTransform UnityEngine.RectTransform
function XUiDoomsdayDragZoomProxy:GetChangePivot(touchMidPos,targetRectTransform)
    local _, rectPos = CS.UnityEngine.RectTransformUtility.ScreenPointToLocalPointInRectangle(targetRectTransform,touchMidPos,CS.XUiManager.Instance.UiCamera)
    local pivot =  CSVector2(rectPos.x / targetRectTransform.rect.width, (rectPos.y / targetRectTransform.rect.height)) + self.Proxy.target.pivot
    return pivot
end

return XUiDoomsdayDragZoomProxy