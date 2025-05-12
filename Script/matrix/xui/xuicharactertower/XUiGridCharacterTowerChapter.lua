local XUiGridCharacter = require("XUi/XUiCharacter/XUiGridCharacter")
---@class XUiGridCharacterTowerChapter
local XUiGridCharacterTowerChapter = XClass(nil, "XUiGridCharacterTowerChapter")

function XUiGridCharacterTowerChapter:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)
    XUiHelper.RegisterClickEvent(self, self.BtnGrid, self.OnBtnGridClick)
end

function XUiGridCharacterTowerChapter:Refresh(chapterId)
    self.ChapterId = chapterId
    ---@type XCharacterTowerChapter
    self.ChapterViewModel = XDataCenter.CharacterTowerManager.GetCharacterTowerChapter(chapterId)
    -- 活动中标识和时间隐藏
    local isInActivity = false
    self.PanelTag.gameObject:SetActiveEx(isInActivity)
    self.NormalImgTxt.gameObject:SetActiveEx(isInActivity)
    self.PressImgTxt.gameObject:SetActiveEx(isInActivity)
    if isInActivity then
        self.ActivityTimeId = self.ChapterViewModel:GetChapterActivityTimeId()
        self:StartTimer()
    else
        self:StopTimer()
    end
    self.BtnGrid:SetRawImage(self.ChapterViewModel:GetChapterImg())
    self.BtnGrid:SetNameByGroup(1, self.ChapterViewModel:GetChapterTitle())
    local finishCount, totalCount = self.ChapterViewModel:GetChapterProgress()
    self.BtnGrid:SetNameByGroup(2, string.format("%s/%s", finishCount, totalCount))
    local isOpen, desc = self.ChapterViewModel:CheckChapterCondition()
    self.BtnGrid:SetButtonState(isOpen and CS.UiButtonState.Normal or CS.UiButtonState.Disable)
    self.BtnGrid:SetNameByGroup(3, desc)
    -- 红点
    local redPoint = XDataCenter.CharacterTowerManager.CheckRedPointByChapterId(chapterId)
    self.BtnGrid:ShowReddot(redPoint)
end

function XUiGridCharacterTowerChapter:OnBtnGridClick()
    self.RootUi:OpenChapterUi(self.ChapterId)
end

-- 活动结束
function XUiGridCharacterTowerChapter:OnActivityEnd()
    self.PanelTag.gameObject:SetActiveEx(false)
    self.NormalImgTxt.gameObject:SetActiveEx(false)
    self.PressImgTxt.gameObject:SetActiveEx(false)
end

function XUiGridCharacterTowerChapter:StartTimer()
    if self.Timer then
        self:StopTimer()
    end

    self:UpdateTimer()
    self.Timer = XScheduleManager.ScheduleForever(function()
        self:UpdateTimer()
    end, XScheduleManager.SECOND)
end

function XUiGridCharacterTowerChapter:UpdateTimer()
    if not self.GameObject or not self.GameObject:Exist() then
        self:StopTimer()
        return
    end

    local endTime = XFunctionManager.GetEndTimeByTimeId(self.ActivityTimeId)
    local leftTime = endTime - XTime.GetServerNowTimestamp()
    if leftTime <= 0 then
        self:StopTimer()
        -- 活动结束
        self:OnActivityEnd()
        return
    end
    local timeText = XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.DEFAULT)
    self.BtnGrid:SetNameByGroup(0, XUiHelper.GetText("CharacterTowerChapterInActivityDesc", timeText))
end

function XUiGridCharacterTowerChapter:StopTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

function XUiGridCharacterTowerChapter:OnClose()
    self:StopTimer()
end

return XUiGridCharacterTowerChapter