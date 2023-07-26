-- 调色战争主界面
local XUiColorTableMain = XLuaUiManager.Register(XLuaUi, "UiColorTableMain")
local RewardAnimTime = 2000 -- 2000毫秒

function XUiColorTableMain:OnAwake()
    self.Timer = nil -- 倒计时定时器

    self:SetButtonCallBack()
    self:InitChapterBtnList()
    self:InitAssetPanel()
end

function XUiColorTableMain:OnStart()

end

function XUiColorTableMain:OnEnable()
    -- 界面动画
    self:PlayAnimation("Start", function(state)
        self:PlayAnimation("Loop", nil, nil, CS.UnityEngine.Playables.DirectorWrapMode.Loop)
    end)

    self:Refresh()
end

function XUiColorTableMain:OnDisable()
    self:StopTimer()
end

function XUiColorTableMain:SetButtonCallBack()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.Close)
    XUiHelper.RegisterClickEvent(self, self.BtnMainUi, function() XLuaUiManager.RunMain() end)
    XUiHelper.RegisterClickEvent(self, self.BtnShop, function() XDataCenter.ColorTableManager.OpenUiShop() end)
    XUiHelper.RegisterClickEvent(self, self.BtnTask, function() XLuaUiManager.Open("UiColorTableTask") end)
    XUiHelper.RegisterClickEvent(self, self.BtnStory, function() XLuaUiManager.Open("UiColorTableStory") end)
    XUiHelper.RegisterClickEvent(self, self.BtnRank, function() XLuaUiManager.Open("UiColorTableRank") end)
    XUiHelper.RegisterClickEvent(self, self.BtnContinue1, self.OnBtnContinueClick)
    XUiHelper.RegisterClickEvent(self, self.BtnContinue2, self.OnBtnContinueClick)
    XUiHelper.RegisterClickEvent(self, self.BtnBreak1, self.OnBtnBreakClick)
    XUiHelper.RegisterClickEvent(self, self.BtnBreak2, self.OnBtnBreakClick)
    self:BindHelpBtn(self.BtnHelp, XColorTableConfigs.GetUiMainHelpKey())
end

function XUiColorTableMain:Refresh()
    -- 活动倒计时
    self:StartTimer()

    -- 作战入口
    self:RefreshChapterUnlock()
    self:RefreshChapterProgress()
    self:RefreshChapterRed()

    -- 资源栏
    self:UpdateAssetPanel()

    -- 商店按钮
    self:RefreshBtnShop()

    -- 任务按钮
    local isTaskRed = XDataCenter.ColorTableManager.CheckTaskCanReward()
    self.BtnTask:ShowReddot(isTaskRed)

    -- 图鉴按钮
    local isStoryRed = XDataCenter.ColorTableManager.IsStoryRed()
    self.BtnStory:ShowReddot(isStoryRed)

    -- 是否作战中
    self:RefreshPlayingStage()
end

function XUiColorTableMain:StartTimer()
    if self.Timer then return end

    self:RefreshActivityTime()
    self.Timer = XScheduleManager.ScheduleForever(function()
        self:RefreshChapterUnlock()
        self:RefreshActivityTime()
    end, XScheduleManager.SECOND, 0)
end

function XUiColorTableMain:StopTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

function XUiColorTableMain:RefreshActivityTime()
    local endTime = XDataCenter.ColorTableManager.GetActivityEndTime()
    local nowTime = XTime.GetServerNowTimestamp()
    self.TxtTime.text = XUiHelper.GetTime(endTime - nowTime, XUiHelper.TimeFormatType.ACTIVITY)
    if nowTime >= endTime then
        XLuaUiManager.RunMain()
        XUiManager.TipMsg(XUiHelper.GetText("ActivityAlreadyOver"))
    end
end

---------------------------------------- 章节入口 begin ----------------------------------------

