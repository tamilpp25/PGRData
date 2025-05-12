local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XUiReform2ndPanelGroup = require("XUi/XUiReform2nd/MainPage/XUiReform2ndPanelGroup")
local XUiReform2ndPanelTasks = require("XUi/XUiReform2nd/MainPage/XUiReform2ndPanelTasks")
local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")

---@field _Control XReformControl
---@class XUiReform2:XLuaUi
local XUiReform2 = XLuaUiManager.Register(XLuaUi, "UiReform2")

function XUiReform2:Ctor()
    --self.StagePanel = nil
    ---@type XUiReform2ndPanelGroup
    self.ChapterGroup = nil
    self.PanelTasks = nil
    self.RewardList = {}
    self.TaskRedPoint = nil

    ---@type XViewModelReform2nd
    self._ViewModel = self._Control:GetViewModel()

    self.Timer = nil
    self.StageOpenTimer = nil

    self._IsToggleOn = false

    self._TimerAnimationQiehuan = false
    -- 切换界面不播放
    self._IsJustEnableToggle = false
    -- 首次进入界面播放
    self._IsJustEnter = true
end

function XUiReform2:OnAwake()
    XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint)

    self:BindExitBtns(self.BtnBack, self.BtnMainUi)
    self:BindHelpBtn(self.BtnHelp, "ReformHelp")
    self:InitPanel(true)
    self:InitTaskRewardDisplay()
    self:RegisterClickEvent(self.BtnGift, self.OpenTaskReward)
    self.ChapterGroup = XUiReform2ndPanelGroup.New(self.PanelGroup, self, self._ViewModel)
    --self.StagePanel = XUiReform2ndStagePanel.New(self, self.PanelSecondary, self._ViewModel)
    self.PanelTaskReward.gameObject:SetActiveEx(false)
    self.TaskRedPoint = XRedPointManager.AddRedPointEvent(self.BtnGift, self.OnCheckTaskRedPoint, self, { XRedPointConditions.Types.CONDITION_REFORM_TASK_GET_REWARD }, nil, true)
    self:RefreshEndTime()

    local isUnlockDiff, stageName = self._ViewModel:GetUnlockedHardStageName()

    if stageName then
        --self:OpenStagePanel()
        --self.StagePanel:RefreshStageGrid()
        self.ChapterGroup:CloseRedPoint(self._ViewModel:GetCurrentChapterIndex())

        if isUnlockDiff then
            XUiManager.TipMsg(XUiHelper.GetText("ReformDiffUnlockedTip", stageName))
        end
    end

    ---@type UnityEngine.UI.Toggle
    local toggle = self.TogHell
    toggle.onValueChanged:AddListener(function(isOn)
        if self._IsToggleOn ~= isOn then
            isOn = self:OnClickToggleHard(isOn)
            -- 在困难模式未开启时, 点击无效
            self._IsToggleOn = isOn
            toggle.isOn = isOn
            self:UpdateToggle()
        end
    end)
end

function XUiReform2:OnEnable()
    self._IsJustEnableToggle = true
    ---@type UnityEngine.UI.Toggle
    local toggle = self.TogHell
    local isOn = self._Control:GetViewModelList():IsSelectToggleHard()
    toggle.isOn = isOn
    self._IsToggleOn = isOn
    self._IsJustEnableToggle = false

    XUiReform2.Super.OnEnable(self)
    self.ChapterGroup:RefreshBtnGrid()
    self:UpdateToggle()
    self:Refresh()
    self.Timer = XScheduleManager.ScheduleForever(function()
        self:RefreshRemainTime()
    end, XScheduleManager.SECOND, 0)
    -- 因为按时间解锁, 所以要每秒刷新 ,有优化空间其实
    self.StageOpenTimer = XScheduleManager.ScheduleForever(function()
        if self._TimerAnimationQiehuan then
            return
        end
        self.ChapterGroup:RefreshBtnGrid()
    end, XScheduleManager.SECOND, 0)

    if self.TaskRedPoint then
        XRedPointManager.Check(self.TaskRedPoint)
    end

    XEventManager.AddEventListener(XEventId.EVENT_ETCD_TIME_CHANGE, self.RefreshEndTime, self)

    if self._IsJustEnter then
        self:PlayAnimationQieHuan()
        self._IsJustEnter = false
    end
end

function XUiReform2:OnDisable()
    XUiReform2.Super.OnDisable(self)
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
    end
    if self.StageOpenTimer then
        XScheduleManager.UnSchedule(self.StageOpenTimer)
        self.StageOpenTimer = false
    end

    XEventManager.RemoveEventListener(XEventId.EVENT_ETCD_TIME_CHANGE, self.RefreshEndTime, self)
end

