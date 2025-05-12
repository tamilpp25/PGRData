local XUiGridArchive = require("XUi/XUiArchive/XUiGridArchive")
local XUiGridArchiveStory = XClass(XUiNode, "XUiGridArchiveStory")
local Rect = CS.UnityEngine.Rect(1, 1, 1, 1)
local LockNameText = CS.XTextManager.GetText("ArchiveLockNameText")
local LockStoryIconAspectRatio = CS.XGame.ClientConfig:GetFloat("LockStoryIconAspectRatio")
function XUiGridArchiveStory:OnStart()
    self:SetButtonCallBack()
end

function XUiGridArchiveStory:SetButtonCallBack()
    self.StoryBtn.CallBack = function()
        self:OnBtnSelect()
    end
end

function XUiGridArchiveStory:OnBtnSelect()
    if self.Chapter:GetIsLock() then
        XUiManager.TipError(self.Chapter:GetLockDesc())
        return
    end
    XLuaUiManager.Open("UiArchiveStoryDetail", self.ChapterList, self.CurIndex)
end

function XUiGridArchiveStory:UpdateGrid(chapterList, base, index)
    local chapter = chapterList and chapterList[index]
    if chapter then
        self.Chapter = chapter
        self.ChapterList = chapterList
        self:SetMonsterData(chapter)
        self.Base = base
        self.CurIndex = index
    end
end

function XUiGridArchiveStory:SetMonsterData(chapter)
    if chapter:GetIsLock() then
        if chapter:GetLockBg() and #chapter:GetLockBg() > 0 then
            self.StoryImg:SetRawImage(chapter:GetLockBg())
        end
        self.StoryTitle.text = LockNameText
        Rect.x = 0
        Rect.y = 0
        self.StoryImg.uvRect = Rect
        self.StoryImgAspect.aspectRatio = LockStoryIconAspectRatio
    else
        if chapter:GetBg() and #chapter:GetBg() > 0 then
            self.StoryImg:SetRawImage(chapter:GetBg())
        end
        self.StoryTitle.text = chapter:GetName()
        Rect.x = chapter:GetBgOffSetX() / 100
        Rect.y = chapter:GetBgOffSetY() / 100
        self.StoryImg.uvRect = Rect
        local width = chapter:GetBgWidth() ~= 0 and chapter:GetBgWidth() or 1
        local high = chapter:GetBgHigh() ~= 0 and chapter:GetBgHigh() or 1
        self.StoryImgAspect.aspectRatio = width / high
    end
end

return XUiGridArchiveStory