local XDynamicGridTask = require("XUi/XUiTask/XDynamicGridTask")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
---@class XUiWeekChallenge
local XUiWeekChallenge = XClass(nil, "XUiWeekChallenge")

function XUiWeekChallenge:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi

    self._Timer = false
    self._WeekIndex = 0
    self._TaskDataList = false
    self._UiWeekTab = {}
    self._UiDynamicTask = false
    ---@type XUiWeekChallengeCourse[]
    self._UiRewardGrid = {}
    self._IsInit = false
    self._IsSelectDefaultWeek = false

    self._TodayRefreshTime = -1
    
    self._SkipCallBackHandle = function() 
        XDataCenter.FunctionEventManager.OnFunctionEventBreak()
    end
end

function XUiWeekChallenge:OnShow()
    self:Refresh()
    self:RefreshReward()
end

function XUiWeekChallenge:Init()
    if self._IsInit then
        return
    end
    self._IsInit = true
    self:InitUi()
    self:InitDynamicTableTask()
    self:InitUiWeekTab()
    self:InitRewardGrid()
    self:AddListener()
    self:StartTimer()
end

function XUiWeekChallenge:OnHide()
    self:RemoveListener()
    self:StopTimer()
end

function XUiWeekChallenge:AddListener()
    XEventManager.AddEventListener(XEventId.EVENT_WEEK_CHALLENGE_UPDATE_REWARD, self.RefreshReward, self)
    XEventManager.AddEventListener(XEventId.EVENT_TASK_SYNC, self.OnTaskUpdate, self)
end

function XUiWeekChallenge:RemoveListener()
    XEventManager.RemoveEventListener(XEventId.EVENT_WEEK_CHALLENGE_UPDATE_REWARD, self.RefreshReward, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_TASK_SYNC, self.OnTaskUpdate, self)
end

function XUiWeekChallenge:OnTaskUpdate()
    self:Refresh()
    self:RefreshReward()
end

function XUiWeekChallenge:Refresh()
    self:Init()
    self:RefreshProgress()
    self:RefreshWeek()
    if not self._IsSelectDefaultWeek then
        self._IsSelectDefaultWeek = true
        self:SelectDefaultWeek()
    end
    self:RefreshWeek()
    XEventManager.DispatchEvent(XEventId.EVENT_SING_IN_OPEN_BTN, true)
end

function XUiWeekChallenge:OnClickWeek(weekIndex)
    if self:SelectWeek(weekIndex) then
        XDataCenter.WeekChallengeManager.SetLastSelectedWeek(weekIndex)
    end
end

function XUiWeekChallenge:SelectWeek(weekIndex, clickTab)
    if self._WeekIndex == weekIndex then
        return false
    end
    if XDataCenter.WeekChallengeManager.GetWeekState(weekIndex) == XWeekChallengeConfigs.WeekState.Lock then
        if not clickTab then
            XDataCenter.WeekChallengeManager.TipWeekLock(weekIndex)
        end
        return false
    end
    local oldWeekIndex = self._WeekIndex
    self._WeekIndex = weekIndex
    self:RefreshWeek()
    if oldWeekIndex > 0 then
        self.QieHuan.gameObject:PlayTimelineAnimation()
    end
    if clickTab then
        self.TabGroup:SelectIndex(weekIndex)
    end
    return true
end

function XUiWeekChallenge:RefreshWeekTabBtn(weekIndex)
    local state = XDataCenter.WeekChallengeManager.GetWeekState(weekIndex)
    local button = self._UiWeekTab[weekIndex]
    if not button then
        return
    end
    if state == XWeekChallengeConfigs.WeekState.Lock then
        button:SetButtonState(XUiButtonState.Disable)
    elseif button.ButtonState == CS.UiButtonState.Disable then -- c#枚举不等于数值3
        button:SetButtonState(XUiButtonState.Normal)
    end
end

function XUiWeekChallenge:RefreshWeek()
    local weekIndex = self._WeekIndex
    local taskDataList = XDataCenter.WeekChallengeManager.GetTaskDataArraySorted(weekIndex)
    self._TaskDataList = taskDataList
    self._UiDynamicTask:SetDataSource(taskDataList)
    self:UpdateTask()
