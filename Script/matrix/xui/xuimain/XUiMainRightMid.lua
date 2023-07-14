local CSXTextManagerGetText = CS.XTextManager.GetText
local DefaultType = 1
local tableInsert = table.insert
local BtnActivityEntryMaxCount = 3

local RegressionMainViewFreshTimeInterval = CS.XGame.ClientConfig:GetInt("RegressionMainViewFreshTimeInterval")

local XUiMainRightMid = XClass(nil, "XUiMainRightMid")

function XUiMainRightMid:Ctor(rootUi)
    self.RootUi = rootUi
    self.Transform = rootUi.PanelRightMid.gameObject.transform
    XTool.InitUiObject(self)
    --ClickEvent
    self.BtnFight.CallBack = function() self:OnBtnFight() end
    self.BtnTask.CallBack = function() self:OnBtnTask() end
    self.BtnBuilding.CallBack = function() self:OnBtnBuilding() end
    self.BtnReward.CallBack = function() self:OnBtnReward() end
    self.BtnSkipTask.CallBack = function() self:OnBtnSkipTask() end
    self.BtnActivityBrief.CallBack = function() self:OnBtnActivityBrief() end
    self.BtnPartner.CallBack = function() self:OnBtnPartner() end
    self.BtnGuild.CallBack = function() self:OnBtnGuildClick() end
    self.BtnGuild.gameObject:SetActiveEx(true)

    if XUiManager.IsHideFunc then
        self.BtnActivityBrief.gameObject:SetActiveEx(false)
        self.BtnGuild.gameObject:SetActiveEx(false)
        self.BtnBuilding.gameObject:SetActiveEx(false)
        self.BtnReward.gameObject:SetActiveEx(false)
    end

    -- 已经移到 PanelDown 区域中
    self.BtnTarget.CallBack = function() self:OnBtnTarget() end
    self.BtnRegression.CallBack = function() self:OnBtnRegression() end
    if self.BtnSpecialShop then
        self.BtnSpecialShop.CallBack = function() self:OnBtnSpecialShop() end
    end

    --RedPoint
    XRedPointManager.AddRedPointEvent(self.BtnTask.ReddotObj, self.OnCheckTaskNews, self, { XRedPointConditions.Types.CONDITION_MAIN_TASK })
    XRedPointManager.AddRedPointEvent(self.BtnTarget.ReddotObj, self.OnCheckTargetNews, self, { XRedPointConditions.Types.CONDITION_MAIN_NEWPLAYER_TASK })
    XRedPointManager.AddRedPointEvent(self.BtnBuilding.ReddotObj, self.OnCheckBuildingNews, self, { XRedPointConditions.Types.CONDITION_DORM_RED })
    --XRedPointManager.AddRedPointEvent(self.BtnReward.ReddotObj, self.OnCheckARewardNews, self, { XRedPointConditions.Types.CONDITION_ACTIVITYDRAW_RED })
    -- XRedPointManager.AddRedPointEvent(self.BtnActivityBrief, self.OnCheckActivityBriefRedPoint, self, { XRedPointConditions.Types.CONDITION_ACTIVITY_NEW_MAINENTRY })
    XRedPointManager.AddRedPointEvent(self.BtnRegression.ReddotObj, nil, self, { XRedPointConditions.Types.CONDITION_REGRESSION })
    XRedPointManager.AddRedPointEvent(self.ImgBuldingRedDot, self.OnCheckGuildRedPoint, self,
    {
        XRedPointConditions.Types.CONDITION_GUILD_APPLYLIST,
        XRedPointConditions.Types.CONDITION_GUILD_ACTIVEGIFT,
        XRedPointConditions.Types.CONDITION_GUILD_NEWS,
        XRedPointConditions.Types.CONDITION_GUILDBOSS_BOSSHP,
        XRedPointConditions.Types.CONDITION_GUILDBOSS_SCORE,
        XRedPointConditions.Types.CONDITION_GUILDWAR_TASK,
    })

    XRedPointManager.AddRedPointEvent(self.BtnPartner, self.OnCheckPartnerRedPoint, self,
    {
        XRedPointConditions.Types.CONDITION_PARTNER_COMPOSE_RED,
        XRedPointConditions.Types.CONDITION_PARTNER_NEWSKILL_RED,
    })

    self.SpecialShopRed = XRedPointManager.AddRedPointEvent(self.BtnSpecialShop.ReddotObj, self.OnCheckSpecialShopRedPoint, self, { XRedPointConditions.Types.CONDITION_MAIN_SPECIAL_SHOP })


    --Filter
    self:CheckFilterFunctions()
    self:InitBtnActivityEntry()
