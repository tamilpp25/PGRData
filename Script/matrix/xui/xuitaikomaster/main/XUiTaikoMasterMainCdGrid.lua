---@class XUiTaikoMasterMainCdGrid : XUiNode
---@field _Control XTaikoMasterControl
local XUiTaikoMasterMainCdGrid = XClass(XUiNode, "XUiTaikoMasterMainCdGrid")

function XUiTaikoMasterMainCdGrid:OnStart()
    self.ImgBgSelect = XUiHelper.TryGetComponent(self.Transform, "PanelSelect/ImgBg01")
    self.ImgBgSelectLevel = XUiHelper.TryGetComponent(self.Transform, "PanelSelect/ImgBg01/ImgBg02", "RawImage")
    self.ImgBgUnSelect = XUiHelper.TryGetComponent(self.Transform, "PanelNotSelect/ImgBg01")
    self.ImgBgUnSelectLevel = XUiHelper.TryGetComponent(self.Transform, "PanelNotSelect/ImgBg01/ImgBg02", "RawImage")
    self.PanelNotLock = XUiHelper.TryGetComponent(self.Transform, "PanelNotLock")
    self.RImgCoverNotLock = XUiHelper.TryGetComponent(self.Transform, "PanelNotLock/RImgCoverSelect", "RawImage")
    self.ImgBgNotLock = XUiHelper.TryGetComponent(self.Transform, "PanelNotLock/ImgBg01")
    self.TxtNotLock = XUiHelper.TryGetComponent(self.Transform, "PanelNotLock/PanelLock/Txt01", "Text")
    self.BtnPlay.gameObject:SetActiveEx(false)
    if self.ImgBgNotLock then
        self.ImgBgNotLock.gameObject:SetActiveEx(false)
    end
end

function XUiTaikoMasterMainCdGrid:Refresh(songId, isSelect)
    local uiData = self._Control:GetUiData()
    local data = uiData.SongUiDataDir[songId]
    local playData = uiData.SongEasyPlayDataDir[songId]
    if XTool.IsTableEmpty(data) then
        return
    end
    self._SongId = songId
    self.RImgCoverSelect:SetRawImage(data.Cover)
    self.RImgCoverNotSelect:SetRawImage(data.Cover)
    if self.RImgCoverNotLock then
        self.RImgCoverNotLock:SetRawImage(data.Cover)
    end
    if self.ImgBgSelect and self.ImgBgSelectLevel then
        if not XTool.IsTableEmpty(playData) and playData.AssessImage then
            self.ImgBgSelectLevel:SetRawImage(playData.AssessImage)
            self.ImgBgSelect.gameObject:SetActiveEx(true)
            self.ImgBgUnSelectLevel:SetRawImage(playData.AssessImage)
            self.ImgBgUnSelect.gameObject:SetActiveEx(true)
        else
            self.ImgBgSelect.gameObject:SetActiveEx(false)
            self.ImgBgUnSelect.gameObject:SetActiveEx(false)
        end
    end
    self:UpdateSelect(isSelect, true)
end

function XUiTaikoMasterMainCdGrid:UpdateSelect(isSelect, isNotPlay)
    if isSelect and not isNotPlay then
        self:PlaySong()
    end
    local uiData = self._Control:GetUiData()
    local isUnLock = XTool.IsNumberValid(self._SongId) and uiData.SongUnLockDir[self._SongId]
    self.PanelSelect.gameObject:SetActiveEx(isSelect and isUnLock)
    if self.PanelNotLock then
        self.TxtNotLock.text = XUiHelper.GetText("EscapeTimeCondition", self._Control:GetSongLockDesc(self._SongId))
        self.PanelNotLock.gameObject:SetActiveEx(not isUnLock)
        self.PanelNotSelect.gameObject:SetActiveEx(not isSelect and isUnLock)
    else
        self.PanelNotSelect.gameObject:SetActiveEx(not isSelect or not isUnLock)
    end
end

function XUiTaikoMasterMainCdGrid:PlaySong()
    if XTool.IsNumberValid(self._SongId) then
        self._Control:PlaySong(self._SongId)
    end
end

return XUiTaikoMasterMainCdGrid