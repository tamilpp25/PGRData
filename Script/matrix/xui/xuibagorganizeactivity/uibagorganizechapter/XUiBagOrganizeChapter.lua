local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
---@class XUiBagOrganizeChapter:XLuaUi
---@field _Control XBagOrganizeActivityControl
local XUiBagOrganizeChapter = XLuaUiManager.Register(XLuaUi, 'UiBagOrganizeChapter')
local XUiPanelBagOrganizeStageList = require('XUi/XUiBagOrganizeActivity/UiBagOrganizeChapter/XUiPanelBagOrganizeStageList')

function XUiBagOrganizeChapter:OnAwake()
    self.BtnBack.CallBack = handler(self, self.Close)
    self.BtnMainUi.CallBack = XLuaUiManager.RunMain
    self:BindHelpBtn(self.BtnHelp, "BagOrganize")
end

function XUiBagOrganizeChapter:OnStart(chapterId, chapterIndex)
    self._ChapterId = chapterId
    self._ChapterIndex = chapterIndex
    self.TitleBg:SetRawImage(self._Control:GetChapterTitleBgById(self._ChapterId))
    self._Control:SetCurChapterId(self._ChapterId)
    self:InitStages()
end

function XUiBagOrganizeChapter:OnEnable()
    self:RefreshStages()
end

function XUiBagOrganizeChapter:OnDisable()
    
end

function XUiBagOrganizeChapter:InitStages()
    self._StageList = XUiPanelBagOrganizeStageList.New(self.PanelChapter, self, self._ChapterId)
    self._StageList:Open()
end

function XUiBagOrganizeChapter:RefreshStages()
    self._StageList:RefreshStages()
end

return XUiBagOrganizeChapter