end

function XUiMainRightMid:OnEnable()
    XEventManager.AddEventListener(XEventId.EVENT_NOTICE_TASKINITFINISHED, self.OnInitTaskFinished, self)
    XEventManager.AddEventListener(XEventId.EVENT_DRAW_ACTIVITYCOUNT_CHANGE, self.CheckDrawTag, self)
    --XEventManager.AddEventListener(XEventId.EVENT_TASKFORCE_INFO_NOTIFY, self.SetupDispatch, self)
    XEventManager.AddEventListener(XEventId.EVENT_REGRESSION_OPEN_STATUS_UPDATE, self.OnRegressionOpenStatusUpdate, self)
    self:RefreshFubenProgress()
    self:UpdateStoryTaskBtn()
    self:UpdateBtnActivityBrief()
    self:UpdateBtnActivityEntry()
    self:CheckDrawTag()
    self:OnRegressionOpenStatusUpdate()
    self:BtnSpecialShopUpdate()
    if XDataCenter.RegressionManager.IsHaveOneRegressionActivityOpen() then
        self:UpdateRegressionLeftTime()
        if not self.RegressionTimeSchedule then
            self.RegressionTimeSchedule = XScheduleManager.ScheduleForever(function()
                self:UpdateRegressionLeftTime()
            end, RegressionMainViewFreshTimeInterval * XScheduleManager.SECOND)
        end
    else
        self.TxtRegressionLeftTime.gameObject:SetActiveEx(false)
    end

    local livingQuarters = XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.Dorm)
    local drawCard = XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.DrawCard)
    local partner = XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.Partner)
    --初始化是否锁定
    self.BtnBuilding:SetDisable(not livingQuarters)
    self.BtnReward:SetDisable(not drawCard)
    self.BtnPartner:SetDisable(not partner)

    if self.BtnTarget and (not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.Target) and not XUiManager.IsHideFunc) then
        self.BtnTarget.gameObject:SetActiveEx(XDataCenter.TaskManager.CheckNewbieTaskAvailable())
    end

    self:CheckGuildOpen()
    XDataCenter.DormManager.StartDormRedTimer() -- 优化

    self:CheckStartActivityEntryTimer()
    self:CheckBtnActivityEntryRedPoint()
end

function XUiMainRightMid:CheckGuildOpen()
    if XUiManager.IsHideFunc then return end

    local guildOpen = XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.Guild)
    self.BtnGuild:SetDisable(not guildOpen)

    -- PS: 这里因为删除XFunctionManager.IsDuringTime方法，因此直接设置为true
    local guildIsDuringTime = true -- XFunctionManager.IsDuringTime(XFunctionManager.FunctionName.Guild)
    self.BtnGuild.gameObject:SetActiveEx(guildIsDuringTime)
end

