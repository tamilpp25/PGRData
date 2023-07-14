local XUiGridChapterExtra = XClass(nil, "XUiGridChapterExtra")

function XUiGridChapterExtra:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self.LockTxt = self.TxtLock.text
end

function XUiGridChapterExtra:RefreshDatas(chapterCfg, difficulty)
    self.ChapterId = chapterCfg.ChapterId[difficulty]
    local chapterInfo = XDataCenter.ExtraChapterManager.GetChapterInfo(self.ChapterId)
    local isActivity = chapterInfo and chapterInfo.IsActivity
    self.PanelActivityTag.gameObject:SetActive(isActivity)
    local extraTitle = XDataCenter.ExtraChapterManager.GetChapterDetailsStageTitle(self.ChapterId)
    -- 红点&判断新关卡
    if isActivity then
        self.PanelNewEffect.gameObject:SetActive(false)
    end
    --初始状态
    self.PanelDegree1.gameObject:SetActive(false)
    self.PanelDegree2.gameObject:SetActive(false)
    self.PanelDegree3.gameObject:SetActive(false)

    --进度展示
    if difficulty == XDataCenter.FubenManager.DifficultNormal then
        self.PanelDegree1.gameObject:SetActive(true)
        XRedPointManager.CheckOnce(self.OnCheckRedPoint, self, { XRedPointConditions.Types.CONDITION_EXTRA_CHAPTER_REWARD }, chapterCfg.ChapterId[1])
        local checkNew = XDataCenter.ExtraChapterManager.CheckChapterNew(chapterCfg.ChapterId[1])
        self.PanelNewEffect.gameObject:SetActive(checkNew)
    elseif difficulty == XDataCenter.FubenManager.DifficultHard then
        self.PanelDegree2.gameObject:SetActive(true)
        XRedPointManager.CheckOnce(self.OnCheckRedPoint, self, { XRedPointConditions.Types.CONDITION_EXTRA_CHAPTER_REWARD }, chapterCfg.ChapterId[2])
        local checkNew = XDataCenter.ExtraChapterManager.CheckChapterNew(chapterCfg.ChapterId[2])
        self.PanelNewEffect.gameObject:SetActive(checkNew)
    end

    -- icon&标题
    self.RImgChapter:SetRawImage(chapterCfg.Icon)
    self.TxtEN.text = chapterCfg.ChapterEn
    self.TxtNum.text = string.format("%s", extraTitle)
    -- 普通关卡
    local progress = XDataCenter.ExtraChapterManager.GetProgressByChapterId(chapterCfg.ChapterId[1])
    self.TxtPercentNormal.text = progress .. "%"
    self.ImgPercentNormal.fillAmount = progress / 100

    -- 困难关卡
    progress = XDataCenter.ExtraChapterManager.GetProgressByChapterId(chapterCfg.ChapterId[2])
    self.TxtPercentHard.text = progress .. "%"
    self.ImgPercentHard.fillAmount = progress / 100

    -- 周目挑战标记
    local zhouMuNumber = XDataCenter.FubenZhouMuManager.GetZhouMuNumber(chapterCfg.ZhouMuId)
    if zhouMuNumber <= 0 then
        self.PanelMultipleWeeksTag.gameObject:SetActiveEx(false)
    else
        self.PanelMultipleWeeksTag.gameObject:SetActiveEx(true)
        self.TextWeekNum.text = zhouMuNumber
    end

    --未解锁
    if chapterInfo.Unlock then
        self.PanelChapterLock.gameObject:SetActive(false)
    else
        if isActivity then
            local isUnLock, desc = XDataCenter.ExtraChapterManager.CheckActivityCondition(chapterCfg.ChapterId[difficulty])
            self.TxtLock.text = desc
            self.PanelChapterLock.gameObject:SetActiveEx(not isUnLock)
            if isUnLock then
                XDataCenter.ExtraChapterManager.UnlockChapterViaActivity(chapterCfg.ChapterId[difficulty])
            end
        else
            self.TxtLock.text = self.LockTxt
            self.PanelChapterLock.gameObject:SetActiveEx(true)
        end
    end
end

function XUiGridChapterExtra:OnCheckRedPoint(count)
    if self.ImgRedDot then
        self.ImgRedDot.gameObject:SetActive(count >= 0)
    end
end

function XUiGridChapterExtra:OnCheckRewards(count, chapterId)
    if self.ImgRewards and chapterId == self.Chapter.ChapterId then
        self.ImgRewards.gameObject:SetActive(count >= 0)
    end
end

return XUiGridChapterExtra