local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
---@class XUiPcgMain : XLuaUi
---@field private _Control XPcgControl
local XUiPcgMain = XLuaUiManager.Register(XLuaUi, "UiPcgMain")

function XUiPcgMain:OnAwake()
    self:RegisterUiEvents()
    self:InitTimer()
    self:InitChapterList()
end

function XUiPcgMain:OnStart()
end

function XUiPcgMain:OnEnable()
    self:Refresh()
end

function XUiPcgMain:OnDisable()
end

function XUiPcgMain:OnDestroy()
    self:ClearTimer()
end

function XUiPcgMain:RegisterUiEvents()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
    self:BindHelpBtn(self.BtnHelp, self._Control:GetClientConfig("HelpKey"))
    self:RegisterClickEvent(self.BtnPicture, self.OnBtnPictureClick)
    self:RegisterClickEvent(self.BtnTask, self.OnBtnTaskClick)
end

function XUiPcgMain:OnBtnBackClick()
    self:Close()
end

function XUiPcgMain:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiPcgMain:OnBtnPictureClick()
    XLuaUiManager.Open("UiPcgPicture")
end

function XUiPcgMain:OnBtnTaskClick()
    XLuaUiManager.Open("UiPcgTask")
end

-- 初始化定时器
function XUiPcgMain:InitTimer()
    self:ClearTimer()
    self.EndTime = self._Control:GetActivityEndTime()
    self.Timer = XScheduleManager.ScheduleForever(function()
        local isClose = self.EndTime < XTime.GetServerNowTimestamp()
        if isClose then
            self._Control:HandleActivityEnd()
        else
            self:RefreshTime()
            self:RefreshChapterList()
        end
    end, XScheduleManager.SECOND)
end

-- 清除定时器
function XUiPcgMain:ClearTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

-- 刷新界面
function XUiPcgMain:Refresh()
    self:RefreshTime()
    self:RefreshChapterList()
    self:RefreshBtnTask()
    self:RefreshBtnPicture()
end

-- 刷新时间
function XUiPcgMain:RefreshTime()
    local gameTime = self.EndTime - XTime.GetServerNowTimestamp()
    if gameTime < 0 then gameTime = 0 end
    self.TxtTime.text = XUiHelper.GetTime(gameTime, XUiHelper.TimeFormatType.ACTIVITY)
end

function XUiPcgMain:InitChapterList()
    self.ChapterCfgs = self._Control:GetActivityChapterConfigs()
    for i, _ in ipairs(self.ChapterCfgs) do
        -- 点击事件
        local index = i
        local uiObj = self["Chapter"..i]
        local button = uiObj:GetObject("Button")
        self:RegisterClickEvent(button, function()
            self:OnChapterClick(index)
        end)
    end
end

-- 刷新章节列表
function XUiPcgMain:RefreshChapterList()
    for i, _ in ipairs(self.ChapterCfgs) do
        self:RefreshChapter(i)
    end
end

-- 刷新单个章节UI
function XUiPcgMain:RefreshChapter(index)
    local cfg = self.ChapterCfgs[index]
    local uiObj = self["Chapter"..index]
    local curChapterId = self._Control:GetCurrentChapterId()
    local isUnlock, tips = self._Control:IsChapterUnlock(cfg.Id)
    local isPassed = self._Control:IsChapterPassed(cfg.Id)
    local isRed = self._Control:IsChapterShowRed(cfg.Id)
    local curStar, allStar = self._Control:GetChapterStarCount(cfg.Id)
    local progressTxt = self._Control:GetClientConfig("ChapterProgressTxt")
    local isClear = isPassed and curStar >= allStar
    uiObj:GetObject("TxtName").text = cfg.Name
    uiObj:GetObject("TagOngoing").gameObject:SetActiveEx(curChapterId == cfg.Id)
    uiObj:GetObject("TagClear").gameObject:SetActiveEx(isClear)
    uiObj:GetObject("TxtStarNum").text = string.format(progressTxt, curStar, allStar)
    uiObj:GetObject("Red").gameObject:SetActiveEx(isRed)
    uiObj:GetObject("PanelLock").gameObject:SetActiveEx(not isUnlock)
    if not isUnlock then
        uiObj:GetObject("TxtTips").text = tips
    end
end

-- 点击章节回调
function XUiPcgMain:OnChapterClick(index)
    local chapterCfg = self.ChapterCfgs[index]
    local chapterId = chapterCfg.Id
    local isUnlock, lockTips = self._Control:IsChapterUnlock(chapterId)
    if not isUnlock then
        XUiManager.TipError(lockTips)
        return
    end
    
    -- 有非此章节的关卡进行中
    local curChapterId = self._Control:GetCurrentChapterId()
    if XTool.IsNumberValid(curChapterId) and chapterId ~= curChapterId then
        local failTips = self._Control:GetClientConfig("ChallengeFailTips")
        XUiManager.TipError(failTips)
        return
    end
    
    self._Control:SetChapterEntered(chapterId)
    XLuaUiManager.Open("UiPcgStage", chapterId, index)
end

-- 刷新任务按钮
function XUiPcgMain:RefreshBtnTask()
    local isRed = self._Control:IsTaskShowRed()
    self.BtnTask:ShowReddot(isRed)

    self.Grid256New.gameObject:SetActiveEx(false)
    local rewardId = self._Control:GetActivityRewardId()
    local rewardItems = XRewardManager.GetRewardList(rewardId)
    self.Items = self.Items or {}
    XUiHelper.CreateTemplates(self, self.Items, rewardItems, XUiGridCommon.New, self.Grid256New, self.Grid256New.transform.parent, function(grid, data)
        grid:Refresh(data, nil, nil, false)
    end)
end

-- 刷新图鉴按钮
function XUiPcgMain:RefreshBtnPicture()
    local isRed = false
    local characterCfgs = self._Control:GetConfigCharacter()
    for _, characterCfg in pairs(characterCfgs) do
        if self._Control:IsCharacterShowRed(characterCfg.Id) then
            isRed = true
            break
        end
    end
    self.BtnPicture:ShowReddot(isRed)
end


return XUiPcgMain
