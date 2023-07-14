local XUiCoupleCombatChapter = require("XUi/XUiFubenCoupleCombat/ChildView/XUiCoupleCombatChapter")

local XUiCoupleCombatMain = XLuaUiManager.Register(XLuaUi, "UiCoupleCombatMain")

local StageType = XFubenCoupleCombatConfig.StageType

function XUiCoupleCombatMain:OnAwake()
    self.TabBtns = {}
    self.SwitchEffect = {}
end

function XUiCoupleCombatMain:OnEnable()
    self:Refresh()
end

function XUiCoupleCombatMain:OnResume(data)
    self.CurrentView = data
end

function XUiCoupleCombatMain:OnStart(defaultView)
    if not self.CurrentView then
        self.CurrentView = defaultView or StageType.Normal
    end

    self.ActTemplate = XDataCenter.FubenCoupleCombatManager.GetCurrentActTemplate()
    if not self.ActTemplate then
        return
    end

    self:CreateActivityTimer(XDataCenter.FubenCoupleCombatManager.GetEndTime())
    self.TxtTitle.text = self.ActTemplate.Name

    self:InitUiView()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    self.PointRewardGridList = {}

    self:OnSwitchView(self.CurrentView, true)
    self.RedPointNormalMode = XRedPointManager.AddRedPointEvent(self.BtnSwitchNormal, self.OnCheckNormalMode, self, { XRedPointConditions.Types.CONDITION_COUPLE_COMBAT_NORMAL }, nil, true)
    self.RedPointHardMode = XRedPointManager.AddRedPointEvent(self.BtnSwitchHard, self.OnCheckHardMode, self, { XRedPointConditions.Types.CONDITION_COUPLE_COMBAT_HARD }, nil, true)
end

function XUiCoupleCombatMain:OnReleaseInst()
    return self.CurrentView
end

function XUiCoupleCombatMain:OnGetEvents()
    return { XEventId.EVENT_FUBEN_COUPLECOMBAT_UPDATE,
             CS.XEventId.EVENT_UI_DONE,
             XEventId.EVENT_ACTIVITY_ON_RESET}
end

function XUiCoupleCombatMain:OnNotify(evt, ...)
    local args = { ... }
    if evt == XEventId.EVENT_FUBEN_COUPLECOMBAT_UPDATE then
        self:Refresh()
    elseif evt == CS.XEventId.EVENT_UI_DONE then
        if XDataCenter.FubenCoupleCombatManager.GetIsActivityEnd() then
            XDataCenter.FubenCoupleCombatManager.OnActivityEnd()
            return
        end
    elseif evt == XEventId.EVENT_ACTIVITY_ON_RESET then
        if args[1] ~= XDataCenter.FubenManager.StageType.CoupleCombat then return end
        XDataCenter.FubenCoupleCombatManager.OnActivityEnd()
    end
end

function XUiCoupleCombatMain:OnCheckNormalMode(count)
    self.BtnSwitchNormal:ShowReddot(count >= 0)
end

function XUiCoupleCombatMain:OnCheckHardMode(count)
    self.BtnSwitchHard:ShowReddot(count >= 0)
end

function XUiCoupleCombatMain:Refresh(isAutoScroll)
    if XDataCenter.FubenCoupleCombatManager.GetIsActivityEnd() then
        XDataCenter.FubenCoupleCombatManager.OnActivityEnd()
        return
    end
    self.BtnSwitchNormal.gameObject:SetActiveEx(self.CurrentView == StageType.Hard)
    self.BtnSwitchHard.gameObject:SetActiveEx(self.CurrentView == StageType.Normal)

    self.PanelStage:SetUiData(self.CurrentView, isAutoScroll)

    local passCount, allCount = XDataCenter.FubenCoupleCombatManager.GetStageSchedule(self.CurrentView)
    self.TxtPassCount.text = passCount
    self.TxtStageCount.text = string.format("/%d", allCount)

    passCount, allCount = XDataCenter.TaskManager.GetTaskProgress(TaskType.CoupleCombat, self.CurrentView)
    self.TxtTaskGotCount.text = passCount
    self.TxtTaskCount.text = allCount
    self.ImgJindu.fillAmount = passCount / allCount

    self.BtnTaskReward:ShowReddot(XDataCenter.TaskManager.GetIsRewardForEx(TaskType.CoupleCombat, self.CurrentView))
    XRedPointManager.Check(self.RedPointNormalMode)
    XRedPointManager.Check(self.RedPointHardMode)
    local isOpen = XDataCenter.FubenCoupleCombatManager.CheckModeOpen(StageType.Hard)
    self.BtnSwitchHard:SetButtonState(isOpen and XUiButtonState.Normal or XUiButtonState.Disable)
end

function XUiCoupleCombatMain:OnDestroy()
    self:StopActivityTimer()
    if self.PanelStage then
        self.PanelStage:OnDestroy()
    end
end

function XUiCoupleCombatMain:InitUiView()
    self.SceneBtnBack.CallBack = function() self:OnBtnBackClick() end
    self.SceneBtnMainUi.CallBack = function() self:OnBtnMainUiClick() end

    self.BtnSwitchNormal.CallBack = function() self:OnSwitchView(StageType.Normal) end
    self.BtnSwitchHard.CallBack = function() self:OnSwitchView(StageType.Hard) end
    self.BtnTaskReward.CallBack = function() self:OnBtnTaskRewardClick() end

    self:BindHelpBtn(self.BtnHelp, "CoupleCombat")
    self.PanelStage = XUiCoupleCombatChapter.New(self.PanelChapter, self)
end

function XUiCoupleCombatMain:OnBtnBackClick()
    self:Close()
end

function XUiCoupleCombatMain:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiCoupleCombatMain:OnBtnTaskRewardClick()
    XLuaUiManager.Open("UiFubenTaskReward", TaskType.CoupleCombat, self.CurrentView, function()
        self:Refresh()
    end)
end

function XUiCoupleCombatMain:OnSwitchView(type, isFromOtherUi)
    local isOpen, desc = XDataCenter.FubenCoupleCombatManager.CheckModeOpen(type)
    if not isOpen then
        XUiManager.TipMsg(desc)
        return
    end

    if not isFromOtherUi then
        self:PlayAnimation("QieHuan")
    end
    self.CurrentView = type
    XDataCenter.FubenCoupleCombatManager.SetReadNewStageMark(type)
    self.RImgBgNor.gameObject:SetActiveEx(type == StageType.Normal)
    self.RImgBgHard.gameObject:SetActiveEx(type == StageType.Hard)
    self:Refresh(true)
end

-- 计时器
function XUiCoupleCombatMain:CreateActivityTimer(endTime)
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
 
function XUiCoupleCombatMain:StopActivityTimer()
    if self.ActivityTimer then
        XScheduleManager.UnSchedule(self.ActivityTimer)
        self.ActivityTimer = nil
    end
    
    if self.AnimTimer then
        XScheduleManager.UnSchedule(self.AnimTimer)
        self.AnimTimer = nil
    end
end