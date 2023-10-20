---@class XUiFunbenWeiLaTutorial:XLuaUi
local XUiFunbenWeiLaTutorial = XLuaUiManager.Register(XLuaUi, "UiFunbenWeiLaTutorial")
local XUiPanelFubenWeiLaStage = require("XUi/XUiNewChar/WeiLa/XUiPanelFubenWeiLaStage")
local XUiPanelNewCharTask=require('XUi/XUiNewChar/XUiPanelNewCharTask')

function XUiFunbenWeiLaTutorial:OnAwake()
    self:InitAutoScript()
    self.RedPointBtnAchievementId=self:AddRedPointEvent(self.BtnAchievement,self.RefreshBtnTaskRedDot,self,{
        XRedPointConditions.Types.CONDITION_NEWCHARACTIVITYTASK,
    })
    self.RedPointBtnTeachingId = self:AddRedPointEvent(self.BtnTeaching, self.RefreshBtnTeachingRedDot, self, {
        XRedPointConditions.Types.CONDITION_KOROMCHARACTIVITYTEACHINGRED,
    })
    self.RedPointBtnChallengeId = self:AddRedPointEvent(self.BtnChallenge, self.RefreshBtnChallengeRedDot, self, {
        XRedPointConditions.Types.CONDITION_KOROMCHARACTIVITYCHALLENGERED,
    })
    --self.PanelRoot = self.PanelStageRoot.parent:Find("PanelRoot")
end

function XUiFunbenWeiLaTutorial:OnStart(actId)
    self:PlayAnimationWithMask("AnimEnable1", function()
        self:PlayAnimation("Loop",nil,nil,CS.UnityEngine.Playables.DirectorWrapMode.Loop)
    end)

    self.Id = actId
    self.CurPanelStage = XDataCenter.FubenNewCharActivityManager.GetKoroLastOpenPanel() or XFubenNewCharConfig.KoroPanelType.Normal
    self.ActivityCfg = XFubenNewCharConfig.GetDataById(self.Id)
    self.ActivityEndTime = XFunctionManager.GetEndTimeByTimeId(self.ActivityCfg.TimeId)
    self:InitPanel()
    local isPlayVideo = self.ActivityCfg.MovieId and self.ActivityCfg.MovieId ~= 0
    self.VideoPlayer.gameObject:SetActiveEx(isPlayVideo)
    if isPlayVideo then
        local config = XVideoConfig.GetMovieById(self.ActivityCfg.MovieId)
        self.VideoPlayer:SetVideoFromRelateUrl(config.VideoUrl)
        self.VideoPlayer:Play()
    end
end

function XUiFunbenWeiLaTutorial:OnEnable()
    self:CheckRedPoint()
    self:SwitchPanelStage(self.CurPanelStage)
    self:StartActivityTimer()
    self:RefreshMainTask()
end

function XUiFunbenWeiLaTutorial:OnDisable()
    self:CloseActivityTimer()
end

function XUiFunbenWeiLaTutorial:InitPanel()
    --self.TxtActivityName.text = self.ActivityCfg.Name
    self.FubenGo = self.PanelStageRoot:LoadPrefab(self.ActivityCfg.FubenPrefab)
    self.FubenGo.gameObject:SetActiveEx(false)
    self.PanelStageKoro = XUiPanelFubenWeiLaStage.New( self.FubenGo, self,self.ActivityCfg, XFubenNewCharConfig.KoroPanelType.Teaching)
    self.FubenChallengeGo = self.PanelChallengeStageRoot:LoadPrefab(self.ActivityCfg.FubenChallengePrefab)
    self.FubenChallengeGo.gameObject:SetActiveEx(false)
    self.PanelStageKoroChallenge = XUiPanelFubenWeiLaStage.New(self.FubenChallengeGo, self, self.ActivityCfg, XFubenNewCharConfig.KoroPanelType.Challenge)
    self.TaskPanel=XUiPanelNewCharTask.New(self.PanelTreasure,self,self.ActivityCfg)
    self.TaskPanel:Close()
end

--按钮红点
function XUiFunbenWeiLaTutorial:CheckRedPoint()
    XRedPointManager.Check(self.RedPointBtnAchievementId)
    XRedPointManager.Check(self.RedPointBtnTeachingId)
    XRedPointManager.Check(self.RedPointBtnChallengeId)
    --self.BtnChapter:ShowReddot(false)
end

--活动时间的定时器开启与关闭
function XUiFunbenWeiLaTutorial:StartActivityTimer()
    local now = XTime.GetServerNowTimestamp()
    self.TxtDay.text = XUiHelper.GetTime(self.ActivityEndTime - now, XUiHelper.TimeFormatType.ACTIVITY)
    self:CloseActivityTimer()

    self.TimerId = XScheduleManager.ScheduleForever(function()
        self:RefreshActivityTime()
    end, XScheduleManager.SECOND, 0)
