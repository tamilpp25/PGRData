local XUiBiancaTheatrePanelReward = require("XUi/XUiBiancaTheatre/Common/XUiBiancaTheatrePanelReward")

--肉鸽玩法二期主界面
local XUiBiancaTheatreMain = XLuaUiManager.Register(XLuaUi, "UiBiancaTheatreMain")

function XUiBiancaTheatreMain:OnAwake()
    XDataCenter.BiancaTheatreManager.SetIsAutoOpen(true)
    XDataCenter.BiancaTheatreManager.SetIsAutoOpenSettleWin(true)
    self.IsShowPanel = true
    XUiHelper.NewPanelActivityAsset(XDataCenter.BiancaTheatreManager.GetAssetItemIds(), self.PanelSpecialTool, nil, handler(self, self.OnBtnClick))
    self:InitButtonCallBack()
    self.TaskManager = XDataCenter.BiancaTheatreManager.GetTaskManager()

    --奖励面板
    self.PanelReward = XUiBiancaTheatrePanelReward.New(self.BtnReward)
    self:InitReward()
end

function XUiBiancaTheatreMain:OnStart()
    self:PlayStartAnim()
end

function XUiBiancaTheatreMain:OnEnable()
    self:Refresh()
    self:CheckRedPoint()
    self:CheckShowPanel()
    self:UpdateBg()
    -- 剧情结局结算完才显示提示弹窗
    if not XDataCenter.BiancaTheatreManager.CheckOpenSettleWin() and not XDataCenter.BiancaTheatreManager.CheckIsInMovie() then
        self:CheckAllUnlockTip()
    end

    self:CheckPlayAnim()
    XDataCenter.BiancaTheatreManager.ResetAudioFilter()
    XEventManager.AddEventListener(XEventId.EVENT_BIANCA_THEATRE_TOTAL_EXP_CHANGE, self.PanelReward.Refresh, self.PanelReward)
end

function XUiBiancaTheatreMain:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_BIANCA_THEATRE_TOTAL_EXP_CHANGE, self.PanelReward.Refresh, self.PanelReward)
end

function XUiBiancaTheatreMain:OnReleaseInst()
    return self.IsShowPanel
end

function XUiBiancaTheatreMain:OnResume(value)
    self.IsShowPanel = value
end

--主要奖励
function XUiBiancaTheatreMain:InitReward()
    local rewardId = XBiancaTheatreConfigs.GetClientConfig("MainViewShowRewardId")
    rewardId = rewardId and tonumber(rewardId)
    if not XTool.IsNumberValid(rewardId) then
        return
    end
    if XTool.UObjIsNil(self.GridReward) or XTool.UObjIsNil(self.PanelList) then
        return
    end

    local rewardItems = XRewardManager.GetRewardList(rewardId)
    local rewardGoodsList = XRewardManager.MergeAndSortRewardGoodsList(rewardItems)
    for i, reward in ipairs(rewardGoodsList) do
        local grid = i == 1 and self.GridReward or XUiHelper.Instantiate(self.GridReward, self.PanelList)
        local gridCommon = XUiGridCommon.New(self, grid)
        gridCommon:Refresh(reward)
        if gridCommon.BtnClick then
            XUiHelper.RegisterClickEvent(gridCommon, gridCommon.BtnClick, function()
                XLuaUiManager.Open("UiBiancaTheatreTips", reward)
            end)
        end
    end
end

--------------------------------------------------------------------------------


-- 红点相关
--------------------------------------------------------------------------------

--检查红点
function XUiBiancaTheatreMain:CheckRedPoint()
    self:CheckTaskRedPoint()
    self:CheckStrengthenPoint()
    self.BtnAtlas:ShowReddot(false)
    self.BtnCollection:ShowReddot(XDataCenter.BiancaTheatreManager.CheckFieldGuideRedPoint())
    self.BtnAchievement:ShowReddot(XDataCenter.BiancaTheatreManager.CheckAchievementTaskCanAchieved())    --成就红点
end

