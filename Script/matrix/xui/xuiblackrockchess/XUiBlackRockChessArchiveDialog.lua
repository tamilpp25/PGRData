---@class XUiBlackRockChessArchiveDialog : XLuaUi
---@field _Control
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
end

function XUiBlackRockChessArchiveDialog:OnClickBtnEnter()
    XDataCenter.MovieManager.PlayMovie(self._StoryId)
end

function XUiBlackRockChessArchiveDialog:OnDestroy()

end

return XUiBlackRockChessArchiveDialog