---@class XUiBigWorldMapPin : XUiNode
---@field BtnPin XUiComponent.XUiButton
---@field PanelPlayerList UnityEngine.RectTransform
---@field ImgTag UnityEngine.UI.Image
---@field UpUp UnityEngine.RectTransform
---@field UpDown UnityEngine.RectTransform
---@field BtnSelect XUiComponent.XUiButton
---@field Parent XUiBigWorldMap
---@field _Control XBigWorldMapControl
local XUiBigWorldMapPin = XClass(XUiNode, "XUiBigWorldMapPin")

function XUiBigWorldMapPin:OnStart(target, targetParent)
    ---@type XBWMapPinData
    self._PinData = false
    self._LevelId = 0

    self:_RegisterButtonClick()
    self:_InitTarget(target, targetParent)
end

function XUiBigWorldMapPin:OnBtnPinClick()
    if self._PinData and XTool.IsNumberValid(self._LevelId) then
        local mousePosition = CS.UnityEngine.Input.mousePosition
        local pinDatas = self._Control:GetScreenPointNearPinDataList(self._LevelId, mousePosition,
            self.Parent:GetPinNodeMap())

        if XTool.IsTableEmpty(pinDatas) or table.nums(pinDatas) <= 1 then
            self:AnchorTo()
            self:SetSelect(true)
            self.Parent:OpenPinDetail(self, self._LevelId, self._PinData)
        else
            self.Parent:OpenPinSelectList(pinDatas, mousePosition)
        end
    end
end

function XUiBigWorldMapPin:OnBtnSelectClick()
    if self._PinData and XTool.IsNumberValid(self._LevelId) then
        local mousePosition = CS.UnityEngine.Input.mousePosition
        local pinDatas = self._Control:GetScreenPointNearPinDataList(self._LevelId, mousePosition,
            self.Parent:GetPinNodeMap())

        self.Parent:OpenPinSelectList(pinDatas, mousePosition)
    end
end

function XUiBigWorldMapPin:SetRangeSelectable(isSelect)
    self.BtnSelect.gameObject:SetActiveEx(isSelect)
end

function XUiBigWorldMapPin:SetSelect(isSelect)
    if isSelect then
        self.BtnPin:SetButtonState(CS.UiButtonState.Select)
    else
        self.BtnPin:SetButtonState(CS.UiButtonState.Normal)
    end
end

function XUiBigWorldMapPin:SetPlayerTagActive(isActive)
    self.ImgTag.gameObject:SetActiveEx(isActive)
end

function XUiBigWorldMapPin:AnchorTo(isIgnoreTween)
    if not XTool.UObjIsNil(self._Target) then
        local posX = self._Target.transform.position.x
        local posY = self._Target.transform.position.y

        self.Parent:AnchorToPosition(posX, posY, isIgnoreTween)
    end
end

---@param pinData XBWMapPinData
function XUiBigWorldMapPin:Refresh(levelId, pinData)
    self._PinData = pinData
    self._LevelId = levelId
    self:_RefreshStyle(pinData)
    self:_RefreshPosition(pinData)
end

---@return XBWMapPinData
function XUiBigWorldMapPin:GetPinData()
    return self._PinData
end

---@param pinData XBWMapPinData
function XUiBigWorldMapPin:_RefreshPosition(pinData)
    if not XTool.UObjIsNil(self._Target) then
        self._Target.anchoredPosition = self._Control:WorldToMapPosition2D(pinData.LevelId, pinData.WorldPosition.x,
            pinData.WorldPosition.z)
    end
end

---@param pinData XBWMapPinData
function XUiBigWorldMapPin:_RefreshStyle(pinData)
    local icon = self._Control:GetPinIconByStyleId(pinData.StyleId, pinData:IsActive())
    local groupIndex = self._Control:GetFloorIndexByGroupId(pinData.MapAreaGroupId)
    local currentIndex = self.Parent:GetCurrentFloorIndex()

    self.UpUp.gameObject:SetActiveEx(groupIndex > currentIndex)
    self.UpDown.gameObject:SetActiveEx(groupIndex < currentIndex)
    self.BtnPin:SetSprite(icon)
    self.BtnPin:ShowTag(self._Control:CheckCurrentTrackPin(pinData.LevelId, pinData.PinId))
end

function XUiBigWorldMapPin:_InitTransformBind()
    if XTool.UObjIsNil(self._TransformBind) then
        self._TransformBind = self.GameObject:AddComponent(typeof(CS.XTransformBind))
    end
end

function XUiBigWorldMapPin:_InitTarget(target, targetParent)
    self:_InitTransformBind()

    if XTool.UObjIsNil(self._Target) then
        self._Target = XUiHelper.Instantiate(target, targetParent)
    end
    if not XTool.UObjIsNil(self._TransformBind) then
        self._TransformBind:SetTarget(self._Target)
    end
end

function XUiBigWorldMapPin:_RegisterButtonClick()
    self.BtnPin.CallBack = Handler(self, self.OnBtnPinClick)
    self.BtnSelect.CallBack = Handler(self, self.OnBtnSelectClick)
end

return XUiBigWorldMapPin