function XUiMainRightMid:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_NOTICE_TASKINITFINISHED, self.OnInitTaskFinished, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_DRAW_ACTIVITYCOUNT_CHANGE, self.CheckDrawTag, self)
    --XEventManager.RemoveEventListener(XEventId.EVENT_TASKFORCE_INFO_NOTIFY, self.SetupDispatch, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_REGRESSION_OPEN_STATUS_UPDATE, self.OnRegressionOpenStatusUpdate, self)

    if self.guildTimer then
        XScheduleManager.UnSchedule(self.guildTimer)
        self.guildTimer = nil
    end

    if self.RegressionTimeSchedule then
        XScheduleManager.UnSchedule(self.RegressionTimeSchedule)
        self.RegressionTimeSchedule = nil
    end
    XDataCenter.DormManager.StopDormRedTimer()
    self:StopActivityEntryTimer()
end

function XUiMainRightMid:OnNotify(evt)
    if evt == XEventId.EVENT_TASKFORCE_INFO_NOTIFY then
        --更新派遣
        self:SetupDispatch()
    end
end

function XUiMainRightMid:UpdateRegressionLeftTime()
    local targetTime = XDataCenter.RegressionManager.GetTaskEndTime()
    if not targetTime then
        if self.RegressionTimeSchedule then
            XScheduleManager.UnSchedule(self.RegressionTimeSchedule)
            self.RegressionTimeSchedule = nil
        end
        self.TxtRegressionLeftTime.gameObject:SetActiveEx(false)
        return
    end
    local leftTime = targetTime - XTime.GetServerNowTimestamp()
    if leftTime > 0 then
        self.TxtRegressionLeftTime.text = XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.MAINBATTERY)
        self.TxtRegressionLeftTime.gameObject:SetActiveEx(true)
    elseif self.RegressionTimeSchedule then
        self.TxtRegressionLeftTime.gameObject:SetActiveEx(false)
        if self.RegressionTimeSchedule then
            XScheduleManager.UnSchedule(self.RegressionTimeSchedule)
        end
        self.RegressionTimeSchedule = nil
    end
end

function XUiMainRightMid:CheckFilterFunctions()
    self.BtnTarget.gameObject:SetActiveEx(not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.Target) and not XUiManager.IsHideFunc)
    self.BtnTask.gameObject:SetActiveEx(not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.Task))
    self.BtnSkipTask.gameObject:SetActiveEx(not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.TaskStory))
    self.BtnPartner.gameObject:SetActiveEx(not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.Partner) and not XUiManager.IsHideFunc)
    if not XUiManager.IsHideFunc then
        self.BtnBuilding.gameObject:SetActiveEx(not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.Dorm))
        self.BtnReward.gameObject:SetActiveEx(not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.DrawCard))
        self.BtnActivityBrief.gameObject:SetActiveEx(not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.ActivityBrief))
    end
end

--新手目标入口
function XUiMainRightMid:OnBtnTarget()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Target) then
        return
    end
    XLuaUiManager.Open("UiNewPlayerTask")
end

---
--- 特殊商店入口点击
function XUiMainRightMid:OnBtnSpecialShop()
    XSaveTool.SaveData(string.format("%d%s", XPlayer.Id, "SpecialShopAlreadyIn"), true)

    if XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.ShopCommon)
    or XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.ShopActive) then

        local shopId = XSpecialShopConfigs.GetShopId()
        XShopManager.GetShopInfo(shopId, function()
            XLuaUiManager.Open("UiSpecialFashionShop", shopId)
        end)
    end

    XRedPointManager.Check(self.SpecialShopRed)
end

--副本入口
function XUiMainRightMid:OnBtnFight()
    XLuaUiManager.Open("UiFuben")
end

--任务入口
function XUiMainRightMid:OnBtnTask()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Task) then
        return
    end
    XLuaUiManager.Open("UiTask")
end

