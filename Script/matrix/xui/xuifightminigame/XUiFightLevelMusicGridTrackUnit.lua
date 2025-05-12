---@class XUiFightLevelMusicGridTrackUnit : XUiNode
---@field Img UnityEngine.UI.Image
---@field _Control XFightLevelMusicGameControl
local XUiFightLevelMusicGridTrackUnit = XClass(XUiNode, "XUiFightLevelMusicGridTrackUnit")

function XUiFightLevelMusicGridTrackUnit:OnStart()
    self._GridWidth = 0
end

function XUiFightLevelMusicGridTrackUnit:OnEnable()

end

function XUiFightLevelMusicGridTrackUnit:OnDisable()

end

---@param unit XFightLevelMusicTrackUnit
function XUiFightLevelMusicGridTrackUnit:Refresh(unit, trackDistance, trackLength)
    self._GridWidth = trackDistance / trackLength
    self.Transform.sizeDelta = Vector2(self._GridWidth, self.Transform.sizeDelta.y)
    self.Transform.anchoredPosition = Vector2(self._GridWidth * (unit:GetIndex() - 1), 0)
end

function XUiFightLevelMusicGridTrackUnit:ShowTriggerArea()
    if self._IsShowTriggerArea then
        return
    end
    self._IsShowTriggerArea = true
    self.Img.color = CS.UnityEngine.Color.red
    XScheduleManager.ScheduleOnce(function()
        self._IsShowTriggerArea = false
        self.Img.color = CS.UnityEngine.Color.white
    end, 500)
end

return XUiFightLevelMusicGridTrackUnit