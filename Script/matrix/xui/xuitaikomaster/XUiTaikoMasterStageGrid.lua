---@class XUiTaikoMasterStageGrid:XUiNode
---@field _Control XTaikoMasterControl
local XUiTaikoMasterStageGrid = XClass(XUiNode, "XUiTaikoMasterStageGrid")

function XUiTaikoMasterStageGrid:OnStart()
    self._SongId = false
    self._Index = false
    self._IsUnfold = false
    self._Difficulty = false
    self._LeftPosX = self.PanelCdItem.transform.localPosition.x
    self._IsPosDirty = false
    local rectWidth = self.Transform.rect.width
    local itemWidth = self.PanelCdItem.rect.width
    self._RightPosX = self._LeftPosX + rectWidth - itemWidth
    self._RectTransform = self.Transform
    self:RegisterButtonClick()
end

function XUiTaikoMasterStageGrid:GetSongId()
    return self._SongId
end

function XUiTaikoMasterStageGrid:GetIndex()
    return self._Index
end

function XUiTaikoMasterStageGrid:GetRectTransform()
    return self._RectTransform
end

function XUiTaikoMasterStageGrid:RegisterButtonClick()
    XUiHelper.RegisterClickEvent(
        self,
        self.ButtonCd,
        function()
            if not self._Control:GetUiData():CheckSongUnLock(self._SongId) then
                self._Control:TipSongLock(self._SongId)
                return
            end
            self._Control:SetSongBrowsed4RedDot(self._SongId)
            XEventManager.DispatchEvent(XEventId.EVENT_TAIKO_MASTER_STAGE_SELECT, self._Index)
        end
    )
end

function XUiTaikoMasterStageGrid:Refresh(songId, selectedIndex, index)
    local uiData = self._Control:GetUiData()
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
    local coverImage = uiData.SongUiDataDir[songId].Cover
    self.RImgCd:SetRawImage(coverImage)
    self.TxtName.text = uiData.SongUiDataDir[songId].Name
    self.PanelSuo.gameObject:SetActiveEx(not self._Control:GetUiData():CheckSongUnLock(songId))
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