--任务跳转按钮点击
function XUiMainRightMid:OnBtnSkipTask()
    if not self.ShowTaskId or self.ShowTaskId <= 0 then
        XLuaUiManager.Open("UiTask", XDataCenter.TaskManager.TaskType.Story)
    else
        local taskData = XDataCenter.TaskManager.GetTaskDataById(self.ShowTaskId)
        local needSkip = taskData and taskData.State < XDataCenter.TaskManager.TaskState.Achieved
        if needSkip then
            if XDataCenter.RoomManager.RoomData ~= nil then
                local title = CSXTextManagerGetText("TipTitle")
                local cancelMatchMsg = CSXTextManagerGetText("OnlineInstanceQuitRoom")
                XUiManager.DialogTip(title, cancelMatchMsg, XUiManager.DialogType.Normal, nil, function()
                    XLuaUiManager.RunMain()
                    local skipId = XDataCenter.TaskManager.GetTaskTemplate(self.ShowTaskId).SkipId
                    XFunctionManager.SkipInterface(skipId)
                end)
            else
                local skipId = XDataCenter.TaskManager.GetTaskTemplate(self.ShowTaskId).SkipId
                XFunctionManager.SkipInterface(skipId)
            end
        else
            XLuaUiManager.Open("UiTask", XDataCenter.TaskManager.TaskType.Story)
        end
    end
end

--宿舍入口
function XUiMainRightMid:OnBtnBuilding()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Dorm) then
        return
    end

    self.RootUi:ChangeLowPowerState(self.RootUi.LowPowerState.None)
    XHomeDormManager.EnterDorm()
end

--研发入口
function XUiMainRightMid:OnBtnReward()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.DrawCard) then
        return
    end
    XDataCenter.DrawManager.MarkActivityDraw()
    XLuaUiManager.Open("UiNewDrawMain", DefaultType)
end

--伙伴入口
function XUiMainRightMid:OnBtnPartner()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Partner) then
        return
    end
    XLuaUiManager.Open("UiPartnerMain", DefaultType)
end

function XUiMainRightMid:CheckDrawTag()
    self:OnCheckDrawActivityTag(XDataCenter.DrawManager.CheckDrawActivityCount())
end

