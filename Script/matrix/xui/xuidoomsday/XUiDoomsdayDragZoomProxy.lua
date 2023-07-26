local XUiDoomsdayDragZoomProxy = XClass(nil,"XUiDoomsdayDragZoomProxy")
local Input = CS.UnityEngine.Input
local CSVector3 = CS.UnityEngine.Vector3
local CSVector2 = CS.UnityEngine.Vector2
local CSMathf = CS.UnityEngine.Mathf
local TouchPhase = CS.UnityEngine.TouchPhase
---@type UnityEngine.Touch
local oldTouch1,oldTouch2
function XUiDoomsdayDragZoomProxy:Ctor(proxy, isKickBack)
    ---@type UnityEngine.UI.XDragZoomComponent
    self.Proxy = proxy
    ---@type UnityEngine.RectTransform
    self.Target = self.Proxy.target
    ---@type UnityEngine.RectTransform
    self.Area = self.Proxy.area
    ---@type UnityEngine.RectTransform
    self.View = self.Proxy.view
    self.AreaPos = self.Area.anchoredPosition
    self.AreaSize = self.Area.sizeDelta
    self.TargetOriginPos = self.Target.localPosition
    --是否需要回弹到原始位置
    self.IsKickBack = isKickBack
    self.Proxy.moveFixHandler = function(eventData) 
        self:MoveBehaviour(eventData)
    end
    self.Proxy.kickBackFixHandler = function(eventData) 
        self:KickBackBehaviour(eventData)
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
        --local minX = self.AreaPos.x - self.AreaSize.x / 2 + self.Target.sizeDelta.x / 2
        --local maxX = self.AreaPos.x + self.AreaSize.x / 2 - self.Target.sizeDelta.x / 2
        --local minY = self.AreaPos.y - self.AreaSize.y / 2 + self.Target.sizeDelta.y / 2
        --local maxY = self.AreaPos.y + self.AreaSize.y / 2 - self.Target.sizeDelta.y / 2
        self:LimitTargetPos(pos)
    end
end

--==============================
 ---@desc 限制Target位置,避免缩放后露馅
 ---@pos target 当前位置
--==============================
function XUiDoomsdayDragZoomProxy:LimitTargetPos(pos)
    local halfAreaSizeX, halfAreaSizeY = self.AreaSize.x / 2, self.AreaSize.y / 2
    local halfTargetSizeX = self.Target.sizeDelta.x / 2 * self.Target.localScale.x
    local halfTargetSizeY = self.Target.sizeDelta.y / 2 * self.Target.localScale.y
    local X1 = self.AreaPos.x - halfAreaSizeX + halfTargetSizeX
    local X2 = self.AreaPos.x + halfAreaSizeX - halfTargetSizeX
    local Y1 = self.AreaPos.y - halfAreaSizeY + halfTargetSizeY
    local Y2 = self.AreaPos.y + halfAreaSizeY - halfTargetSizeY
    pos.x = CSMathf.Clamp(pos.x, math.min(X1, X2), math.max(X1, X2))
    pos.y = CSMathf.Clamp(pos.y, math.min(Y1, Y2), math.max(Y1, Y2))
    self.Target.anchoredPosition = pos
end

--==============================
 ---@desc 超出可视范围回弹
 ---@eventData eventData 
--==============================
function XUiDoomsdayDragZoomProxy:KickBackBehaviour(eventData)
    if not self.IsKickBack then
        return
    end
    --local pos = self.Target.localPosition
    --local halfTargetSizeX = self.Target.sizeDelta.x / 2 * self.Target.localScale.x
    --local halfTargetSizeY = self.Target.sizeDelta.y / 2 * self.Target.localScale.y
    --local tmpX = math.abs(self.View.sizeDelta.x / 2 - halfTargetSizeX);
    --local tmpY = math.abs(self.View.sizeDelta.y / 2 - halfTargetSizeY);
    --pos.x = CSMathf.Clamp(pos.x, -tmpX, tmpX)
    --pos.y = CSMathf.Clamp(pos.y, -tmpY, tmpY)
    --self.Target.transform:DOLocalMove(pos, XDataCenter.FubenMainLineManager.UiGridChapterMoveDuration)
    self.Target.transform:DOLocalMove(self.TargetOriginPos, XDataCenter.FubenMainLineManager.UiGridChapterMoveDuration)
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
        self:LimitTargetPos(self.Target.anchoredPosition)

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

    self:LimitTargetPos(self.Target.anchoredPosition)
    
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