local XUiGridArchive = require("XUi/XUiArchive/XUiGridArchive")
local XUiGridArchiveCG = require("XUi/XUiArchive/XUiGridArchiveCG")
---@class XUiGridArchiveComic: XUiNode
---@field private _Control XArchiveControl
local XUiGridArchiveComic = XClass(XUiGridArchiveCG, 'XUiGridArchiveComic')
local LockNameText = CS.XTextManager.GetText("ArchiveLockNameText")

function XUiGridArchiveComic:OnDisable()
    self:ClearReddotEvent()
end

---@overload
function XUiGridArchiveComic:UpdateGrid(chapterList, base, index)
    local chapter = chapterList and chapterList[index]

    self:ClearReddotEvent()
    
    if chapter then
        self.Chapter = chapter
        self.ChapterList = chapterList
        self:SetMonsterData(chapter)
        self.ReddotId = self:AddRedPointEvent(self.CGBtn,self.OnCheckArchiveRedPoint, self, { XRedPointConditions.Types.CONDITION_ARCHIVE_COMIC_RED }, self.Chapter.Id)

        self.Base = base
        self.CurIndex = index
    end
end

---@param chapter XTableArchiveComicChapter
---@overload
function XUiGridArchiveComic:SetMonsterData(chapter)
    self.IsUnLock, self.LockTips = self._Control.ComicControl:GetIsComicChapterUnlockForShow(chapter.Id)
    self.PanelLabelDynamic.gameObject:SetActiveEx(false)

    if not self.IsUnLock then
        if not string.IsNilOrEmpty(chapter.LockBg) then
            self.CGImg:SetRawImage(chapter.LockBg)
        end
        self.CGTitle.text = LockNameText
    else
        if not string.IsNilOrEmpty(chapter.Bg) then
            self.CGImg:SetRawImage(chapter.Bg)
        end
        self.CGTitle.text = chapter.Name
    end
end

---@overload
function XUiGridArchiveComic:OnBtnSelect()
    if not self.IsUnLock then
        if not string.IsNilOrEmpty(self.LockTips) then
            XUiManager.TipError(self.LockTips)
        end
        return
    end

    if not XTool.IsNumberValid(self.ChapterList[self.CurIndex].DetailCount) then
        XLog.Error('漫画章节Id：'..tostring(self.ChapterList[self.CurIndex].Id)..'的漫画数为0，请检查ArchiveComicDetail配置表')
        return
    end
    
    XLuaUiManager.Open("UiArchiveComicDetail", self.ChapterList[self.CurIndex], true)
end


function XUiGridArchiveComic:OnCheckArchiveRedPoint(count)
    self.CGBtn:ShowReddot(count >= 0)
end

function XUiGridArchiveComic:ClearReddotEvent()
    if self.ReddotId then
        self:RemoveRedPointEvent(self.ReddotId)
        self.ReddotId = nil
    end
end

return XUiGridArchiveComic