--副本入口进度更新
function XUiMainRightMid:RefreshFubenProgress()
    local progressOrder = 1
    local curChapterOrderId = 1
    local curStageOrderId
    local curStageOrderIdForShow = 1
    local curStageCount = 1
    local chapterNew
    local extraClear = false
    local extraLock = false
    -- 普通
    local curDifficult = XDataCenter.FubenManager.DifficultNormal
    local chapterList = XDataCenter.FubenMainLineManager.GetChapterList(XDataCenter.FubenManager.DifficultNormal)
    for _, v in ipairs(chapterList) do
        local chapterInfo = XDataCenter.FubenMainLineManager.GetChapterInfo(v)
        if chapterInfo then --不知道什么情况偶现的没有副本数据，暂时加个保护
            if chapterInfo.Unlock then
                if v == XDataCenter.FubenMainLineManager.TRPGChapterId then
                    curChapterOrderId = v
                else
                    local activeStageId = chapterInfo.ActiveStage
                    if not activeStageId then break end
                    local stageInfo = XDataCenter.FubenManager.GetStageInfo(activeStageId)
                    local stageCfg = XDataCenter.FubenManager.GetStageCfg(activeStageId)
                    local chapter = XDataCenter.FubenMainLineManager.GetChapterCfg(v)
                    curStageOrderId = stageInfo.OrderId
                    curStageOrderIdForShow = stageCfg.OrderId
                    curChapterOrderId = chapter.OrderId
                    curStageCount = #XDataCenter.FubenMainLineManager.GetStageList(v)
                    progressOrder = chapterInfo.PassStageNum
                end
            --[[                if curStageOrderId == curStageCount and stageInfo.Passed then
                    --当前章节打完，下一章节未解锁时进度更为100%
                    progressOrder = curStageOrderId
                else
                    progressOrder = curStageOrderId - 1
                end]]
            end
            if not chapterInfo.Passed then
                break
            end
        end
    end
    local mainLineClear = self:IsMainLineClear(curChapterOrderId, progressOrder, curStageCount, #chapterList)
    if mainLineClear then
        local clearData = XDataCenter.ExtraChapterManager.GetChapterClearData()
        if clearData and clearData.ChapterId then
            extraClear = clearData.IsClear and clearData.AllChapterClear
            chapterNew = not clearData.IsClear
            progressOrder = clearData.PassStageNum
            self.TxtCurChapter.text = clearData.StageTitle .. "-" .. clearData.LastStageOrder
            self.TxtCurDifficult.text = CSXTextManagerGetText("DifficultMode") .. CSXTextManagerGetText("Difficult" .. curDifficult)
            curStageCount = #XDataCenter.ExtraChapterManager.GetStageList(clearData.ChapterId)
        else
            extraLock = true
        end
    end
    -- 主线与外章普通全部完成时改为显示据点战
    if XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.FubenNightmare) and extraClear then
        local chapterId = XDataCenter.BfrtManager.GetActiveChapterId()
        if not chapterId then return end
        local chapterCfg = XDataCenter.BfrtManager.GetChapterCfg(chapterId)
        progressOrder = XDataCenter.BfrtManager.GetChapterPassCount(chapterId)
        curStageCount = XDataCenter.BfrtManager.GetGroupCount(chapterId)
        chapterNew = XDataCenter.BfrtManager.CheckChapterNew(chapterId)
        self.TxtCurChapter.text = chapterCfg.ChapterEn
        local chapterPassedStr = progressOrder == curStageCount and CSXTextManagerGetText("BfrtStatePassed") or CSXTextManagerGetText("BfrtStateNotPassed")
        self.TxtCurDifficult.text = chapterPassedStr
    elseif not mainLineClear or (mainLineClear and extraLock) then
        chapterNew = XDataCenter.FubenMainLineManager.CheckNewChapter()
        local difficultTxt = CSXTextManagerGetText("Difficult" .. curDifficult)
        self.TxtCurDifficult.text = CSXTextManagerGetText("DifficultMode") .. difficultTxt
        if curChapterOrderId == XDataCenter.FubenMainLineManager.TRPGChapterId then
            self.TxtCurChapter.text = XFubenMainLineConfigs.GetChapterMainChapterEn(curChapterOrderId)
        else
            self.TxtCurChapter.text = curChapterOrderId .. "-" .. curStageOrderIdForShow
        end
    end

    local progress
    if curChapterOrderId == XDataCenter.FubenMainLineManager.TRPGChapterId then
        progress = XDataCenter.TRPGManager.GetProgress()
        progress = progress / 100
    else
        progress = progressOrder / curStageCount
    end
    self.ImgCurProgress.fillAmount = progress
    self.TxtCurProgress.text = CSXTextManagerGetText("MainFubenProgress", math.ceil(progress * 100))
    self.PanelBtnFightEffect.gameObject:SetActive(chapterNew)
end

function XUiMainRightMid:IsMainLineClear(curChapterOrderId, progressOrder, curStageCount, chapterListTotal)
    if curChapterOrderId == XDataCenter.FubenMainLineManager.TRPGChapterId then
        return XDataCenter.TRPGManager.IsTRPGClear()
    else
        return curChapterOrderId == chapterListTotal and progressOrder == curStageCount
    end
end

--更新任务按钮描述
function XUiMainRightMid:UpdateStoryTaskBtn()
    self.ShowTaskId = XDataCenter.TaskManager.GetStoryTaskShowId()
    local white = "#ffffff"
    local blue = "#34AFF8"
    if self.ShowTaskId > 0 then
        local taskTemplates = XDataCenter.TaskManager.GetTaskTemplate(self.ShowTaskId)
        self.BtnSkipTask:SetDisable(false, true)
        local taskData = XDataCenter.TaskManager.GetTaskDataById(self.ShowTaskId)
        local hasRed = taskData and taskData.State == XDataCenter.TaskManager.TaskState.Achieved
        self.BtnSkipTask:ShowReddot(hasRed)
        local color = hasRed and blue or white
        self.BtnSkipTask:SetName(string.format("<color=%s>%s</color>", color, taskTemplates.Desc))
    else
        self.BtnSkipTask:SetDisable(true, true)
        self.BtnSkipTask:SetName(string.format("<color=%s>%s</color>", white, CSXTextManagerGetText("TaskStoryNoTask")))
    end
