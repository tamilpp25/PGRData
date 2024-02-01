local XUiReform2ndPanelGroup = require("XUi/XUiReform2nd/MainPage/XUiReform2ndPanelGroup")
local XUiReform2ndStagePanel = require("XUi/XUiReform2nd/MainPage/XUiReform2ndStagePanel")
local XUiReform2ndPanelTasks = require("XUi/XUiReform2nd/MainPage/XUiReform2ndPanelTasks")
local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")

---@field _Control XReformControl
---@class XUiReform2:XLuaUi
local XUiReform2 = XLuaUiManager.Register(XLuaUi, "UiReform2")

function XUiReform2:Ctor()
    self.ChapterGridList = {}
    --self.StagePanel = nil
    self.ChapterGroup = nil
    self.PanelTasks = nil
    self.RewardList = {}
    self.TaskRedPoint = nil

    ---@type XViewModelReform2nd
    self.ViewModel = self._Control:GetViewModel()

    self.Timer = nil
    self.StageOpenTimer = nil
end

function XUiReform2:OnAwake()
    XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint)

    self:BindExitBtns(self.BtnBack, self.BtnMainUi)
    self:BindHelpBtn(self.BtnHelp, "ReformHelp")
    self:InitPanel(true)
    self:InitTaskRewardDisplay()
    self:RegisterClickEvent(self.BtnGift, self.OpenTaskReward)
    self.ChapterGroup = XUiReform2ndPanelGroup.New(self.PanelGroup, self, self.ViewModel)
    --self.StagePanel = XUiReform2ndStagePanel.New(self, self.PanelSecondary, self.ViewModel)
    self.PanelTaskReward.gameObject:SetActiveEx(false)
    self.TaskRedPoint = XRedPointManager.AddRedPointEvent(self.BtnGift, self.OnCheckTaskRedPoint, self, { XRedPointConditions.Types.CONDITION_REFORM_TASK_GET_REWARD }, nil, true)
    self:RefreshEndTime()

    local isUnlockDiff, stageName = self.ViewModel:GetUnlockedHardStageName()

    if stageName then
        --self:OpenStagePanel()
        --self.StagePanel:RefreshStageGrid()
        self.ChapterGroup:CloseRedPoint(self.ViewModel:GetCurrentChapterIndex())

        if isUnlockDiff then
            XUiManager.TipMsg(XUiHelper.GetText("ReformDiffUnlockedTip", stageName))
        end
    end
end

function XUiReform2:OnEnable()
    XUiReform2.Super.OnEnable(self)
    self.ChapterGroup:RefreshBtnGrid()
    self:Refresh()
    self.Timer = XScheduleManager.ScheduleForever(function()
        self:RefreshRemainTime()
    end, XScheduleManager.SECOND, 0)
    self.StageOpenTimer = XScheduleManager.ScheduleForever(function()
        --if self.StagePanel then
        --    if self.StagePanel:CheckStageTimeOpen() then
        --        self.StagePanel:RefreshStageGrid()
        --    end
        --end
    end, XScheduleManager.SECOND, 0)

    if self.TaskRedPoint then
        XRedPointManager.Check(self.TaskRedPoint)
    end

    XEventManager.AddEventListener(XEventId.EVENT_ETCD_TIME_CHANGE, self.RefreshEndTime, self)
end

function XUiReform2:OnDisable()
    XUiReform2.Super.OnDisable(self)
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
    end
    if self.StageOpenTimer then
        XScheduleManager.UnSchedule(self.StageOpenTimer)
    end

    XEventManager.RemoveEventListener(XEventId.EVENT_ETCD_TIME_CHANGE, self.RefreshEndTime, self)
end

function XUiReform2:OnDestroy()
    XRedPointManager.RemoveRedPointEvent(self.TaskRedPoint)

    self.ViewModel:ReleaseConfig()
    self.ChapterGridList = nil
    --self.StagePanel = nil
    self.ChapterGroup = nil
    self.PanelTasks = nil
    self.RewardList = nil
    self.TaskRedPoint = nil
    self.ViewModel = nil
    self.Timer = nil
    self.StageOpenTimer = nil
end

function XUiReform2:RefreshEndTime()
    local openAutoClose, autoCloseEndTime, callback = self:GetAutoCloseInfo()

    if openAutoClose then
        self:SetAutoCloseInfo(autoCloseEndTime, callback)
    end
end

function XUiReform2:InitPanel(isShowPanelGroup)
    self.PanelGroup.gameObject:SetActiveEx(isShowPanelGroup)
    --self.PanelSecondary.gameObject:SetActiveEx(not isShowPanelGroup)
    self.PanelTittle.gameObject:SetActiveEx(isShowPanelGroup)
    self.TxtRemainTime.text = self._Control:GetActivityTime()
end

function XUiReform2:InitTaskRewardDisplay()
    local rewardsData = self.ViewModel:GetDisplayRewards()

    XUiHelper.RefreshCustomizedList(self.PanelReward, self.GridReward, #rewardsData, function(index, obj)
        local gridCommont = XUiGridCommon.New(self, obj)

        gridCommont:Refresh(rewardsData[index])
    end)
end

function XUiReform2:GetAutoCloseInfo()
    local endTime = self._Control:GetActivityEndTime()

    return true, endTime, function(isClose)
        if isClose then
            XMVCA.XReform:HandleActivityEndTime()
        end
    end
end

function XUiReform2:RefreshRemainTime()
    self.TxtRemainTime.text = self._Control:GetActivityTime()
end

function XUiReform2:Refresh()
    local txt, imgExp = self.ViewModel:GetTaskProgressTextAndImgExp()

    self.BtnGift:SetNameByGroup(0, txt)
    self.NormalImgTaskExp.fillAmount = imgExp
    self.PressImgTaskExp.fillAmount = imgExp
end

function XUiReform2:RefreshTask()
    local taskData = self.ViewModel:GetTaskDataList()

    self.PanelTasks:SetData(taskData)
    self.PanelTasks:Refresh()

    if self.TaskRedPoint then
        XRedPointManager.Check(self.TaskRedPoint)
    end
end

function XUiReform2:OpenStagePanel()
    local stage = self.ViewModel:GetCurrentStage()
    --viewModel:SaveIndexToManager()
    XLuaUiManager.Open("UiReformList", stage)

    --self:InitPanel(false)
    --
    --self.StagePanel:RefreshStageGrid()
    --self.StagePanel:RefreshDetailPanel()
    --self:RegisterClickEvent(self.BtnBack, self.CloseStagePanel, true)
end

function XUiReform2:OpenTaskReward()
    self.PanelTaskReward.gameObject:SetActiveEx(true)

    if not self.PanelTasks then
        self.PanelTasks = XUiReform2ndPanelTasks.New(self, self.PanelTaskReward, self.ViewModel)
    end

    self:RefreshTask()
end

function XUiReform2:CloseStagePanel()
    --self:PlayAnimation("MainEnable")
    --self:InitPanel(true)
    --self.ChapterGroup:RefreshBtnGrid()
    --self:RegisterClickEvent(self.BtnBack, self.Close, true)
    --self.ViewModel:SetStageIsSelectToLocal()
end

function XUiReform2:OnCheckTaskRedPoint(count)
    self.BtnGift:ShowReddot(count >= 0)
end

return XUiReform2