end

function XUiWeekChallenge:UpdateTask()
    self._UiDynamicTask:ReloadDataASync(1)
end

function XUiWeekChallenge:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:SetSkipCallBack(self._SkipCallBackHandle)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self._TaskDataList[index]
        grid.RootUi = self.RootUi
        grid:ResetData(data)
    end
end

function XUiWeekChallenge:InitUiWeekTab()
    local weekAmount = XDataCenter.WeekChallengeManager.GetWeekAmount()
    for i = 1, weekAmount do
        self._UiWeekTab[i] = XUiHelper.TryGetComponent(self.Transform, "PanelRound1/TopBtnWeek/BtnWeek" .. i, "Button")
    end
    self.TabGroup:Init(
        self._UiWeekTab,
        function(tab)
            self:OnClickWeek(tab)
        end
    )
    self:RefreshAllWeekTabBtn()
end

function XUiWeekChallenge:RefreshAllWeekTabBtn()
    for i = 1, #self._UiWeekTab do
        self:RefreshWeekTabBtn(i)
    end
end

function XUiWeekChallenge:SelectDefaultWeek()
    -- 玩家选中的页签会被保存，本次登录后再次打开该界面会默认选中上次离开时的页签
    local lastSelectedWeek = XDataCenter.WeekChallengeManager.GetLastSelectedWeek()
    if lastSelectedWeek and self:SelectWeek(lastSelectedWeek, true) then
        return
    end

    -- 默认选中当前周的页签，如果当前周任务未完成
    local currentWeekIndex = XDataCenter.WeekChallengeManager.GetWeekIndex()
    if
        not XDataCenter.WeekChallengeManager.IsThisWeekAllTaskFinished(currentWeekIndex) and
            self:SelectWeek(currentWeekIndex, true)
     then
        return
    end

    -- 如果已完成，则选中周数最靠前且存在未完成任务的页签。如果全部任务完成则仍选中当前周的页签
    local weekOfTaskUnfinished = XDataCenter.WeekChallengeManager.GetWeekOfTaskUnfinished()
    if weekOfTaskUnfinished and self:SelectWeek(weekOfTaskUnfinished, true) then
        return
    end

    -- 都不符合，选当前周
    self:SelectWeek(currentWeekIndex or 1, true)
end

function XUiWeekChallenge:InitDynamicTableTask()
    local taskTransform = self.Transform:Find("PanelRound1/PanelTaskStoryList")
    self._UiDynamicTask = XDynamicTableNormal.New(taskTransform)
    self._UiDynamicTask:SetProxy(XDynamicGridTask)
    self._UiDynamicTask:SetDelegate(self)
end

-- update number
function XUiWeekChallenge:RefreshProgress()
    local value = XDataCenter.WeekChallengeManager.GetNumberOfCompletedTasks()
    local maxValue = XDataCenter.WeekChallengeManager.GetNumberOfTasks()
    self.ProgressTxt.text = string.format("%d/%d", value, maxValue)
    self.ImgProgress.fillAmount = value / maxValue
end