end

--更新任务标签
function XUiMainRightMid:OnInitTaskFinished()
    self:UpdateStoryTaskBtn()
end

-------------活动简介 Begin-------------------
function XUiMainRightMid:UpdateBtnActivityBrief()
    local isOpen = XDataCenter.ActivityBriefManager.CheckActivityBriefOpen()
    isOpen = isOpen and not XUiManager.IsHideFunc
    self.BtnActivityBrief.gameObject:SetActiveEx(isOpen)
end

function XUiMainRightMid:OnBtnActivityBrief()
    XLuaUiManager.Open("UiActivityBriefBase")
end
-------------活动简介 End-------------------
-------------活动入口 Begin-------------------
function XUiMainRightMid:InitBtnActivityEntry()
    self:SetBtnActivityEntryHide()
    self:InitBtnActivityEntryRedPointEventIds()
    if XUiManager.IsHideFunc then return end

    local configs = XDataCenter.ActivityBriefManager.GetNowActivityEntryConfig()
    for index, config in ipairs(configs) do
        local btn = self["BtnActivityEntry" .. index]
        if btn then
            btn:SetSprite(config.Bg)
            btn.CallBack = function() self:OnClickBtnActivityEntry(config.Id, index) end
            btn.gameObject:SetActiveEx(true)
            local redPointConditions = XActivityBriefConfigs.GetRedPointConditionsBySkipId(config.SkipId)
            if redPointConditions then
                local redPointEventId = XRedPointManager.AddRedPointEvent(btn, self["OnCheckActivityEntryRedPoint" .. index], self, redPointConditions)
                tableInsert(self.BtnActivityEntryRedPointEventIds, redPointEventId)
            else
                btn:ShowReddot(false)
            end
        end
    end
end

function XUiMainRightMid:InitBtnActivityEntryRedPointEventIds()
    for _, redPointEventId in ipairs(self.BtnActivityEntryRedPointEventIds or {}) do
        XRedPointManager.RemoveRedPointEvent(redPointEventId)
    end
    self.BtnActivityEntryRedPointEventIds = {}
end

function XUiMainRightMid:UpdateBtnActivityEntry()
    local _, isNewActivity = XDataCenter.ActivityBriefManager.GetNowActivityEntryConfig()
    if isNewActivity then
        self:InitBtnActivityEntry()
    end
end

function XUiMainRightMid:SetBtnActivityEntryHide()
    for index = 1, BtnActivityEntryMaxCount do
        self["BtnActivityEntry" .. index].gameObject:SetActiveEx(false)
    end
end

function XUiMainRightMid:OnClickBtnActivityEntry(id, index)
    local dict = {}
    dict["ui_first_button"] = XGlobalVar.BtnBuriedSpotTypeLevelOne["BtnUiMainBtnActivityEntry" .. index]
    dict["role_level"] = XPlayer.GetLevel()
    CS.XRecord.Record(dict, "200004", "UiOpen")
    local skipId = XActivityBriefConfigs.GetActivityEntrySkipId(id)
    XFunctionManager.SkipInterface(skipId)
end

function XUiMainRightMid:CheckBtnActivityEntryRedPoint()
    for _, redPointEventId in ipairs(self.BtnActivityEntryRedPointEventIds) do
        XRedPointManager.Check(redPointEventId)
    end
end

function XUiMainRightMid:OnCheckActivityEntryRedPoint1(count)
    self.BtnActivityEntry1:ShowReddot(count >= 0)
end

