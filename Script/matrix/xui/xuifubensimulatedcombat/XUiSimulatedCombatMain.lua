local XUiGridPointReward = require("XUi/XUiFubenSimulatedCombat/ChildItem/XUiGridPointReward")
local XUiSimulatedCombatChapter = require("XUi/XUiFubenSimulatedCombat/XUiSimulatedCombatChapter")
local Lerp = CS.UnityEngine.Mathf.Lerp

local XUiSimulatedCombatMain = XLuaUiManager.Register(XLuaUi, "UiSimulatedCombatMain")

local StageType = XFubenSimulatedCombatConfig.StageType
local ChildUiType = {
    Task = 1,
    Star = 2,
}
local ChildUiName = {
    [ChildUiType.Task] = "UiSimulatedCombatTaskReward",
    [ChildUiType.Star] = "UiSimulatedCombatStarReward",
}

function XUiSimulatedCombatMain:OnAwake()
    self.TabBtns = {}
    self.SwitchEffect = {}
end

function XUiSimulatedCombatMain:OnEnable()
    if not XLuaUiManager.IsUiLoad("UiSimulatedCombatResAllo") then
        XDataCenter.FubenSimulatedCombatManager.ResetChange()
    end

    if self.RedPointActive then
        XRedPointManager.Check(self.RedPointActive)
    end

    if self.RedPointStarReward then
        XRedPointManager.Check(self.RedPointStarReward)
    end

    if self.RedPointTask then
        XRedPointManager.Check(self.RedPointTask)
    end

    self:Refresh()
end

function XUiSimulatedCombatMain:OnStart(defaultView, childUiType)
    self.CurrentView = defaultView or StageType.Normal
    self.ActTemplate = XDataCenter.FubenSimulatedCombatManager.GetCurrentActTemplate()
    if not self.ActTemplate then 
        self:Close()
    end

    self:CreateActivityTimer(XDataCenter.FubenSimulatedCombatManager.GetEndTime())
    self.TxtChapterName.text = self.ActTemplate.Name
    
    self:InitUiView()
    self.AssetActivityPanel = XUiPanelActivityAsset.New(self.PanelSpecialTool, self, true)
    self.AssetActivityPanel:SetQueryFunc(XDataCenter.FubenSimulatedCombatManager.GetCurrencyByItem)
    self.PointRewardGridList = {}

    self:OnSwitchView(self.CurrentView, true)
    if childUiType then
        self:OpenOneChildUi(ChildUiName[childUiType], self)
    end
    self.RedPointActive = XRedPointManager.AddRedPointEvent(self.BtnSwitchHard, self.OnCheckChallenge, self, { XRedPointConditions.Types.CONDITION_SIMULATED_COMBAT_CHALLENGE }, nil, true)
    self.RedPointStarReward = XRedPointManager.AddRedPointEvent(self.BtnStarReward, self.OnCheckStarReward, self, { XRedPointConditions.Types.CONDITION_SIMULATED_COMBAT_STAR }, nil, true)
    self.RedPointTask = XRedPointManager.AddRedPointEvent(self.BtnTask, self.OnCheckTask, self, { XRedPointConditions.Types.CONDITION_SIMULATED_COMBAT_TASK }, nil, true)
end

function XUiSimulatedCombatMain:OnGetEvents()
    return { XEventId.EVENT_FUBEN_SIMUCOMBAT_UPDATE,
             XEventId.EVENT_FUBEN_SIMUCOMBAT_REWARD,
             XEventId.EVENT_ACTIVITY_ON_RESET}
end

function XUiSimulatedCombatMain:OnNotify(evt, ...)
    local args = { ... }
    if evt == XEventId.EVENT_FUBEN_SIMUCOMBAT_UPDATE then
        self:Refresh(args)
    elseif evt == XEventId.EVENT_FUBEN_SIMUCOMBAT_REWARD then
        self:SetupPointReward()
    elseif evt == XEventId.EVENT_ACTIVITY_ON_RESET then
        if args[1] ~= XDataCenter.FubenManager.StageType.SimulatedCombat then return end
        XDataCenter.FubenSimulatedCombatManager.OnActivityEnd()
    end
end

function XUiSimulatedCombatMain:OnCheckChallenge(count)
    self.BtnSwitchHard:ShowReddot(count >= 0)
    self.BtnSwitchNormal:ShowReddot(false)
end

function XUiSimulatedCombatMain:OnCheckStarReward(count)
    self.BtnStarReward:ShowReddot(count >= 0)
