---@class XUiBlackRockChessArchiveDialog : XLuaUi
---@field _Control XBlackRockChessControl
local XUiBlackRockChessArchiveDialog = XLuaUiManager.Register(XLuaUi, "UiBlackRockChessArchiveDialog")

function XUiBlackRockChessArchiveDialog:OnAwake()
    self:RegisterClickEvent(self.BtnMask, self.Close)
    self:RegisterClickEvent(self.BtnEnterStoryAfter, self.OnClickBtnEnter)
end

---@param data XTableBlackRockChessArchive
function XUiBlackRockChessArchiveDialog:OnStart(data)
    self._StoryId = data.StoryId
    self.TxtStoryName.text = data.ArchiveTitle
    self.TxtStoryDec.text = data.ArchiveDesc
    self.ArchiveType = data.ArchiveType
    self.BtnEnterStoryAfter:SetNameByGroup(0, self._Control:GetArchiveTypeButtonText(self.ArchiveType))
end

function XUiBlackRockChessArchiveDialog:OnClickBtnEnter()
    if self.ArchiveType == XMVCA.XBlackRockChess.ArchiveType.Story then
        XDataCenter.MovieManager.PlayMovie(self._StoryId)
    elseif self.ArchiveType == XMVCA.XBlackRockChess.ArchiveType.Communication then
        local communicationId = tonumber(self._StoryId)
        self._Control:PlayCommunication(communicationId)
    end
end

function XUiBlackRockChessArchiveDialog:OnDestroy()

end

return XUiBlackRockChessArchiveDialog