function XUiMainRightMid:OnCheckActivityEntryRedPoint2(count)
    self.BtnActivityEntry2:ShowReddot(count >= 0)
end

function XUiMainRightMid:OnCheckActivityEntryRedPoint3(count)
    self.BtnActivityEntry3:ShowReddot(count >= 0)
end

function XUiMainRightMid:CheckStartActivityEntryTimer()
    self:StopActivityEntryTimer()
    local serverTimestamp
    local endTimeStamp = XDataCenter.ActivityBriefManager.GetSpecialActivityMaxEndTime()
    self.ActivityEntryTimer = XScheduleManager.ScheduleForever(function()
        serverTimestamp = XTime.GetServerNowTimestamp()
        self:UpdateBtnActivityEntry()
        self:CheckBtnActivityEntryRedPoint()
        if endTimeStamp <= serverTimestamp then
            self:StopActivityEntryTimer()
        end
    end, XScheduleManager.SECOND)
end

function XUiMainRightMid:StopActivityEntryTimer()
    if self.ActivityEntryTimer then
        XScheduleManager.UnSchedule(self.ActivityEntryTimer)
        self.ActivityEntryTimer = nil
    end
end
-------------活动入口 End-------------------
-------------回归活动入口 Begin-------------
function XUiMainRightMid:OnRegressionOpenStatusUpdate()
    local isOpen = XDataCenter.RegressionManager.IsHaveOneRegressionActivityOpen()
    self.BtnRegression.gameObject:SetActiveEx(isOpen)
    if not isOpen and self.RegressionTimeSchedule then
        XScheduleManager.UnSchedule(self.RegressionTimeSchedule)
        self.RegressionTimeSchedule = nil
        self.TxtRegressionLeftTime.gameObject:SetActiveEx(false)
    end
end

function XUiMainRightMid:OnBtnRegression()
    XLuaUiManager.Open("UiRegression")
end

-- 公会
function XUiMainRightMid:OnBtnGuildClick()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Guild) then
        return
    end

    XDataCenter.GuildDormManager.EnterGuildDorm()
end

function XUiMainRightMid:OnCheckGuildRedPoint(count)
    self.ImgBuldingRedDot.gameObject:SetActiveEx(count >= 0)
end
-------------回归活动入口 End-------------
---
--- 更新特殊商店入口状态
function XUiMainRightMid:BtnSpecialShopUpdate()
    if self.BtnSpecialShop then
        local isShow = XDataCenter.SpecialShopManager:IsShowEntrance()
        self.BtnSpecialShop.gameObject:SetActiveEx(isShow)
    end
end

--伙伴红点
function XUiMainRightMid:OnCheckPartnerRedPoint(count)
    self.BtnPartner:ShowReddot(count >= 0)
end

--任务红点
function XUiMainRightMid:OnCheckTaskNews(count)
    self.BtnTask:ShowReddot(count >= 0)
end

--新手目标红点
function XUiMainRightMid:OnCheckTargetNews(count)
    self.BtnTarget:ShowReddot(count >= 0)
end

-- 特殊商店红点
function XUiMainRightMid:OnCheckSpecialShopRedPoint(count)
    self.BtnSpecialShop:ShowReddot(count >= 0)
end

--宿舍红点
function XUiMainRightMid:OnCheckBuildingNews(count)
    self.BtnBuilding:ShowReddot(count >= 0)
end

--活动简介红点
function XUiMainRightMid:OnCheckActivityBriefRedPoint(count)
    self.BtnActivityBrief:ShowReddot(count >= 0)
end

--研发红点
function XUiMainRightMid:OnCheckARewardNews(count)
    self.BtnReward:ShowReddot(count >= 0)
end

--研发活动标签
function XUiMainRightMid:OnCheckDrawActivityTag(IsShow)
    if XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.DrawCard) then
        self.BtnReward:ShowTag(IsShow)
    else
        self.BtnReward:ShowTag(false)
    end
end


return XUiMainRightMid