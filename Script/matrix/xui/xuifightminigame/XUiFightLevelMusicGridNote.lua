---@class XUiFightLevelMusicGridNote : XUiNode
---@field Transform UnityEngine.RectTransform
---@field EffectTriggerA UnityEngine.RectTransform
---@field EffectTriggerB UnityEngine.RectTransform
---@field ImgNoteA UnityEngine.UI.Image
---@field ImgNoteB UnityEngine.UI.Image
---@field _Control XFightLevelMusicGameControl
local XUiFightLevelMusicGridNote = XClass(XUiNode, "XUiFightLevelMusicGridNote")

function XUiFightLevelMusicGridNote:OnStart()
    self._GridWidth = 0
    ---@type UnityEngine.GameObject[]
    self._NodeShowImageDir = {
        [XEnumConst.FIGHT_LEVEL_MUSIC.NOTE_TYPE.A] = self.ImgNoteA.gameObject,
        [XEnumConst.FIGHT_LEVEL_MUSIC.NOTE_TYPE.B] = self.ImgNoteB.gameObject,
    }
end

function XUiFightLevelMusicGridNote:OnEnable()
    if self.EffectTriggerA then
        self.EffectTriggerA.gameObject:SetActiveEx(false)
        self.EffectTriggerB.gameObject:SetActiveEx(false)
    end
end

function XUiFightLevelMusicGridNote:OnDisable()
end

---@param note XFightLevelMusicNote
function XUiFightLevelMusicGridNote:Refresh(note, trackDistance, trackLength)
    self._GridWidth = trackDistance / trackLength
    self.Transform.sizeDelta = Vector2(self._GridWidth * note:GetLength(), self.Transform.sizeDelta.y)
    self.Transform.anchoredPosition = Vector2(self._GridWidth * (note:GetTrackUnitIndex() - 1), 0)
    for type, nodeUiObj in pairs(self._NodeShowImageDir) do
        nodeUiObj:SetActiveEx(note:IsType(type))
    end
    if self.EffectTriggerA then
        self.EffectTriggerA.gameObject:SetActiveEx(false)
        self.EffectTriggerB.gameObject:SetActiveEx(false)
    end
end

function XUiFightLevelMusicGridNote:PlayTriggerAnim(noteType)
    if noteType == XEnumConst.FIGHT_LEVEL_MUSIC.NOTE_TYPE.A and self.EffectTriggerA then
        self.EffectTriggerA.gameObject:SetActiveEx(true)
    elseif noteType == XEnumConst.FIGHT_LEVEL_MUSIC.NOTE_TYPE.B and self.EffectTriggerB then
        self.EffectTriggerB.gameObject:SetActiveEx(true)
    end
    self:PlayAnimation("NotePanelAnimDisable")
end

function XUiFightLevelMusicGridNote:PlayInitAnim()
    self:PlayAnimation("NotePanelAnimEnable")
end

function XUiFightLevelMusicGridNote:GetCurRLLimitPos()
    local rightLimitPos = Vector3(self._GridWidth, 0)
    return self.Transform.position, self.Transform:TransformPoint(rightLimitPos)
end

return XUiFightLevelMusicGridNote