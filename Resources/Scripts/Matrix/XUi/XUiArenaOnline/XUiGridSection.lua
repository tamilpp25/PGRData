local XUiGridSection = XClass(nil, "XUiGridSection")

function XUiGridSection:Ctor(ui, uiRoot)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.UiRoot = uiRoot

    XTool.InitUiObject(self)
    self:AutoAddListener()
    self.Canvas.sortingOrder = self.Canvas.sortingOrder + self.UiRoot:GetSortingOrder()
end

function XUiGridSection:AutoAddListener()
    self.BtnStage.CallBack = function() self:OnBtnStageClick() end
end

function XUiGridSection:OnBtnStageClick()
    if self.LeftTime ~= 0 then
        XUiManager.TipMsg(CS.XTextManager.GetText("ArenaOnlineSectionClose"))
        return
    end
    XDataCenter.ArenaOnlineManager.OpenArenaOnlineSection(self.ScetionId)
end

function XUiGridSection:Refresh(sectionId)
    if sectionId then
        self.ScetionId = sectionId
    end

    self:StopTimer()
    self.LeftTime = XDataCenter.ArenaOnlineManager.CheckSectionLeftTime(self.ScetionId)
    if self.LeftTime < 0 then
        self.PanelNor.gameObject:SetActiveEx(false)
        self.PanelLock.gameObject:SetActiveEx(false)
    elseif self.LeftTime == 0 then
        self:HandlerOpen()
    else
        self:HandlerClose()
    end
    self.PanelClear.gameObject:SetActiveEx(false)
    local path = XDataCenter.ArenaOnlineManager.GetCurSectionIcon(self.ScetionId)
    self.NorBg2:SetRawImage(path)
end

function XUiGridSection:HandlerOpen()
    self.PanelNor.gameObject:SetActiveEx(true)
    self.PanelLock.gameObject:SetActiveEx(false)

    local stars, allStars = XDataCenter.ArenaOnlineManager.GetStarInfoBySectionid(self.ScetionId)
    local passCount, allCount = XDataCenter.ArenaOnlineManager.GetStageScheduleByScetionId(self.ScetionId)
    self.TxtAllCollect.text = CS.XTextManager.GetText("ArenaOnlineStarDesc", allStars)
    self.TxtCollect.text = stars
    self.TxtStage.text = CS.XTextManager.GetText("ArenaOnlinePassDesc", passCount, allCount)
end

function XUiGridSection:HandlerClose()
    self.PanelNor.gameObject:SetActiveEx(false)
    self.PanelLock.gameObject:SetActiveEx(true)

    self.Timer = XScheduleManager.ScheduleForever(function()
        if XTool.UObjIsNil(self.Transform) then
            return
        end

        self.LeftTime = self.LeftTime - 1
        if self.LeftTime <= 0 then
            self:Refresh()
            return
        end

        local str = XUiHelper.GetTime(self.LeftTime, XUiHelper.TimeFormatType.DEFAULT)
        self.TxtLeftTime.text = CS.XTextManager.GetText("ArenaOnlineSectionLeftTime", str)
    end, XScheduleManager.SECOND, 0)
end

function XUiGridSection:StopTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

function XUiGridSection:OnDestroy()
    self:StopTimer()
end

return XUiGridSection