end

function XUiSimulatedCombatMain:OnCheckTask(count)
    self.BtnTask:ShowReddot(count >= 0)
end

function XUiSimulatedCombatMain:Refresh()
    self.BtnSwitchNormal.gameObject:SetActiveEx(self.CurrentView == StageType.Challenge)
    self.BtnSwitchHard.gameObject:SetActiveEx(self.CurrentView == StageType.Normal)
    self.PanelStage:SetUiData(self.CurrentView)
    self.AssetActivityPanel:Refresh(self.ActTemplate.ConsumeIds)
    self:SetupReward()
    self.TxtChllengeRewardTime.text = XDataCenter.FubenSimulatedCombatManager.GetDailyRewardRemainCount()

    local isOpen = XConditionManager.CheckCondition(self.ActTemplate.HardConditionId)
    self.BtnSwitchHard:SetButtonState(isOpen and XUiButtonState.Normal or XUiButtonState.Disable)
end

function XUiSimulatedCombatMain:OnDestroy()
    self:StopActivityTimer()
end

--设置奖励
function XUiSimulatedCombatMain:SetupReward()
    if self.ActTemplate.PointId ~= 0 then
        XDataCenter.ItemManager.AddCountUpdateListener(self.ActTemplate.PointId, function ()
            self:SetupPointReward()
        end, self.GameObject)
        self:SetupPointReward()
    end
    self:SetupStarReward()
end

function XUiSimulatedCombatMain:SetupPointReward()
    local pointCount = XDataCenter.ItemManager.GetCount(self.ActTemplate.PointId)
    local pointRewardCfg = XFubenSimulatedCombatConfig.GetPointReward()
    self.TxtPoint.text = pointCount
    local defaultIndex
    for index in ipairs(pointRewardCfg) do
        local tmpPointCfg = XFubenSimulatedCombatConfig.GetPointRewardById(index)
        local nextPointCfg = XFubenSimulatedCombatConfig.GetPointRewardById(index + 1) or nil
        local grid
        if not self.PointRewardGridList[index] then
            if index == 1 then
                grid = XUiGridPointReward.New(self.GridCourse, self)
                self.GridCourse.gameObject:SetActiveEx(true)
                self.GridCourse.transform:SetParent(self.PanelCourseContainer, false)
            else
                local ui = CS.UnityEngine.Object.Instantiate(self.GridCourse)
                ui.gameObject:SetActiveEx(true)
                ui.transform:SetParent(self.PanelCourseContainer, false)
                grid = XUiGridPointReward.New(ui, self)
            end
            self.PointRewardGridList[index] = grid
        else
            grid = self.PointRewardGridList[index]
        end
        
        -- 从0开始的第一段 特殊处理
        if index == 1 then
            if pointCount < tmpPointCfg.NeedPoint then
                self.ImgFirstPassedLine.fillAmount = pointCount / tmpPointCfg.NeedPoint
            else
                self.ImgFirstPassedLine.fillAmount = 1
            end
        end
        
        grid:UpdateData(tmpPointCfg, nextPointCfg, pointCount)
        if not defaultIndex and not XDataCenter.FubenSimulatedCombatManager.CheckPointRewardGet(index) then
            defaultIndex = index
        end
    end
    -- 针对全部领取的情况处理滑动
    if not defaultIndex then
        defaultIndex = #pointRewardCfg
        --如果最后一个没有被领取则不是全部被领取
        if not XDataCenter.FubenSimulatedCombatManager.CheckPointRewardGet(defaultIndex) then
            defaultIndex = nil
        end
    end

    if defaultIndex then
        self:SetSViewIndex(defaultIndex)
    end
end

function XUiSimulatedCombatMain:SetSViewIndex(defaultIndex)
    local pointRewardCfg = XFubenSimulatedCombatConfig.GetPointReward()
    local length = #pointRewardCfg or 0
    local percentage = 0
    
    if defaultIndex then
        if defaultIndex <= 5 then
            defaultIndex = -1
        end

        if length > 0 then
            percentage = (defaultIndex + 1) / (length + 1)
        end
        CS.UnityEngine.Canvas.ForceUpdateCanvases()
    end

    self.AnimTimer = XUiHelper.Tween(0.7, function(f)
        local tempPercentage = Lerp(self.SViewCourse.horizontalNormalizedPosition, percentage, f)
        self.SViewCourse.horizontalNormalizedPosition = tempPercentage
    end, nil, function(t)
        return XUiHelper.Evaluate(XUiHelper.EaseType.Sin, t)
    end)