function XUiBiancaTheatreMain:CheckStrengthenPoint()
    self.BtnStrengthen:ShowReddot(self:CheckStrengthenUnlock() and not XDataCenter.BiancaTheatreManager.GetStrengthenUnlockCache())
end

--任务红点
function XUiBiancaTheatreMain:CheckTaskRedPoint()
    local isShowRedPoint = XDataCenter.BiancaTheatreManager.CheckTaskCanReward()
    self.BtnTask:ShowReddot(isShowRedPoint)
end

--------------------------------------------------------------------------------


-- Ui刷新相关
--------------------------------------------------------------------------------

function XUiBiancaTheatreMain:Refresh()
    local adventureManager = XDataCenter.BiancaTheatreManager.GetCurrentAdventureManager()
    local chapter = adventureManager and adventureManager:GetCurrentChapter()
    local chapterId = chapter and chapter:GetCurrentChapterId()

    --开始冒险按钮的文本
    local curStateIsBegin = not XDataCenter.BiancaTheatreManager.CheckHasAdventure()
    local txtPath = curStateIsBegin and XBiancaTheatreConfigs.TheatreTxtStartPath or XBiancaTheatreConfigs.TheatreTxtContinuePath
    self.BtnMain:SetRawImage(txtPath)

    --是否显示终止冒险
    self.BtnTermination.gameObject:SetActiveEx(not curStateIsBegin)

    --背景图片
    if self.BiancaTheatreBg then
        local bgA = XBiancaTheatreConfigs.GetChapterBgA(chapterId)
        self.BiancaTheatreBg:SetRawImage(bgA)
    end
    if self.ImgBt then
        local bgB = XBiancaTheatreConfigs.GetChapterBgB(chapterId)
        self.ImgBt:SetRawImage(bgB)
    end
    
    --外循环强化是否解锁
    local isUnlock = self:CheckStrengthenUnlock()
    self.BtnStrengthen:SetDisable(not isUnlock)

    self:UpdateTask()
    self:UpdateAchievement()
    self.PanelReward:Refresh()

    self:CheckRedPoint()
end

function XUiBiancaTheatreMain:UpdateTask()
    local taskId = self.TaskManager:GetMainShowTaskId()
    local isComplete = not XTool.IsNumberValid(taskId) and true or XDataCenter.TaskManager.IsTaskFinished(taskId)
    local config = not isComplete and XDataCenter.TaskManager.GetTaskTemplate(taskId)
    local desc = config and config.Desc or XBiancaTheatreConfigs.GetClientConfig("MissionComplete")
    --任务描述
    self.BtnTask:SetNameByGroup(0, desc)
    self.BtnTask.gameObject:SetActiveEx(true)
end

function XUiBiancaTheatreMain:UpdateBg()
    local chapter = XDataCenter.BiancaTheatreManager.GetCurrentAdventureManager():GetCurrentChapter()
    local chapterId = chapter and chapter:GetCurrentChapterId()
    self.BiancaTheatreBg:SetRawImage(XBiancaTheatreConfigs.GetChapterBgA(chapterId))
    self.ImgBt:SetRawImage(XBiancaTheatreConfigs.GetChapterBgB(chapterId))
end

function XUiBiancaTheatreMain:UpdateAchievement()
    self.BtnAchievement:SetDisable(not XDataCenter.BiancaTheatreManager.CheckAchievementIsOpen())
    local allTaskCount = self.TaskManager:GetAllAchievementTabTaskCount()
    local allFinishCount = self.TaskManager:GetAllAchievementTabFinishCount()
    self.BtnAchievement:SetNameByGroup(0, string.format(XBiancaTheatreConfigs.GetClientConfig("MainAchievementAllPrecoss"), allFinishCount, allTaskCount))
end

function XUiBiancaTheatreMain:CheckShowPanel()
    local isShowPanel = self.IsShowPanel or false
    self.PanelSpecialTool.gameObject:SetActiveEx(isShowPanel)
    self.BtnMain.gameObject:SetActiveEx(isShowPanel)
end

