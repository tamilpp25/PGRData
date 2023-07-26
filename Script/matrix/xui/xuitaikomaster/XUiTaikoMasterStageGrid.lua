---@class XUiTaikoMasterStageGrid
local XUiTaikoMasterStageGrid = XClass(nil, "XUiTaikoMasterStageGrid")
function XUiTaikoMasterStageGrid:Ctor(ui)
    self._RectTransform = ui
    self.Transform = ui
    XTool.InitUiObject(self)

    self._IsActive = nil
    self._SongId = false
    self._Index = false
    self._IsUnfold = false
    self._Difficulty = false
    self._LeftPosX = self.PanelCdItem.transform.localPosition.x
    self._IsPosDirty = false
    local rectWidth = ui.transform.rect.width
    local itemWidth = self.PanelCdItem.rect.width
    self._RightPosX = self._LeftPosX + rectWidth - itemWidth
    self:RegisterButtonClick()
end

function XUiTaikoMasterStageGrid:GetSongId()
    return self._SongId
end

function XUiTaikoMasterStageGrid:GetIndex()
    return self._Index
end

function XUiTaikoMasterStageGrid:IsActive()
    return self._IsActive
end

function XUiTaikoMasterStageGrid:SetActive(value)
    if self._IsActive == value then
        return
    end
    self._IsActive = value
    self._RectTransform.gameObject:SetActiveEx(value)
end

function XUiTaikoMasterStageGrid:GetRectTransform()
    return self._RectTransform
end

function XUiTaikoMasterStageGrid:RegisterButtonClick()
    XUiHelper.RegisterClickEvent(
        self,
        self.ButtonCd,
        function()
            if not XDataCenter.TaikoMasterManager.IsSongUnlock(self._SongId) then
                XDataCenter.TaikoMasterManager.TipSongLock(self._SongId)
                return
            end
            XDataCenter.TaikoMasterManager.SetSongBrowsed4RedDot(self._SongId)
            XEventManager.DispatchEvent(XEventId.EVENT_TAIKO_MASTER_STAGE_SELECT, self._Index)
        end
    )
end

function XUiTaikoMasterStageGrid:Refresh(songId, selectedIndex, index)
    if selectedIndex == index then
        self:Unfold()
    else
        self:Fold()
    end
    local isDirty = false
    if self._IsPosDirty then
        isDirty = true
        self._IsPosDirty = false
    end
    if self._SongId == songId then
        return isDirty
    end
    self._SongId = songId
    self._Index = index
    local coverImage = XTaikoMasterConfigs.GetSongCoverImage(songId)
    self.RImgCd:SetRawImage(coverImage)
    self.TxtName.text = XTaikoMasterConfigs.GetSongName(songId)
    self.PanelSuo.gameObject:SetActiveEx(not XDataCenter.TaikoMasterManager.IsSongUnlock(songId))
    self:CheckRedPointCdUnlock()
    return true
end

function XUiTaikoMasterStageGrid:Unfold()
    self.PanelCdItem.gameObject:SetActiveEx(false)
end

function XUiTaikoMasterStageGrid:Fold()
    self.PanelCdItem.gameObject:SetActiveEx(true)
end

function XUiTaikoMasterStageGrid:SetPosDirty()
    self._IsPosDirty = true
end

--region red point
function XUiTaikoMasterStageGrid:CheckRedPointCdUnlock()
    XRedPointManager.CheckOnce(
        self.OnCheckRedPointCdUnlock,
        self,
        {XRedPointConditions.Types.CONDITION_ACTIVITY_TAIKO_MASTER_CD_UNLOCK},
        self._SongId
    )
end

function XUiTaikoMasterStageGrid:OnCheckRedPointCdUnlock(count)
    self.ButtonCd:ShowReddot(count >= 0)
end
--endregion

return XUiTaikoMasterStageGrid