function XUiWeekChallenge:InitRewardGrid()
    local XUiWeekChallengeCourse = require("XUi/XUiWeekChallenge/XUiWeekChallengeCourse")
    local obj =
        self.Transform:Find("PanelRound1/PanelReward/SViewCourse/Viewport/Container/PanelCourseContainer/GridCourse")
    local instance = XUiWeekChallengeCourse.New(obj)
    self._UiRewardGrid[1] = instance

    local arrayRewardId = XDataCenter.WeekChallengeManager.GetArrayReward()
    for i = 2, #arrayRewardId do
        local obj = CS.UnityEngine.Object.Instantiate(instance.Transform, instance.Transform.parent)
        local grid = XUiWeekChallengeCourse.New(obj)
        self._UiRewardGrid[i] = grid
    end

    local arrayTaskCount = XDataCenter.WeekChallengeManager.GetArrayTaskCount()
    for i = 1, #self._UiRewardGrid do
        local rewardId = arrayRewardId[i]
        local grid = self._UiRewardGrid[i]
        local taskCount = arrayTaskCount[i]
        grid:SetReward(rewardId)
        grid:SetTaskCount(taskCount)
        XUiHelper.RegisterClickEvent(
            self,
            grid:GetButtonComponent(),
            function()
                if not XDataCenter.WeekChallengeManager.RequestReceiveReward(taskCount, handler(self, self.RefreshReward)) then
                    grid:CallClickItem()
                end
            end
        )
    end

    local obj = self._UiRewardGrid[1].Transform
    local containerWidth = self.Container.rect.width
    self.ProgressBg.sizeDelta = Vector2(containerWidth, self.ProgressBg.sizeDelta.y)
    local maxValue = XDataCenter.WeekChallengeManager.GetNumberOfTasks()
    local eachTaskWidth = containerWidth / maxValue
    for i = 1, #self._UiRewardGrid do
        local taskCount = arrayTaskCount[i]
        local adjustPosition = CS.UnityEngine.Vector3(taskCount * eachTaskWidth, obj.anchoredPosition3D.y, 0)
        self._UiRewardGrid[i].Transform.anchoredPosition3D = adjustPosition
    end
end

function XUiWeekChallenge:RefreshReward()
    for i = 1, #self._UiRewardGrid do
        local grid = self._UiRewardGrid[i]
        grid:UpdateState()
    end
end

function XUiWeekChallenge:RefreshUpdateTime()
    self._TodayRefreshTime = XTime.GetSeverNextRefreshTime()
end

function XUiWeekChallenge:StartTimer()
    if self._Timer then
        return
    end
    self:UpdateTime()
    self:RefreshUpdateTime()
    self._Timer =
        XScheduleManager.ScheduleForever(
        function()
            self:UpdateTime()
            self:CheckActivityEnd()
        end,
        XScheduleManager.SECOND
    )
end

function XUiWeekChallenge:StopTimer()
    if not self._Timer then
        return
    end
    XScheduleManager.UnSchedule(self._Timer)
    self._Timer = false
end

function XUiWeekChallenge:UpdateTime()
    local remainSeconds = XDataCenter.WeekChallengeManager.GetActivityRemainSeconds()
    self.ActivityTimeTxt.text = XUiHelper.GetTime(remainSeconds, XUiHelper.TimeFormatType.PASSPORT)

    if self._TodayRefreshTime > 0 then
        local currentTime = XTime.GetServerNowTimestamp()
        if currentTime > self._TodayRefreshTime then
            self:RefreshUpdateTime()
            self:Refresh()
            self:RefreshAllWeekTabBtn()
        end
    end
end

function XUiWeekChallenge:CheckActivityEnd()
    if not XDataCenter.WeekChallengeManager.IsOpen() then
        if XLuaUiManager.IsUiShow("UiSign") then
            XLuaUiManager.Close("UiSign")
        end
        if XLuaUiManager.IsUiShow("UiSignBanner") then
            XLuaUiManager.Close("UiSignBanner")
        end
    end
end

function XUiWeekChallenge:InitUi()
    self.ActivityTimeTxt = XUiHelper.TryGetComponent(self.Transform, "PanelRound1/PanelTime/TextTime", "Text")
    self.ProgressTxt = XUiHelper.TryGetComponent(self.Transform, "PanelRound1/PanelReward/TextNum", "Text")
    self.ImgProgress =
        XUiHelper.TryGetComponent(
        self.Transform,
        "PanelRound1/PanelReward/SViewCourse/Viewport/Container/ProgressBg/ImgProgress",
        "Image"
    )
    self.ProgressBg =
        XUiHelper.TryGetComponent(
        self.Transform,
        "PanelRound1/PanelReward/SViewCourse/Viewport/Container/ProgressBg",
        "RectTransform"
    )
    self.Container = self.Transform:Find("PanelRound1/PanelReward/SViewCourse/Viewport/Container")
    self.QieHuan = XUiHelper.TryGetComponent(self.Transform, "Animation/QieHuan", "PlayableDirector")
    self.TabGroup = XUiHelper.TryGetComponent(self.Transform, "PanelRound1/TopBtnWeek", "XUiButtonGroup")
end

return XUiWeekChallenge