function XUiBiancaTheatreMain:OnNotify(evt, ...)
    if evt == XEventId.EVENT_TASK_SYNC then
        self:UpdateTask()
        self:UpdateAchievement()
    end
end

function XUiBiancaTheatreMain:OnGetEvents()
    return { XEventId.EVENT_TASK_SYNC }
end

function XUiBiancaTheatreMain:PlayStartAnim()
    self:PlayAnimationWithMask("AnimEnable1", function ()
        local animEnable1 = self:FindComponent("AnimEnable1", "PlayableDirector")
        self.AnimEnable1CurrentTime = animEnable1.time
        self:PlayAnimation("UiLoop", nil, nil, CS.UnityEngine.Playables.DirectorWrapMode.Loop)
    end)
end

-- 防止因为弹出结算界面被中断的动画不再播放
function XUiBiancaTheatreMain:CheckPlayAnim()
    if not XTool.IsNumberValid(self.AnimEnable1CurrentTime) then
        return
    end
    local animEnable1 = self:FindComponent("AnimEnable1", "PlayableDirector")
    local isPlaying = animEnable1.state == CS.UnityEngine.Playables.PlayState.Playing
    local isFinish = self.AnimEnable1CurrentTime <= animEnable1.duration
    if animEnable1 and not isPlaying and isFinish then
        self:PlayStartAnim()
    else
        self:PlayAnimation("UiLoop", nil, nil, CS.UnityEngine.Playables.DirectorWrapMode.Loop)
    end
end

--------------------------------------------------------------------------------


-- 按钮相关
--------------------------------------------------------------------------------

function XUiBiancaTheatreMain:InitButtonCallBack()
    self:BindHelpBtn(self.BtnHelp, XDataCenter.BiancaTheatreManager.GetHelpKey())
    self:RegisterClickEvent(self.BtnBack, function() 
        XDataCenter.BiancaTheatreManager.ResetAudioFilter()
        self:Close()
    end)
    self:RegisterClickEvent(self.BtnMainUi, function() XDataCenter.BiancaTheatreManager.RunMain() end)
    self:RegisterClickEvent(self.BtnMain, self.OnBtnMainClick)                --开始冒险
    self:RegisterClickEvent(self.BtnTermination, self.OnBtnTerminationClick)    --结束冒险
    self:RegisterClickEvent(self.BtnAtlas, self.OnBtnAtlasClick)                --羁绊图鉴
    self:RegisterClickEvent(self.BtnCollection, self.OnBtnCollectionClick)      --道具图鉴
    self:RegisterClickEvent(self.BtnStrengthen, self.OnBtnStrengthenClick)      --外循环强化
    self:RegisterClickEvent(self.BtnTask, self.OnBtnTaskClick)                  --任务
    self:RegisterClickEvent(self.BtnAchievement, self.OnBtnAchievementClick)    --成就
end

--货币点击方法
function XUiBiancaTheatreMain:OnBtnClick(index)
    XLuaUiManager.Open("UiBiancaTheatreTips", XBiancaTheatreConfigs.TheatreOutCoin)
end

function XUiBiancaTheatreMain:OnBtnTaskClick()
    XLuaUiManager.Open("UiBiancaTheatreTask")
end

function XUiBiancaTheatreMain:OnBtnAtlasClick()
    XLuaUiManager.Open("UiBiancaTheatreComboTips", nil, true)
end

function XUiBiancaTheatreMain:OnBtnCollectionClick()
    XLuaUiManager.Open("UiBiancaTheatreProp")
end

-- V2.1 打开成就界面
function XUiBiancaTheatreMain:OnBtnAchievementClick()
    if XDataCenter.BiancaTheatreManager.CheckAchievementIsOpen(true) then
        XLuaUiManager.Open("UiBiancaTheatreAchievement")
    end
end

function XUiBiancaTheatreMain:OnBtnStrengthenClick()
    local isUnlock = self:CheckStrengthenUnlock(true)
    if not isUnlock then
        return
    end
    XDataCenter.BiancaTheatreManager.SetStrengthenUnlockCache()
    self:CheckStrengthenPoint()
    XLuaUiManager.Open("UiBiancaTheatreSkill")
