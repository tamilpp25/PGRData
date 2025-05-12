local XUiGridColorTableStory = XClass(nil, "UiGridColorTableStory")

local StageStoryType = {
    NormalWin = 1, -- 关卡普通胜利
    SpecialWin = 2, -- 关卡特殊胜利
    Start = 3, -- 关卡开头
}

function XUiGridColorTableStory:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)
    self:SetButtonCallBack()
end

function XUiGridColorTableStory:Refresh(base, handBookConfig)
    self.Base = base
    self.HandBookType = handBookConfig.Type
    self.IsUnlock = false

    if self.HandBookType == XColorTableConfigs.HandBookType.Event then
        self.Config = XColorTableConfigs.GetColorTableEvent(handBookConfig.EventId)
        self.IsUnlock = XDataCenter.ColorTableManager.IsHandbookUnlock(handBookConfig.Id)
    elseif self.HandBookType == XColorTableConfigs.HandBookType.Drama then
        self.Config = XColorTableConfigs.GetColorTableDrama(handBookConfig.DramaId)
        self.IsUnlock = XDataCenter.ColorTableManager.IsHandbookUnlock(handBookConfig.Id)
    elseif self.HandBookType == XColorTableConfigs.HandBookType.StageEndStory then
        self.Config = handBookConfig
        self.IsUnlock = XDataCenter.ColorTableManager.IsStagePassed(handBookConfig.StageId)

        local storyType = handBookConfig.StoryType
        if storyType == StageStoryType.NormalWin or storyType == StageStoryType.SpecialWin then
            local winType = storyType == StageStoryType.NormalWin and XColorTableConfigs.WinType.NormalWin or XColorTableConfigs.WinType.SpecialWin
            self.IsUnlock = self.IsUnlock or XDataCenter.ColorTableManager.IsPassWinType(handBookConfig.StageId, winType)
        else
            self.IsUnlock = self.IsUnlock or XDataCenter.ColorTableManager.IsStageMoviePlayed(handBookConfig.StageId)
        end
    end

    self.StoryImg:SetRawImage(self.Config.Icon)
    self.StoryTitle.text = self.Config.Name
    self.ImgLock.gameObject:SetActiveEx(not self.IsUnlock)
    if not self.IsUnlock then
        self.LockTips.text = handBookConfig.UnlockTips
    end

    self:RefreshRed()
end

function XUiGridColorTableStory:SetButtonCallBack()
    XUiHelper.RegisterClickEvent(self, self.StoryBtn, self.OnBtnPlayClicked)
end

function XUiGridColorTableStory:RefreshRed()
    local isRed = false
    if self.HandBookType == XColorTableConfigs.HandBookType.Drama then
        local isPlayed = XDataCenter.ColorTableManager.IsDramaPlayed(self.Config.Id)
        isRed = self.IsUnlock and not isPlayed
    end
    self.Red.gameObject:SetActiveEx(isRed)
end

function XUiGridColorTableStory:OnBtnPlayClicked()
    if not self.IsUnlock then
        return
    end

    -- 事件
    if self.HandBookType == XColorTableConfigs.HandBookType.Event then
        XLuaUiManager.Open("UiColorTableStageMainInfo", XColorTableConfigs.TipsType.EventTip, nil, self.Config.Id)

    -- 剧情
    elseif self.HandBookType == XColorTableConfigs.HandBookType.Drama then
        XLuaUiManager.Open("UiColorTableEnterMovie", self.Config.Id)

    -- 关卡结束剧情
    elseif self.HandBookType == XColorTableConfigs.HandBookType.StageEndStory then
        XLuaUiManager.Open("UiColorTableEnterMovie", nil, nil, self.Config.StoryId, self.Config.Name, self.Config.Desc, self.Config.Icon)
    end
end

function XUiGridColorTableStory:IsStageOneWin(stageId)
    local winCnt = 0
    local stageEndStoryConfig = XColorTableConfigs.GetColorTableStageEndStory()
    for i, config in ipairs(stageEndStoryConfig) do
        if config.StageId == stageId and (config.StoryType == StageStoryType.NormalWin or config.StoryType == StageStoryType.SpecialWin) then
            winCnt = winCnt + 1
        end
    end

    return winCnt == 1
end

return XUiGridColorTableStory
