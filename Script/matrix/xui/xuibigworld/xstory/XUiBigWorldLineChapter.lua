
---@class XUiBigWorldLineChapter : XBigWorldUi
---@field GameObject UnityEngine.GameObject
---@field Transform UnityEngine.Transform
---@field _Control XBigWorldQuestControl
---@field _PanelChapter XUiPanelBWChapter
local XUiBigWorldLineChapter = XMVCA.XBigWorldUI:Register(nil, "UiBigWorldLineChapter")

function XUiBigWorldLineChapter:OnAwake()
    self:InitUi()
    self:InitCb()
end

function XUiBigWorldLineChapter:OnStart()
    self:InitView()
end

function XUiBigWorldLineChapter:InitUi()
end

function XUiBigWorldLineChapter:InitCb()
    self.BtnClose.CallBack = function()
        self:Close()
    end
end

function XUiBigWorldLineChapter:InitView()
    local chapterId = self._Control:GetChapterId()
    local chapterUrl = self._Control:GetChapterUrl(chapterId)
    local prefab = self.Chapter1:LoadPrefab(chapterUrl)
    self._PanelChapter = require("XUi/XUiBigWorld/XStory/Panel/XUiPanelBWChapter").New(prefab, self, chapterId)
    --self.RImgChapterBg:SetRawImage(self._Control:GetChapterFullBg(chapterId))

    self.TxtTitle.text = self._Control:GetChapterName(chapterId)
    self.TxtReview.text = self._Control:GetChapterMapName(chapterId)
end