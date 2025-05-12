---@class XUiFightLevelMusicGridAreaPoint : XUiNode
---@field Transform UnityEngine.RectTransform
---@field ImgPointNor UnityEngine.UI.Image
---@field ImgPointFail UnityEngine.UI.Image
---@field ImgPointFSuccessfulA UnityEngine.UI.Image
---@field ImgPointFSuccessfulB UnityEngine.UI.Image
---@field _Control XFightLevelMusicGameControl
local XUiFightLevelMusicGridAreaPoint = XClass(XUiNode, "XUiFightLevelMusicGridAreaPoint")

XUiFightLevelMusicGridAreaPoint.ShowTypeEnum = {
    None = 1,   -- 移动
    Fail = 2,   -- 失败
    ClearA = 3, -- AClear
    ClearB = 4, -- BClear
}

function XUiFightLevelMusicGridAreaPoint:OnStart()
    self._AnimTimer = 0
end

function XUiFightLevelMusicGridAreaPoint:OnEnable()
    self._ShowType = XUiFightLevelMusicGridAreaPoint.ShowTypeEnum.None
    self._ShowTime = 0
    self._ShowTriggerPosition = false
end

function XUiFightLevelMusicGridAreaPoint:OnDisable()
end

---@param areaPoint XFightLevelMusicArea
function XUiFightLevelMusicGridAreaPoint:Refresh(areaPoint)
    self:Update(0, areaPoint)
    self:_UpdateStatus(0)
end

---@param areaPoint XFightLevelMusicArea
function XUiFightLevelMusicGridAreaPoint:Update(time, areaPoint)
    self.Transform.anchoredPosition = Vector2(areaPoint:GetRLCurPos(), 0)
    self:_UpdateStatus(time)
end

---@return UnityEngine.Vector3 Transform.position
function XUiFightLevelMusicGridAreaPoint:GetRLCurPos()
    return self.Transform.position
end

--region Ui - Status
function XUiFightLevelMusicGridAreaPoint:_UpdateStatus(time)
    if not self.ImgPointNor then
        return
    end
    
    self._ShowTime = math.max(0, self._ShowTime - time)
    if self._ShowTime <= 0 then
        self._ShowType = XUiFightLevelMusicGridAreaPoint.ShowTypeEnum.None
        self._ShowTriggerPosition = false
    end
    
    self:_RefreshStateShow()
end

function XUiFightLevelMusicGridAreaPoint:_RefreshStateShow()
    --self.ImgPointNor.gameObject:SetActiveEx(self:CheckShowType(XUiFightLevelMusicGridAreaPoint.ShowTypeEnum.None))
    self.ImgPointFail.gameObject:SetActiveEx(self:CheckShowType(XUiFightLevelMusicGridAreaPoint.ShowTypeEnum.Fail))
    self.ImgPointFSuccessfulA.gameObject:SetActiveEx(self:CheckShowType(XUiFightLevelMusicGridAreaPoint.ShowTypeEnum.ClearA))
    self.ImgPointFSuccessfulB.gameObject:SetActiveEx(self:CheckShowType(XUiFightLevelMusicGridAreaPoint.ShowTypeEnum.ClearB))
    if self._ShowTriggerPosition then
        self.ImgPointFSuccessfulA.transform.position = self._ShowTriggerPosition
        self.ImgPointFSuccessfulB.transform.position = self._ShowTriggerPosition
    end
end

function XUiFightLevelMusicGridAreaPoint:CheckShowType(type)
    return self._ShowType == type
end
--endregion

--region Anim
function XUiFightLevelMusicGridAreaPoint:PlayTriggerFail()
    self._ShowType = XUiFightLevelMusicGridAreaPoint.ShowTypeEnum.Fail
    self._ShowTime = 0.5
    self:_RefreshStateShow()
    self:PlayAnimation("AreaPointPanelAnimFail")
end

---@param noteUiObj XUiFightLevelMusicGridNote
function XUiFightLevelMusicGridAreaPoint:PlayTriggerClearAnim(noteType, noteUiObj)
    if noteType == XEnumConst.FIGHT_LEVEL_MUSIC.NOTE_TYPE.A then
        self._ShowType = XUiFightLevelMusicGridAreaPoint.ShowTypeEnum.ClearA
    elseif noteType == XEnumConst.FIGHT_LEVEL_MUSIC.NOTE_TYPE.B then
        self._ShowType = XUiFightLevelMusicGridAreaPoint.ShowTypeEnum.ClearB
    end
    self._ShowTime = 0.5
    -- trigger光标
    --local leftLimitPos, rightLimitPos = noteUiObj:GetCurRLLimitPos()
    --self._ShowTriggerPosition = self:GetRLCurPos()
    --if self._ShowTriggerPosition.x > leftLimitPos.x and self._ShowTriggerPosition.x > rightLimitPos.x then
    --    self._ShowTriggerPosition = rightLimitPos
    --elseif self._ShowTriggerPosition.x < leftLimitPos.x and self._ShowTriggerPosition.x < rightLimitPos.x then
    --    self._ShowTriggerPosition = leftLimitPos
    --end
    
    self:_RefreshStateShow()
    self:PlayAnimation("AreaPointPanelAnimHit")
end
--endregion

return XUiFightLevelMusicGridAreaPoint