end

function XUiSimulatedCombatMain:SetupStarReward()
    local totalStars = 0
    local isRed = false
    local curStars = XDataCenter.FubenSimulatedCombatManager.GetStarProgress()
    local starRewardList = XDataCenter.FubenSimulatedCombatManager.GetStarRewardList()

    for i, v in ipairs(starRewardList) do
        totalStars = totalStars < v.RequireStar and v.RequireStar or totalStars
        if v.IsFinish and not v.IsReward then
            isRed = true
        end
    end

    self.ImgJindu.fillAmount = totalStars > 0 and curStars / totalStars or 0
    self.ImgJindu.gameObject:SetActiveEx(true)
    --self.ImgLingqu.gameObject:SetActiveEx(totalStars <= curStars and (not isRed))
    self.BtnStarReward:ShowReddot(isRed)

    self.TxtStarNum.text = string.format("%d/%d", curStars, totalStars)
end

function XUiSimulatedCombatMain:InitUiView()
    self.BtnTask.CallBack = function() self:OpenOneChildUi(ChildUiName[ChildUiType.Task], self) end
    self.BtnStarReward.CallBack = function() self:OpenOneChildUi(ChildUiName[ChildUiType.Star], self) end
    
    self.SceneBtnBack.CallBack = function() self:OnBtnBackClick() end
    self.SceneBtnMainUi.CallBack = function() self:OnBtnMainUiClick() end

    self.BtnSwitchNormal.CallBack = function() self:OnSwitchView(StageType.Normal) end
    self.BtnSwitchHard.CallBack = function() self:OnSwitchView(StageType.Challenge) end
    self.BtnChllengeRewardHelp.CallBack = function() self:OnBtnChllengeRewardHelpClick() end

    self:BindHelpBtn(self.BtnHelp, "SimulatedCombat")
    self.PanelStage = XUiSimulatedCombatChapter.New(self.PanelChapter, self)
end

function XUiSimulatedCombatMain:OnBtnBackClick()
    self:Close()
end

function XUiSimulatedCombatMain:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiSimulatedCombatMain:OnBtnChllengeRewardHelpClick()
    XUiManager.UiFubenDialogTip(CsXTextManagerGetText("SimulatedCombatChallengeRewardHelpTitle"), CsXTextManagerGetText("SimulatedCombatChallengeRewardHelpContent"))
end

function XUiSimulatedCombatMain:OnSwitchView(type, isFromOtherUi)
    local isOpen, desc = XDataCenter.FubenSimulatedCombatManager.CheckModeOpen(type)
    if not isOpen then
        XUiManager.TipMsg(desc)
        return
    end

    if not isFromOtherUi then
        self:PlayAnimation("QieHuan")
    end
    self.CurrentView = type

    self.RImgBgNor.gameObject:SetActiveEx(type == StageType.Normal)
    self.RImgBgHard.gameObject:SetActiveEx(type == StageType.Challenge)
    self.PanelHard.gameObject:SetActiveEx(type == StageType.Challenge)
    self:Refresh()
end

-- 背景
function XUiSimulatedCombatMain:SwitchBg(actTemplate)
    if not actTemplate or not actTemplate.MainBackgound then return end
    self.RImgFestivalBg:SetRawImage(actTemplate.MainBackgound)
end

-- 计时器
function XUiSimulatedCombatMain:CreateActivityTimer(endTime)
    local time = XTime.GetServerNowTimestamp()
    self.TxtDay.text = XUiHelper.GetTime(endTime - time, XUiHelper.TimeFormatType.ACTIVITY)
    self:StopActivityTimer()
    self.ActivityTimer = XScheduleManager.ScheduleForever(function()
            time = XTime.GetServerNowTimestamp()
            if time > endTime then
                --self:StopActivityTimer()
                return
            end
            self.TxtDay.text = XUiHelper.GetTime(endTime - time, XUiHelper.TimeFormatType.ACTIVITY)
        end, XScheduleManager.SECOND, 0)
end
 
function XUiSimulatedCombatMain:StopActivityTimer()
    if self.ActivityTimer then
        XScheduleManager.UnSchedule(self.ActivityTimer)
        self.ActivityTimer = nil
    end
    
    if self.AnimTimer then
        XScheduleManager.UnSchedule(self.AnimTimer)
        self.AnimTimer = nil
    end
end