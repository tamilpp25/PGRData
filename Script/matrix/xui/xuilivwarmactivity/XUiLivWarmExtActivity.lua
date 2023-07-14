local XUiLivWarmExtActivity = XLuaUiManager.Register(XLuaUi, "UiLivWarmExtActivity")
local XUiLivWarmExtActivityTaskPanel = require("XUi/XUiLivWarmActivity/XUiLivWarmExtActivityTaskPanel")
local CSTextManager = CS.XTextManager.GetText

function XUiLivWarmExtActivity:OnAwake()
end

function XUiLivWarmExtActivity:OnStart()
    self.PanelReward = XUiLivWarmExtActivityTaskPanel.New(self.PanelCheckReward, self)
    self.ActivityId = XDataCenter.LivWarmExtActivityManager.GetActivityId()
    self:InitTimer()
    self:AddListener()
end

function XUiLivWarmExtActivity:OnGetEvents()
    return {
        XEventId.EVENT_XLIVWARM_EXT_ACTIVITY_END,
        XEventId.EVENT_TASK_SYNC,
        XEventId.EVENT_XLIVWARM_EXT_ACTIVITY_CLICK,
    }
end

function XUiLivWarmExtActivity:OnNotify(evt, ...)
    if evt == XEventId.EVENT_XLIVWARM_EXT_ACTIVITY_END then
        XDataCenter.LivWarmExtActivityManager.CheckActivityIsOpen()
    elseif evt == XEventId.EVENT_TASK_SYNC then
        self:RefreshTask()
    elseif evt == XEventId.EVENT_XLIVWARM_EXT_ACTIVITY_CLICK then
        self:RefreshBtnRed(...)
    end
end

function XUiLivWarmExtActivity:OnEnable()
    if not XDataCenter.LivWarmExtActivityManager.CheckActivityIsOpen() then
        return
    end
    self:RefreshUi()
    self:RefreshBtnUi()
    self:RefreshTask()
end

function XUiLivWarmExtActivity:OnDisable()
end

function XUiLivWarmExtActivity:OnDestroy()
    XCountDown.UnBindTimer(self.PanelTitle, XCountDown.GTimerName.LivWarmExActivity)
end

function XUiLivWarmExtActivity:InitTimer()
    XCountDown.BindTimer(self.PanelTitle, XCountDown.GTimerName.LivWarmExActivity, function(v)
        if not XDataCenter.LivWarmExtActivityManager.CheckActivityIsOpen() then
            return
        end
        self.TextTitleTime.text = XUiHelper.GetTime(v, XUiHelper.TimeFormatType.ACTIVITY)
    end)
end

function XUiLivWarmExtActivity:RefreshUi()
    self.ImageBackground:SetRawImage(XLivWarmExtActivityConfig.GetSuitAbleImgUrl())
    self:RefreshTitle()
end

function XUiLivWarmExtActivity:RefreshBtnUi()
    local length = XLivWarmExtActivityConfig.GetLivWarmExtTimelineLength()
    for i = 1, length do
        local timeId = XLivWarmExtActivityConfig.GetLivWarmExtTimelineTimeId(i)
        local isInTime = XFunctionManager.CheckInTimeByTimeId(timeId)
        local btnPath = ""
        local descName = ""
        local descTime = ""
        if isInTime then
            btnPath = XLivWarmExtActivityConfig.GetLivWarmExtTimelineUnlockIcon(i)
            descName = XLivWarmExtActivityConfig.GetLivWarmExtTimelineName(i)
        else
            btnPath = XLivWarmExtActivityConfig.GetLivWarmExtTimelineLockedIcon(i)
            local startTime = XFunctionManager.GetStartTimeByTimeId(timeId)
            local nowTime = XTime.GetServerNowTimestamp()
            descTime = CSTextManager("LivWarmExtActivityTime",XUiHelper.GetTime(startTime - nowTime, XUiHelper.TimeFormatType.MAINBATTERY))
            descName = CSTextManager("LivWarmExtActivityExpectation")
        end
        self["Btn"..i]:SetDisable(not isInTime,isInTime)
        self["Btn"..i]:SetRawImage(btnPath)
        self["Btn"..i]:SetNameByGroup(0,descTime)
        self["Btn"..i]:SetNameByGroup(1,descName)
        self:RefreshBtnRed(i)
    end
end

function XUiLivWarmExtActivity:RefreshBtnRed(index)
    local timeId = XLivWarmExtActivityConfig.GetLivWarmExtTimelineTimeId(index)
    local isInTime = XFunctionManager.CheckInTimeByTimeId(timeId)
    if isInTime then
        self["Btn"..index]:ShowReddot(not XDataCenter.LivWarmExtActivityManager.CheckEverClickIndex(index))
    else
        self["Btn"..index]:ShowReddot(false)
    end
end


function XUiLivWarmExtActivity:AddListener()
    self.BtnBack.CallBack = function()
        self:OnBtnBackClick()
    end
    self.BtnMainUi.CallBack = function()
        self:OnBtnMainUiClick()
    end

    local length = XLivWarmExtActivityConfig.GetLivWarmExtTimelineLength()
    for i = 1, length do
        self["Btn"..i].CallBack = function()
            CS.UnityEngine.Application.OpenURL(XLivWarmExtActivityConfig.GetLivWarmExtTimelineUrl(i))
            XDataCenter.LivWarmExtActivityManager.SaveClickIndex(i)
        end
    end

    self:RegisterClickEvent(self.BtnGift, function()
        self:Switch2RewardList()
    end)
end

function XUiLivWarmExtActivity:OnBtnBackClick()
    self:Close()
end

function XUiLivWarmExtActivity:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiLivWarmExtActivity:RefreshTitle()
    self.PanelTitle.text = XLivWarmExtActivityConfig.GetActivityName(self.ActivityId)
end

function XUiLivWarmExtActivity:Switch2RewardList()
    self.PanelReward.GameObject:SetActiveEx(true)
    self.PanelReward:UpdateRewardList(TaskType.LivWarmExtActivity)
end

function XUiLivWarmExtActivity:RefreshTask()
    local taskList = XDataCenter.TaskManager.GetTaskList(TaskType.LivWarmExtActivity)
    local passCount, allCount = XDataCenter.TaskManager.GetTaskProgressByTaskList(taskList)
    self.TxtTitle.text = CSTextManager("LivWarmExtActivityProgress", passCount, allCount)
    self.BtnGift:ShowReddot(XDataCenter.LivWarmExtActivityManager.CheckTaskRedPoint())
    if self.PanelReward.GameObject.activeSelf then
        self.PanelReward:UpdateRewardList(TaskType.LivWarmExtActivity)
    end
end