end

function XUiFunbenWeiLaTutorial:RefreshActivityTime()
    local now = XTime.GetServerNowTimestamp()
    if now > self.ActivityEndTime then
        XUiManager.TipText("KoroCharacterActivityEnd")
        self:CloseActivityTimer()
        XScheduleManager.ScheduleOnce(function()
            XLuaUiManager.RunMain()
        end,500)
        return
    end
    self.TxtDay.text = XUiHelper.GetTime(self.ActivityEndTime - now, XUiHelper.TimeFormatType.ACTIVITY)
end

function XUiFunbenWeiLaTutorial:CloseActivityTimer()
    if self.TimerId then
        XScheduleManager.UnSchedule(self.TimerId)
        self.TimerId = nil
    end
end

--切换到挑战界面或者教学关界面
function XUiFunbenWeiLaTutorial:SwitchPanelStage(panelStage)
    XDataCenter.FubenNewCharActivityManager.SetKoroLastOpenPanel(panelStage)
    if panelStage ~= XFubenNewCharConfig.KoroPanelType.Normal then
        self.PanelMain.gameObject:SetActiveEx(false)
        self.PanelSpine.gameObject:SetActiveEx(false)
        self.VideoPlayer.gameObject:SetActiveEx(false)
        --self.PanelRoot.gameObject:SetActiveEx(false)
        self.PanelEffect.gameObject:SetActiveEx(false)
        if panelStage == XFubenNewCharConfig.KoroPanelType.Teaching then
            self.PanelStageKoro:OnShow(panelStage)
        elseif panelStage == XFubenNewCharConfig.KoroPanelType.Challenge then
            self.PanelStageKoroChallenge:OnShow(panelStage)
        end
        self.CurPanelStage = panelStage
    else
        if self.PanelStageKoro:CheckCanClose() and self.PanelStageKoroChallenge:CheckCanClose() then
            self.PanelMain.gameObject:SetActiveEx(true)
            self.PanelSpine.gameObject:SetActiveEx(true)
            local isPlayVideo = self.ActivityCfg.MovieId and self.ActivityCfg.MovieId ~= 0
            self.VideoPlayer.gameObject:SetActiveEx(isPlayVideo)
            --self.PanelRoot.gameObject:SetActiveEx(true)
            self.PanelEffect.gameObject:SetActiveEx(true)
            self.PanelStageKoro:OnHide()
            self.PanelStageKoroChallenge:OnHide()
            self.CurPanelStage = panelStage
            self:CheckRedPoint()
            self:RefreshMainTask()
            --XLuaUiManager.SetMask(true)
            --self:PlayAnimation("AnimSwitch", function()
            --    XLuaUiManager.SetMask(false)
            --end)
        end
    end
end

--按钮绑定事件
function XUiFunbenWeiLaTutorial:InitAutoScript()
    self.BtnBack.CallBack = function() self:OnBtnBackClick() end
    self.BtnMainUi.CallBack = function() self:OnBtnMainUiClick() end
    --self.BtnChapter.CallBack = function() self:OnBtnChapterClick() end
    self.BtnTeaching.CallBack = function() self:OnBtnTeachingClick() end
    self.BtnChallenge.CallBack = function() self:OnBtnChallengeClick() end
    self.BtnDetails.CallBack = function() self:OnBtnDetailsClick() end
    self.BtnCultivate.CallBack = function() self:OnBtnCultivateClick() end
    self.BtnObtain.CallBack = function() self:OnBtnObtainClick() end
    self.BtnSkin.CallBack = function() self:OnBtnSkinClick() end
    self.BtnResearch.CallBack = function() self:OnBtnResearchClick() end
    if self.BtnAchievement then
        self.BtnAchievement.CallBack=function() self.TaskPanel:Open() end
    end
    if self.BtnTreasure then
        XUiHelper.RegisterClickEvent(self,self.BtnTreasure,function() self.TaskPanel:Open() end)
    end
end

function XUiFunbenWeiLaTutorial:OnBtnBackClick()
    if self.CurPanelStage == XFubenNewCharConfig.KoroPanelType.Normal then
        XDataCenter.FubenNewCharActivityManager.SetKoroLastOpenPanel(self.CurPanelStage)
        self:Close()
        return
    end
    self:SwitchPanelStage(XFubenNewCharConfig.KoroPanelType.Normal)
end

function XUiFunbenWeiLaTutorial:OnBtnMainUiClick()
    XDataCenter.FubenNewCharActivityManager.SetKoroLastOpenPanel(XFubenNewCharConfig.KoroPanelType.Normal)
    XLuaUiManager.RunMain()
end

function XUiFunbenWeiLaTutorial:OnBtnChapterClick()
    XFunctionManager.SkipInterface(self.ActivityCfg.SkipIdJZ)
end