function XUiColorTableMain:InitChapterBtnList()
    local chapterConfigs = XColorTableConfigs.GetColorTableChapter()
    for i, config in ipairs(chapterConfigs) do
        local go = self["Chapter" .. i]
        local btnEntrance = go:GetObject("BtnEntrance")

        local tempIndex = i
        XUiHelper.RegisterClickEvent(self, btnEntrance, function() 
            self:OnBtnChapterClick(tempIndex)
        end)
    end
end

function XUiColorTableMain:OnBtnChapterClick(index)
    local chapterConfigs = XColorTableConfigs.GetColorTableChapter()
    local chapterConfig = chapterConfigs[index]
    local isInTime = chapterConfig.TimeId == 0 or XFunctionManager.CheckInTimeByTimeId(chapterConfig.TimeId)
    if not isInTime then
        XUiManager.TipText("ColorTableNoOpenTime")
        return
    end

    local isOpen = chapterConfig.ConditionId == 0 or XConditionManager.CheckCondition(chapterConfig.ConditionId)
    if not isOpen then
        XUiManager.TipText("ColorTableNoPassStage")
        return
    end

    local isChallenging = XDataCenter.ColorTableManager.IsChallenging()
    if isChallenging then
        XUiManager.TipText("ColorTableChallengingTips")
        return
    end

    XLuaUiManager.Open("UiColorTableChoicePlay", index)
end

function XUiColorTableMain:RefreshChapterUnlock()
    local isChallenging = XDataCenter.ColorTableManager.IsChallenging()
    local chapterConfigs = XColorTableConfigs.GetColorTableChapter()
    for i, config in ipairs(chapterConfigs) do
        local isLock = false
        local isInTime = config.TimeId == 0 or XFunctionManager.CheckInTimeByTimeId(config.TimeId)
        local textSuo = self["Chapter" .. i]:GetObject("TxtSuo")
        textSuo.text = ""
        if isInTime then
            if config.ConditionId ~= 0 then
                local isOpen, desc = XConditionManager.CheckCondition(config.ConditionId)
                if not isOpen then
                    isLock = true
                    textSuo.text = desc
                end
            end
        else
            isLock = true
            local startTime = XFunctionManager.GetStartTimeByTimeId(config.TimeId)
            local nowTime =  XTime.GetServerNowTimestamp()
            local showTime = XUiHelper.GetTime(startTime - nowTime, XUiHelper.TimeFormatType.ACTIVITY)
            textSuo.text = XUiHelper.GetText("SpecialTrainBreakthroughTimeHellMode", showTime)
        end

        -- 挑战中统一设置成disable
        if not isChallenging then
            local btnEntrance = self["Chapter" .. i]:GetObject("BtnEntrance")
            if btnEntrance.ButtonState ~= CS.UiButtonState.Press then 
                btnEntrance:SetDisable(isLock)
            end
        end
    end
end

-- 刷新通关进度
function XUiColorTableMain:RefreshChapterProgress()
    local chapterConfigs = XColorTableConfigs.GetColorTableChapter()
    for chapterId, _ in ipairs(chapterConfigs) do
        local norPassCnt, norAllCnt = XDataCenter.ColorTableManager.GetStageProgress(chapterId, XColorTableConfigs.StageDifficultyType.Normal)
        local difPassCnt, difAllCnt = XDataCenter.ColorTableManager.GetStageProgress(chapterId, XColorTableConfigs.StageDifficultyType.Difficult)
        local btnEntrance = self["Chapter" .. chapterId]:GetObject("BtnEntrance")
        btnEntrance:SetName((norPassCnt + difPassCnt) .. "/" .. (norAllCnt + difAllCnt))
    end
end

-- 刷新通关红点
function XUiColorTableMain:RefreshChapterRed()
    local chapterConfigs = XColorTableConfigs.GetColorTableChapter()
    for chapterId, _ in ipairs(chapterConfigs) do
        local isNormalRed = XDataCenter.ColorTableManager.IsShowProgressRed(chapterId, XColorTableConfigs.StageDifficultyType.Normal)
        local isDifficultRed = XDataCenter.ColorTableManager.IsShowProgressRed(chapterId, XColorTableConfigs.StageDifficultyType.Difficult)
        local btnEntrance = self["Chapter" .. chapterId]:GetObject("BtnEntrance")
        btnEntrance:ShowReddot(isNormalRed or isDifficultRed)
    end
