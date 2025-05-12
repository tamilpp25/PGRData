---@class XUiBigWorldMapTrackPin : XUiNode
---@field ImgPin UnityEngine.UI.Image
---@field BtnAnchor XUiComponent.XUiButton
---@field ImgPlayer UnityEngine.UI.Image
---@field Pointer UnityEngine.RectTransform
---@field Parent XUiBigWorldMap
---@field _Control XBigWorldMapControl
local XUiBigWorldMapTrackPin = XClass(XUiNode, "XUiBigWorldMapTrackPin")

function XUiBigWorldMapTrackPin:OnStart()
    self._LevelId = 0
    self._PinId = 0

    self.ImgPlayer.gameObject:SetActiveEx(false)
    self.ImgPin.gameObject:SetActiveEx(true)
    self:_RegisterButtonClicks()
end

function XUiBigWorldMapTrackPin:OnBtnAnchorClick()
    if XTool.IsNumberValid(self._PinId) then
        self.Parent:AnchorToPin(self._PinId)
    end
end

function XUiBigWorldMapTrackPin:Refresh(levelId, pinId)
    self._LevelId = levelId
    self._PinId = pinId

    self:_RefreshPin(self._Control:GetPinDataByLevelIdAndPinId(levelId, pinId))
end

function XUiBigWorldMapTrackPin:SetPosition(position, direction, angle)
    local width = self.Transform.rect.width
    local height = self.Transform.rect.height

    self.Transform.anchoredPosition = Vector2(position.x - width / 2 * direction.x, position.y - height / 2 * direction.y)
    self.Pointer.rotation = CS.UnityEngine.Quaternion.Euler(0, 0, angle)
end

---@param pinData XBWMapPinData
function XUiBigWorldMapTrackPin:_RefreshPin(pinData)
    if pinData then
        local icon = self._Control:GetPinIconByStyleId(pinData.StyleId, pinData:IsActive())

        self.ImgPin:SetSprite(icon)
    end
end

function XUiBigWorldMapTrackPin:_RegisterButtonClicks()
    self.BtnAnchor.CallBack = Handler(self, self.OnBtnAnchorClick)
end

return XUiBigWorldMapTrackPin
