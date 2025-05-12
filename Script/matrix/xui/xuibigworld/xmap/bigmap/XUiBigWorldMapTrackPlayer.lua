local XUiBigWorldMapTrackPin = require("XUi/XUiBigWorld/XMap/BigMap/XUiBigWorldMapTrackPin")

---@class XUiBigWorldMapTrackPlayer : XUiBigWorldMapTrackPin
local XUiBigWorldMapTrackPlayer = XClass(XUiBigWorldMapTrackPin, "XUiBigWorldMapTrackPlayer")

function XUiBigWorldMapTrackPlayer:OnStart()
    self._PosX = false
    self._PosY = false

    self.ImgPlayer.gameObject:SetActiveEx(true)
    self.ImgPin.gameObject:SetActiveEx(false)
    self:_RegisterButtonClicks()
end

function XUiBigWorldMapTrackPlayer:OnBtnAnchorClick()
    if self._PosX and self._PosY then
        self.Parent:AnchorToPosition(self._PosX, self._PosY)
    end
end

function XUiBigWorldMapTrackPlayer:Refresh(posX, posY)
    self._PosX = posX
    self._PosY = posY
end

return XUiBigWorldMapTrackPlayer