end
---------------------------------------- 章节入口 end ----------------------------------------

---------------------------------------- 战斗中 begin ----------------------------------------

function XUiColorTableMain:RefreshPlayingStage()
    local isChallenging = XDataCenter.ColorTableManager.IsChallenging()
    local chapterConfigs = XColorTableConfigs.GetColorTableChapter()
    if isChallenging then
        local curStageId = XDataCenter.ColorTableManager.GetCurStageId()
        local curChapterId = XColorTableConfigs.GetStageChapterId(curStageId)
        for i, config in ipairs(chapterConfigs) do
            local btnEntrance = self["Chapter" .. i]:GetObject("BtnEntrance")
            btnEntrance:SetDisable(true)

            local imgSuo = self["Chapter" .. i]:GetObject("ImgSuo")
            imgSuo.gameObject:SetActiveEx(config.Id ~= curChapterId)
            
            local panelContinue = self["Chapter" .. i]:GetObject("PanelContinue")
            panelContinue.gameObject:SetActiveEx(config.Id == curChapterId)
        end
    else
        for i, config in ipairs(chapterConfigs) do
            local panelContinue = self["Chapter" .. i]:GetObject("PanelContinue")
            panelContinue.gameObject:SetActiveEx(false)
        end
    end
end

function XUiColorTableMain:OnBtnContinueClick()
    XDataCenter.ColorTableManager.EnterStageGame()
end

function XUiColorTableMain:OnBtnBreakClick()
    local title = XUiHelper.GetText("TipTitle")
    local stageConfig = XColorTableConfigs.GetColorTableStage()
    local curStageId = XDataCenter.ColorTableManager.GetCurStageId()
    local content = XUiHelper.GetText("ColorTableBreakFight", stageConfig[curStageId].Name)
    local sureCallback = function()
        XDataCenter.ColorTableManager.GiveUpGame(function()
            self:RefreshChapterUnlock()
            self:RefreshPlayingStage()
        end)
    end
    XLuaUiManager.Open("UiDialog", title, content, XUiManager.DialogType.Normal, nil, sureCallback)
end
---------------------------------------- 战斗中 end ----------------------------------------

---------------------------------------- 资源栏 begin ----------------------------------------

function XUiColorTableMain:InitAssetPanel()
    self.AssetActivityPanel = XUiPanelActivityAsset.New(self.PanelSpecialTool)
    XDataCenter.ItemManager.AddCountUpdateListener(
        {
            XDataCenter.ItemManager.ItemId.ColorTableCoin,
        },
        handler(self, self.UpdateAssetPanel),
        self.AssetActivityPanel
    )
end

function XUiColorTableMain:UpdateAssetPanel()
    self.AssetActivityPanel:Refresh(
        {
            XDataCenter.ItemManager.ItemId.ColorTableCoin,
        }
    )
end
---------------------------------------- 资源栏 end ----------------------------------------

function XUiColorTableMain:RefreshBtnShop()
    local shopIds = XDataCenter.ColorTableManager.GetActivityShopIds()
    XShopManager.GetShopInfoList(shopIds, function()
        local shopName
        for _, shopId in ipairs(shopIds) do
            local conditionIdList = XShopManager.GetShopConditionIdList(shopId)
            if conditionIdList and #conditionIdList > 0 then
                local isOpen = XConditionManager.CheckCondition(conditionIdList[1])
                if isOpen then
                    shopName = XShopManager.GetShopName(shopId)
                end
            else
                shopName = XShopManager.GetShopName(shopId)
            end
        end
        self.BtnShop:SetNameByGroup(0, shopName)

        XDataCenter.ColorTableManager.CheckShopUnlockTipsUi()
    end, XShopManager.ActivityShopType.ColortableShop)
end