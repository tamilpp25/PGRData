---@class XUiGridPaster : XUiNode 放置贴纸的格子类
---@field Parent XUiFightCaptureV217
---@field _Control XFightCaptureV217Control
local XUiGridPaster = XClass(XUiNode, "XUiGridPaster")
local XUguiDragProxy = CS.XUguiDragProxy
local Quaternion = CS.UnityEngine.Quaternion

function XUiGridPaster:OnStart()
    XTool.InitUiObject(self)
    
    -- 大小拖拽
    local dragProxy
    for i = 1, 2 do
        dragProxy = self["DragNode" .. i].gameObject:AddComponent(typeof(XUguiDragProxy))
        dragProxy:RegisterHandler(handler(self, self["OnScaleDragProxy" .. i]))
    end
    -- 旋转拖拽
    dragProxy = self.BtnRotation.gameObject:AddComponent(typeof(XUguiDragProxy))
    dragProxy:RegisterHandler(handler(self, self.OnRotationDragProxy))
    -- 点击和移动
    local uiWeight = self.GameObject:AddComponent(typeof(CS.XUiWidget))
    uiWeight:AddDragListener(function(eventData)
        self:OnDrag(eventData)
    end)
    uiWeight:AddPointerDownListener(function(eventData)
        self:OnPointerDown(eventData)
    end)

    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.OnBtnCloseClick)
end

--右下的拖拽点
function XUiGridPaster:OnScaleDragProxy1(dragType, eventData)
    self:OnScaleDragProxy(dragType, eventData)
end

--左上的拖拽点
function XUiGridPaster:OnScaleDragProxy2(dragType, eventData)
    self:OnScaleDragProxy(dragType, eventData, true)
end

function XUiGridPaster:OnScaleDragProxy(dragType, eventData, isInvert)
    if dragType == 0 then
        -- 开始拖拽
        self.Parent:StartLeyPaster()
    elseif dragType == 1 then
        -- 拖拽中
        local eventX = isInvert and -eventData.delta.x or eventData.delta.x
        local x = XMath.Clamp(self.RectTransform.sizeDelta.x + eventX, self.Width * self.MinScale, self.Width * self.MaxScale)
        local y = x / self.RectTransform.sizeDelta.x * self.RectTransform.sizeDelta.y --等比缩放
        self.RectTransform.sizeDelta = Vector2(x,y)
    elseif dragType == 2 then
        -- 结束拖拽
        --self.Parent:EndLeyPaster()
    end
end

local dragStartPos
local originalRotation
function XUiGridPaster:OnRotationDragProxy(dragType, eventData)
    if dragType == 0 then
        originalRotation = self.RectTransform.rotation
        dragStartPos = eventData.position
        self.Parent:StartLeyPaster()
    elseif dragType == 1 then
        local delta = eventData.position - dragStartPos
        local rotationAngle = math.atan(delta.y, delta.x) * CS.UnityEngine.Mathf.Rad2Deg - 90
        local rotation = Quaternion.AngleAxis(rotationAngle, Vector3.forward)
        self.RectTransform.rotation = originalRotation * rotation
    elseif dragType == 2 then
        --结束拖拽
        --self.Parent:EndLeyPaster()
    end
end

function XUiGridPaster:OnPointerDown(eventData)
    self.Operation.gameObject:SetActiveEx(true)
    self.Bg.gameObject:SetActiveEx(true)
    self.Parent:StartLeyPaster()
end

function XUiGridPaster:OnDrag(eventData)
    local hasValue, point = CS.UnityEngine.RectTransformUtility.ScreenPointToLocalPointInRectangle(self.Parent.GridPasterRoot, eventData.position, CS.XUiManager.Instance.UiCamera)
    if not hasValue then
        return
    end
    self.RectTransform.localPosition = Vector3(point.x, point.y, 0)
end

-- XObjectPool调用
---@param stickerId - CaptureV217Sticker表的Id
---@param texture - Texture2D 滤镜图片
function XUiGridPaster:Init(stickerId, texture)
    self.StickerId = stickerId
    self.MaxScale = self._Control._Model:GetStickerCfgMaxScale(stickerId)
    self.MinScale = self._Control._Model:GetStickerCfgMinScale(stickerId)
    
    local iconPath = self._Control._Model:GetStickerCfgSmallIconPath(stickerId) or ""
    self.Image:SetSprite(iconPath)
    self.RectTransform.localPosition = Vector3.zero
    self.RectTransform.localScale = Vector3.one
    self.RectTransform.localRotation = Quaternion.identity
    -- 尺寸
    local scale = self._Control._Model:GetStickerCfgDefaultScale(stickerId)
    local width = self._Control._Model:GetStickerCfgWidth(stickerId)
    local height = self._Control._Model:GetStickerCfgHeight(stickerId)
    self.Width = width
    self.RectTransform.sizeDelta = Vector2(width * scale, height * scale)
    
    self:SetImageLut(texture)
    self.Parent:StartLeyPaster()
    self:Open()
end

function XUiGridPaster:OnBtnCloseClick()
    self.Parent:RemoveGridPaster(self)
    self.Parent:EndLeyPaster()
    self:Close()
end

function XUiGridPaster:EndLeyPaster()
    self.Bg.gameObject:SetActiveEx(false)
    self.Operation.gameObject:SetActiveEx(false)
end

function XUiGridPaster:SetImageLut(texture)
    self.ImageLut:SetLutTex(texture)
end

return XUiGridPaster