function XUiFunbenWeiLaTutorial:OnBtnTeachingClick()
    self:SwitchPanelStage(XFubenNewCharConfig.KoroPanelType.Teaching)
end

function XUiFunbenWeiLaTutorial:OnBtnChallengeClick()
    if self.ActivityCfg.ChallengeCondition then
        local isOpen,desc = XConditionManager.CheckCondition(self.ActivityCfg.ChallengeCondition)
        if not isOpen then
            XUiManager.TipMsg(desc)
            return
        end
    end

    self:SwitchPanelStage(XFubenNewCharConfig.KoroPanelType.Challenge)
end

function XUiFunbenWeiLaTutorial:OnBtnDetailsClick()
    XLuaUiManager.Open("UiCharacterDetail", self.ActivityCfg.CharacterId)
end

function XUiFunbenWeiLaTutorial:OnBtnCultivateClick()
    XFunctionManager.SkipInterface(self.ActivityCfg.SkipIdChar)
end

function XUiFunbenWeiLaTutorial:OnBtnObtainClick()
    XFunctionManager.SkipInterface(self.ActivityCfg.SkipGet)
end

function XUiFunbenWeiLaTutorial:OnBtnSkinClick()
    XFunctionManager.SkipInterface(self.ActivityCfg.SkipIdSkin)
end

function XUiFunbenWeiLaTutorial:OnBtnResearchClick()
    XFunctionManager.SkipInterface(self.ActivityCfg.SkipIdDraw)
end

function XUiFunbenWeiLaTutorial:RefreshBtnChallengeRedDot(count)
    self.BtnChallenge:ShowReddot(count >= 0)
end

function XUiFunbenWeiLaTutorial:RefreshBtnTeachingRedDot(count)
    self.BtnTeaching:ShowReddot(count >= 0)
end

function XUiFunbenWeiLaTutorial:RefreshBtnTaskRedDot(count)
    self.BtnAchievement:ShowReddot(count>=0)
end

function XUiFunbenWeiLaTutorial:HideTopBtn()
    self.BtnMainUi.gameObject:SetActiveEx(false)
    self.BtnBack.gameObject:SetActiveEx(false)
end

function XUiFunbenWeiLaTutorial:ShowTopBtn()
    self.BtnMainUi.gameObject:SetActiveEx(true)
    self.BtnBack.gameObject:SetActiveEx(true)
end

--2.8 刷新主界面的任务相关内容
function XUiFunbenWeiLaTutorial:RefreshMainTask()
    local actCfg=XFubenNewCharConfig.GetActTemplates()[self.Id]
    local rewardId=0
    if XTool.IsNumberValid(actCfg.ShowRewardId) then --显示配置的数据
        rewardId=actCfg.ShowRewardId
    else --采用原逻辑按顺序显示
        XLog.Error('任务奖励入口显示未配置固定显示，执行按优先级筛选显示逻辑--2.8版本显示需求')
        local treasureId, isAllFinish = XDataCenter.FubenNewCharActivityManager.GetShowTaskId(self.Id)
        if not XTool.IsNumberValid(treasureId) then
            self.PanelTips.gameObject:SetActiveEx(false)
            return
        end
        local config = XFubenNewCharConfig.GetTreasureCfg(treasureId)
        rewardId = config.RewardId
    end
    self.PanelTips.gameObject:SetActiveEx(true)
    self.GridMainTaskReward = self.GridMainTaskReward or {}
    local rewards=XRewardManager.GetRewardListNotCount(rewardId)
    local rewardsNum = #rewards
    for i = 1, rewardsNum do
        local grid = self.GridMainTaskReward[i]
        if not grid then
            local go = i == 1 and self.Grid256New or XUiHelper.Instantiate(self.Grid256New, self.PanelItem)
            grid = XUiGridCommon.New(self, go)
            self.GridMainTaskReward[i] = grid
        end
        grid:Refresh(rewards[i])
        grid.GameObject:SetActiveEx(true)
    end
    for i = rewardsNum + 1, #self.GridMainTaskReward do
        self.GridMainTaskReward[i].GameObject:SetActiveEx(false)
    end
    
    self:InitStarts()
end

--初始化收集进度
function XUiFunbenWeiLaTutorial:InitStarts()
    local curStars
    local totalStars
    curStars, totalStars = XDataCenter.FubenNewCharActivityManager.GetProcess()

    self.ImgJindu.fillAmount = totalStars > 0 and curStars / totalStars or 0
    self.ImgJindu.gameObject:SetActiveEx(true)

    local received = true
    local cfg=XFubenNewCharConfig.GetActTemplates()[self.Id]
    for _, v in pairs(cfg.TreasureId) do
        if not XDataCenter.FubenNewCharActivityManager.IsTreasureGet(v) then
            received = false
            break
        end
    end
    self.ImgLingqu.gameObject:SetActiveEx(received)

end