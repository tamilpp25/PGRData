local CsXTextManagerGetText = CsXTextManagerGetText

--章节控件
local XUiGridChapter = XClass(nil, "XUiGridChapter")

function XUiGridChapter:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)
end

function XUiGridChapter:Init(rootUi)
    self.RootUi = rootUi
end

function XUiGridChapter:Refresh(chapterId, index)
    --进度
    local passCount, allCount = XDataCenter.FubenCoupleCombatManager.GetStageSchedule(chapterId)
    local progress = passCount .. "/" .. allCount
    self.GridChapter:SetNameByGroup(0, progress)
    for _, image in pairs(self.GridChapter.ImageList) do
        image.fillAmount = passCount / allCount
    end

    local isUnlock, conditionDes = XDataCenter.FubenCoupleCombatManager.CheckChapterUnlock(chapterId)
    self.GridChapter:SetDisable(not isUnlock, isUnlock)

    if not isUnlock then
        self.Time2.text = conditionDes
    end

    self:UpdateTimer(chapterId)
end

function XUiGridChapter:UpdateTimer(chapterId)
    self:StopTimer()

    local isUnlock, conditionDes = XDataCenter.FubenCoupleCombatManager.CheckChapterUnlock(chapterId)
    if isUnlock then
        return
    end

    self.Timer = XScheduleManager.ScheduleForever(function()
        isUnlock, conditionDes = XDataCenter.FubenCoupleCombatManager.CheckChapterUnlock(chapterId)
        if isUnlock then
            self.GridChapter:SetDisable(not isUnlock, isUnlock)
            self:StopTimer()
            return
        end
        self.Time2.text = conditionDes
    end, XScheduleManager.SECOND, 0)
end

function XUiGridChapter:StopTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

return XUiGridChapter