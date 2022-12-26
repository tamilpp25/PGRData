XUiGridArchiveCG = XClass(nil, "XUiGridArchiveCG")
local Rect = CS.UnityEngine.Rect(1, 1, 1, 1)
local LockNameText = CS.XTextManager.GetText("ArchiveLockNameText")
local LockCGIconAspectRatio = CS.XGame.ClientConfig:GetFloat("LockStoryIconAspectRatio")
function XUiGridArchiveCG:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self:SetButtonCallBack()
end

function XUiGridArchiveCG:SetButtonCallBack()
    self.CGBtn.CallBack = function()
        self:OnBtnSelect()
    end
end

function XUiGridArchiveCG:OnBtnSelect()
    if self.Chapter:GetIsLock() then
        XUiManager.TipError(self.Chapter:GetLockDesc())
        return
    end
    XLuaUiManager.Open("UiArchiveCGDetail", self.ChapterList, self.CurIndex)
end

function XUiGridArchiveCG:UpdateGrid(chapterList, base, index)
    local chapter = chapterList and chapterList[index]
    if chapter then
        self.Chapter = chapter
        self.ChapterList = chapterList
        self:SetMonsterData(chapter)
        self:CheckRedPoint(chapter:GetId())
        self.Base = base
        self.CurIndex = index
    end
end

function XUiGridArchiveCG:SetMonsterData(chapter)
    if chapter:GetIsLock() then
        if chapter:GetLockBg() and #chapter:GetLockBg() > 0 then
            self.CGImg:SetRawImage(chapter:GetLockBg())
        end
        self.CGTitle.text = LockNameText
        Rect.x = 0
        Rect.y = 0
        self.CGImg.uvRect = Rect
        self.CGImgAspect.aspectRatio = LockCGIconAspectRatio
        self.PanelLabelDynamic.gameObject:SetActiveEx(false)
    else
        local spineBg = chapter:GetSpineBg()
        if spineBg and spineBg ~= "" then
            self.PanelLabelDynamic.gameObject:SetActiveEx(true)
        else
            self.PanelLabelDynamic.gameObject:SetActiveEx(false)
        end
        if chapter:GetBg() and #chapter:GetBg() > 0 then
            self.CGImg:SetRawImage(chapter:GetBg())
        end
        self.CGTitle.text = chapter:GetName()
        Rect.x = chapter:GetBgOffSetX() / 100
        Rect.y = chapter:GetBgOffSetY() / 100
        self.CGImg.uvRect = Rect
        local width = chapter:GetBgWidth() ~= 0 and chapter:GetBgWidth() or 1
        local high = chapter:GetBgHigh() ~= 0 and chapter:GetBgHigh() or 1
        self.CGImgAspect.aspectRatio = width / high
    end
end

function XUiGridArchiveCG:CheckRedPoint(id)
    XRedPointManager.CheckOnce(
        self.OnCheckArchiveRedPoint,
        self,
        { XRedPointConditions.Types.CONDITION_ARCHIVE_CG_RED },
        id
    )
end

function XUiGridArchiveCG:OnCheckArchiveRedPoint(count)
    self.CGBtn:ShowReddot(count >= 0)
end