local XUiGridChapterDP = XClass(nil,"XUiGridChapterDP")

function XUiGridChapterDP:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self.LockTxt = self.TxtLock.text
end 

function XUiGridChapterDP:Refresh(chapterCfg, difficulty)
    self.ChapterId = chapterCfg.ChapterId
    local isActivity = XDataCenter.ShortStoryChapterManager.IsActivity(self.ChapterId)
    self.PanelActivityTag.gameObject:SetActiveEx(isActivity)
    -- 判断新关卡
    if isActivity then
        self.PanelNewEffect.gameObject:SetActiveEx(false)
    end
    --初始状态
    self.PanelDegree1.gameObject:SetActiveEx(false)
    self.PanelDegree2.gameObject:SetActiveEx(false)
    self.PanelDegree3.gameObject:SetActiveEx(false)
    --红点
    XRedPointManager.CheckOnce(self.OnCheckRedPoint, self, { XRedPointConditions.Types.CONDITION_SHORT_STORY_CHAPTER_REWARD }, self.ChapterId)
    
    local checkNew = XDataCenter.ShortStoryChapterManager.CheckChapterNew(self.ChapterId)
    self.PanelNewEffect.gameObject:SetActiveEx(checkNew)
    --进度展示
    local progress = XDataCenter.ShortStoryChapterManager.GetProgressByChapterId(self.ChapterId)
    
    if difficulty == XDataCenter.FubenManager.DifficultNormal then
        self.PanelDegree1.gameObject:SetActiveEx(true)
        -- 普通关卡
        self.TxtPercentNormal.text = progress .. "%"
        self.ImgPercentNormal.fillAmount = progress / 100
    elseif difficulty == XDataCenter.FubenManager.DifficultHard then
        self.PanelDegree2.gameObject:SetActiveEx(true)
        -- 困难关卡
        self.TxtPercentHard.text = progress .. "%"
        self.ImgPercentHard.fillAmount = progress / 100
    end

    -- icon&标题
    local chapterMainId = XFubenShortStoryChapterConfigs.GetChapterMainIdByChapterId(self.ChapterId)
    local icon = XFubenShortStoryChapterConfigs.GetIconById(chapterMainId)
    local chapterEn = XFubenShortStoryChapterConfigs.GetChapterEnById(chapterMainId)
    local extraTitle = XFubenShortStoryChapterConfigs.GetStageTitleByChapterId(self.ChapterId)
    self.RImgChapter:SetRawImage(icon)
    self.TxtEN.text = chapterEn
    self.TxtNum.text = string.format("%s", extraTitle)

    -- 周目挑战标记
    local zhouMuId = XFubenShortStoryChapterConfigs.GetZhouMuId(chapterMainId)
    local zhouMuNumber = XDataCenter.FubenZhouMuManager.GetZhouMuNumber(zhouMuId)
    if zhouMuNumber <= 0 then
        self.PanelMultipleWeeksTag.gameObject:SetActiveEx(false)
    else
        self.PanelMultipleWeeksTag.gameObject:SetActiveEx(true)
        self.TextWeekNum.text = zhouMuNumber
    end

    --未解锁
    local unlock = XDataCenter.ShortStoryChapterManager.IsUnlock(self.ChapterId)
    if unlock then
        self.PanelChapterLock.gameObject:SetActiveEx(false)
    else
        if isActivity then
            local isUnLock, desc = XDataCenter.ShortStoryChapterManager.CheckActivityCondition(self.ChapterId)
            self.TxtLock.text = desc
            self.PanelChapterLock.gameObject:SetActiveEx(not isUnLock)
            if isUnLock then
                XDataCenter.ShortStoryChapterManager.UnlockChapterViaActivity(self.ChapterId)
            end
        else
            self.TxtLock.text = self.LockTxt
            self.PanelChapterLock.gameObject:SetActiveEx(true)
        end
    end
end

function XUiGridChapterDP:OnCheckRedPoint(count)
    if self.ImgRedDot then
        self.ImgRedDot.gameObject:SetActiveEx(count >= 0)
    end
end

return XUiGridChapterDP