end

function XUiBiancaTheatreMain:CheckStrengthenUnlock(isTips)
    local conditionId = XBiancaTheatreConfigs.GetTheatreConfig("StrongerConditionId").Value
    conditionId = tonumber(conditionId)
    if XTool.IsNumberValid(conditionId) then
        local unlock, desc = XConditionManager.CheckCondition(conditionId)
        if not unlock and isTips then
            XUiManager.TipMsg(desc)
        end
        return unlock, desc
    end
    return true
end

function XUiBiancaTheatreMain:OnBtnMainClick()
    local difficultyId = XDataCenter.BiancaTheatreManager.GetDifficultyId()
    local curChapter = XDataCenter.BiancaTheatreManager.GetCurrentAdventureManager():GetCurrentChapter()
    local curStep = curChapter and curChapter:GetCurStep()
    if curStep then
        -- 继续冒险
        XDataCenter.BiancaTheatreManager.CheckOpenView()
    elseif XTool.IsNumberValid(difficultyId) then
        -- 已选难度，进入分队选择
        XLuaUiManager.Open("UiBiancaTheatreChoice", {UiType = XBiancaTheatreConfigs.UiChoiceType.TeamSelect})
    else
        -- 选择难度
        XLuaUiManager.Open("UiBiancaTheatreChoice", {UiType = XBiancaTheatreConfigs.UiChoiceType.Difficulty})
    end
end

--结束冒险
function XUiBiancaTheatreMain:OnBtnTerminationClick()
    local adventureManager = XDataCenter.BiancaTheatreManager.GetCurrentAdventureManager()
    local chapter = adventureManager and adventureManager:GetCurrentChapter()
    if not chapter then
        return
    end

    XLuaUiManager.Open("UiBiancaTheatreEndTips", XUiHelper.GetText("TheatreChapterSettleSureTitle")
        , XUiHelper.GetText("TheatreChapterSettleSureTip", chapter:GetTitle())
        , XUiManager.DialogType.Normal, nil
        , function()
            adventureManager:RequestSettleAdventure(function()
                self:Refresh()
        end)
    end)
end

--------------------------------------------------------------------------------


-- 自动弹窗相关
--------------------------------------------------------------------------------

function XUiBiancaTheatreMain:CheckAllUnlockTip()
    local beforeLv = XDataCenter.BiancaTheatreManager.GetCurLevelCache()
    local afterLv = XDataCenter.BiancaTheatreManager.GetCurRewardLevel()
    if XDataCenter.BiancaTheatreManager.CheckCurLevelIsUpdate() then
        -- 升级提示弹窗结束再道具弹窗提示
        XDataCenter.BiancaTheatreManager.AddTipOpenData("UiBiancaTheatreLvTips", nil, beforeLv, afterLv)
    end
    if XDataCenter.BiancaTheatreManager.CheckUnlockItemUpdate() then
        XDataCenter.BiancaTheatreManager.AddTipOpenData("UiBiancaTheatreItemUnlockTips", nil, XDataCenter.BiancaTheatreManager.GetNewUnlockItemDic())
    end
    if self:CheckStrengthenUnlock() and not XDataCenter.BiancaTheatreManager.GetStrengthenUnlockTipsCache() then
        XDataCenter.BiancaTheatreManager.AddTipOpenData("UiBiancaTheatreUnlockTips")
    end
    if XDataCenter.BiancaTheatreManager.CheckVisionSystemIsOpen() and not XDataCenter.BiancaTheatreManager.GetVisionOpenTipCache() then
        XDataCenter.BiancaTheatreManager.AddTipOpenData("UiBiancaTheatrePsionicVision", nil, true)
    end

    XDataCenter.BiancaTheatreManager.CheckTipOpenList(function ()
        XDataCenter.GuideManager.CheckGuideOpen()	-- 触发成就引导
    end)
end

--------------------------------------------------------------------------------