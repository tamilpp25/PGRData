local XUiGridMainLineBanner = XClass(nil, "XUiGridMainLineBanner")

function XUiGridMainLineBanner:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Transform3d = ui.transform
    XTool.InitUiObject(self)
    self.LockTxt = self.TxtLock.text
end

function XUiGridMainLineBanner:OnCheckRewards(count, chapterId)
    if self.ImgRewards and chapterId == self.Chapter.ChapterId then
        self.ImgRewards.gameObject:SetActive(count >= 0)
    end
end

function XUiGridMainLineBanner:RegisterClickEvent(uiNode, func)
    if func == nil then
        XLog.Error("XUiGridMainLineBanner:RegisterClickEvent函数参数错误：参数func不能为空")
        return
    end

    if type(func) ~= "function" then
        XLog.Error("XUiGridMainLineBanner:RegisterClickEvent函数错误, 参数func需要是function类型, func的类型是" .. type(func))
    end

    local listener = function(...)
        func(self, ...)
    end

    CsXUiHelper.RegisterClickEvent(uiNode, listener)
end

-- auto
-- chapter 组件内容更新
function XUiGridMainLineBanner:UpdateChapterGrid(chapterMain, difficulty)
    --初始状态
    self.PanelDegree1.gameObject:SetActive(false)
    self.PanelDegree2.gameObject:SetActive(false)
    self.PanelDegree3.gameObject:SetActive(false)

    local chapterInfo
    local isActivity

    --判断活动关卡
    chapterInfo = XDataCenter.FubenMainLineManager.GetChapterInfoByChapterMain(chapterMain.Id, difficulty)
    isActivity = chapterInfo.IsActivity
    self.PanelActivityTag.gameObject:SetActive(isActivity)

    -- 红点&判断新关卡
    if isActivity then
        self.PanelNewEffect.gameObject:SetActive(false)
    end

    --进度展示
    if difficulty == XDataCenter.FubenMainLineManager.DifficultNormal then
        self.PanelDegree1.gameObject:SetActive(true)
        XRedPointManager.CheckOnce(self.OnCheckRedPoint, self, { XRedPointConditions.Types.CONDITION_MAINLINE_CHAPTER_REWARD }, chapterMain.ChapterId[1])
        local checkNew = XDataCenter.FubenMainLineManager.CheckChapterNew(chapterMain.ChapterId[1])
        self.PanelNewEffect.gameObject:SetActive(checkNew)
    elseif difficulty == XDataCenter.FubenMainLineManager.DifficultHard then
        self.PanelDegree2.gameObject:SetActive(true)
        XRedPointManager.CheckOnce(self.OnCheckRedPoint, self, { XRedPointConditions.Types.CONDITION_MAINLINE_CHAPTER_REWARD }, chapterMain.ChapterId[2])
        local checkNew = XDataCenter.FubenMainLineManager.CheckChapterNew(chapterMain.ChapterId[2])
        self.PanelNewEffect.gameObject:SetActive(checkNew)
    end

    -- icon&标题
    self.RImgChapter:SetRawImage(chapterMain.Icon)
    self.TxtEN.text = chapterMain.ChapterEn
    self.TxtNum.text = string.format("%02d", chapterMain.OrderId)

    -- 普通关卡
    local progress = XDataCenter.FubenMainLineManager.GetProgressByChapterId(chapterMain.ChapterId[1])
    self.TxtPercentNormal.text = progress .. "%"
    self.ImgPercentNormal.fillAmount = progress / 100

    -- 困难关卡
    if chapterMain.ChapterId[2] and chapterMain.ChapterId[2] > 0 then
        progress = XDataCenter.FubenMainLineManager.GetProgressByChapterId(chapterMain.ChapterId[2])
        self.TxtPercentHard.text = progress .. "%"
        self.ImgPercentHard.fillAmount = progress / 100
    end

    -- 周目挑战标记
    local zhouMuNumber = XDataCenter.FubenZhouMuManager.GetZhouMuNumber(chapterMain.ZhouMuId)
    if zhouMuNumber <= 0 then
        self.PanelMultipleWeeksTag.gameObject:SetActiveEx(false)
    else
        self.PanelMultipleWeeksTag.gameObject:SetActiveEx(true)
        self.TextWeekNum.text = zhouMuNumber
    end

    --未解锁
    if chapterInfo and chapterInfo.Unlock then
        self.PanelChapterLock.gameObject:SetActive(false)
    else
        if isActivity then
            local chapterId = XDataCenter.FubenMainLineManager.GetChapterIdByChapterMain(chapterMain.Id, difficulty)
            local _, desc = XDataCenter.FubenMainLineManager.CheckActivityCondition(chapterId)
            self.TxtLock.text = desc
        else
            self.TxtLock.text = self.LockTxt
        end
        self.PanelChapterLock.gameObject:SetActive(true)
    end
end

function XUiGridMainLineBanner:OnCheckRedPoint(count)
    if self.ImgRedDot then
        self.ImgRedDot.gameObject:SetActive(count >= 0)
    end
end

return XUiGridMainLineBanner