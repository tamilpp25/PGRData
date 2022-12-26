local XUiGridFashionStoryTrial = XClass(nil, "UiGridFashionStoryTrial")

function XUiGridFashionStoryTrial:Ctor(ui, parent)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Parent = parent

    XTool.InitUiObject(self)
    self:AutoAddListener()
end

function XUiGridFashionStoryTrial:Refresh(stageId, activityId, entranceCb)
    if stageId == XFashionStoryConfigs.StoryEntranceId and activityId then
        self.IsStoryEntrance = true
        self.ActivityId = activityId
        self.EntranceCb = entranceCb
    else
        self.IsStoryEntrance = false
        self.ActivityId = nil
    end
    self.StageId = stageId
    self.BtnSummer:SetRawImage(self.IsStoryEntrance and XFashionStoryConfigs.GetStoryEntranceBg(activityId) or XFubenConfigs.GetStageIcon(stageId))
    self.ImageStoryProcess:SetSprite(self.IsStoryEntrance and XFashionStoryConfigs.GetStoryEntranceFinishTag(activityId) or XFashionStoryConfigs.GetTrialFinishTag(stageId))
    if self.IsStoryEntrance then
        local passNum, totalNum = XDataCenter.FashionStoryManager.GetChapterProgress(self.ActivityId)
        self.TxtStoryProcessNumber.text= string.format("%d/%d",passNum, totalNum)
        self.TxtStoryProcess.gameObject:SetActiveEx(true)
        self.PanelPass.gameObject:SetActiveEx(false)
    else
        local isPassed = XDataCenter.FubenManager.CheckStageIsPass(self.StageId)
        self.PanelPass.gameObject:SetActiveEx(isPassed)
        self.TxtStoryProcess.gameObject:SetActiveEx(false)
    end

    self:RefreshLeftTime()
end

function XUiGridFashionStoryTrial:AutoAddListener()
    self.BtnSummer.CallBack = function()
        self:OnClick()
    end
end

function XUiGridFashionStoryTrial:OnClick()
    if self.IsStoryEntrance then
        self.EntranceCb()
    else
        XEventManager.DispatchEvent(XEventId.EVENT_FASHION_STORY_OPEN_TRIAL_DETAIL, self.StageId)
    end
end

function XUiGridFashionStoryTrial:RefreshLeftTime()
    local leftTime
    if self.IsStoryEntrance then
        leftTime = XDataCenter.FashionStoryManager.GetStoryTimeStamp(self.ActivityId)
    else
        leftTime = XDataCenter.FashionStoryManager.GetTrialStageLeftTimeStamp(self.StageId)
    end

    -- 刷新剩余时间
    local func = function()
        leftTime = leftTime > 0 and leftTime or 0

        local strTime = XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.ACTIVITY)
        if self.TxtLeftTime then
            self.TxtLeftTime.text = CSXTextManagerGetText("FashionStoryTrialStageLeftTime", strTime)
        end

        if leftTime <= 0 then
            self:RemoveTimer()
            XEventManager.DispatchEvent(XEventId.EVENT_FASHION_STORY_TRIAL_REFRESH)
        end
    end

    func()
    self.Parent:RegisterTimerFun(self.StageId, function()
        leftTime = leftTime - 1
        func()
    end)
end

function XUiGridFashionStoryTrial:OnRecycle()
    self:RemoveTimer()
end

function XUiGridFashionStoryTrial:RemoveTimer()
    self.Parent:RemoveTimerFun(self.StageId)
end

return XUiGridFashionStoryTrial