function XUiReform2:OnDestroy()
    XRedPointManager.RemoveRedPointEvent(self.TaskRedPoint)

    self._ViewModel:ReleaseConfig()
    --self.StagePanel = nil
    self.ChapterGroup = nil
    self.PanelTasks = nil
    self.RewardList = nil
    self.TaskRedPoint = nil
    self._ViewModel = nil
    self.Timer = nil
    self.StageOpenTimer = nil

    if self._TimerAnimationQiehuan then
        XScheduleManager.UnSchedule(self._TimerAnimationQiehuan)
        self._TimerAnimationQiehuan = false
    end
    if XLuaUiManager.IsMaskShow("UiReform") then
        XLuaUiManager.SetMask(false, "UiReform")
    end
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
    local rewardsData = self._ViewModel:GetDisplayRewards()

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
    local txt, imgExp = self._ViewModel:GetTaskProgressTextAndImgExp()

    self.BtnGift:SetNameByGroup(0, txt)
    self.NormalImgTaskExp.fillAmount = imgExp
    self.PressImgTaskExp.fillAmount = imgExp
end

function XUiReform2:RefreshTask()
    local taskData = self._ViewModel:GetTaskDataList()

    self.PanelTasks:SetData(taskData)
    self.PanelTasks:Refresh()

    if self.TaskRedPoint then
        XRedPointManager.Check(self.TaskRedPoint)
    end
end

function XUiReform2:OpenStagePanel()
    local stage = self._ViewModel:GetCurrentStage()
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
        self.PanelTasks = XUiReform2ndPanelTasks.New(self, self.PanelTaskReward, self._ViewModel)
    end

    self:RefreshTask()
end

function XUiReform2:CloseStagePanel()
    --self:PlayAnimation("MainEnable")
    --self:InitPanel(true)
    --self.ChapterGroup:RefreshBtnGrid()
    --self:RegisterClickEvent(self.BtnBack, self.Close, true)
    --self._ViewModel:SetStageIsSelectToLocal()
end

function XUiReform2:OnCheckTaskRedPoint(count)
    self.BtnGift:ShowReddot(count >= 0)
end

function XUiReform2:OnClickToggleHard(isOn)
    if not self._Control:IsUnlockAllStageHard() and not self._Control:IsSuperior() then
        XUiManager.TipText("ReformLockDifficulty")
        return false
    end
    self._Control:GetViewModelList():OnClickToggleHard(isOn)
    self.ChapterGroup:RefreshBtnGrid()

    --if isOn then
    --    self._Control:SetAllChapterCanChallengeNotJustUnlockToggleHard()
    --end
    self:PlayAnimationQieHuan()
    return isOn
end

function XUiReform2:UpdateRedPointToggleHard()
    if not self.Red then
        return
    end
    -- 在非困难模式下, 提示困难模式红点
    if self.TogHell.isOn == false then
        local isShowRedPoint = XMVCA.XReform:CheckToggleHard()
        self.Red.gameObject:SetActiveEx(isShowRedPoint)
    else
        self.Red.gameObject:SetActiveEx(false)
    end
end

function XUiReform2:UpdateEffect()
    local isOn = self._IsToggleOn
    if isOn then
        self.PanelEffect.gameObject:SetActiveEx(false)
        self.PanelEffect02.gameObject:SetActiveEx(true)
    else
        self.PanelEffect.gameObject:SetActiveEx(true)
        self.PanelEffect02.gameObject:SetActiveEx(false)
    end
end

function XUiReform2:UpdateToggle()
    self:UpdateRedPointToggleHard()
    self:UpdateEffect()
    self:UpdateUiForDifficulty()
end

function XUiReform2:PlayAnimationQieHuan()
    if self._IsJustEnableToggle then
        return
    end
    self:PlayAnimation("ModeQiehuan")
    local gridList = self.ChapterGroup:GetBtnChapters()
    local activeButton = {}
    for i = 1, #gridList do
        local grid = gridList[i]
        local uiButton = grid:GetUiButton()
        local activeInHierarchy = uiButton.gameObject.activeInHierarchy
        if activeInHierarchy then
            activeButton[#activeButton + 1] = uiButton
            uiButton.gameObject:SetActiveEx(false)
        end
    end

    local index = 0
    XLuaUiManager.SetMask(true, "UiReform")
    self._TimerAnimationQiehuan = XScheduleManager.ScheduleForever(function()
        index = index + 1
        local uiButton = activeButton[index]
        if not uiButton then
            XScheduleManager.UnSchedule(self._TimerAnimationQiehuan)
            self._TimerAnimationQiehuan = false
            XLuaUiManager.SetMask(false, "UiReform")
            return
        end
        uiButton.gameObject:SetActiveEx(true)
        local animation = XUiHelper.TryGetComponent(uiButton.transform, "PanelBtn1/Animation/Btn1Enable", "Transform")
        if animation and animation.gameObject.activeInHierarchy then
            animation:PlayTimelineAnimation()
        end
    end, 80)
end

-- 背景
function XUiReform2:UpdateUiForDifficulty()
    if self._IsToggleOn then
        self.RImgBg.gameObject:SetActiveEx(false)
        self.RImgBgHard.gameObject:SetActiveEx(true)
    else
        self.RImgBg.gameObject:SetActiveEx(true)
        self.RImgBgHard.gameObject:SetActiveEx(false)
    end

    if self.RImgTittle then
        if self._IsToggleOn then
            self.RImgTittle.gameObject:SetActiveEx(false)
            self.RImgTittleRed.gameObject:SetActiveEx(true)
        else
            self.RImgTittle.gameObject:SetActiveEx(true)
            self.RImgTittleRed.gameObject:SetActiveEx(false)
        end
    end
end

return XUiReform2
