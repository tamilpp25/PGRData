XUiPanelTaskDaily = XClass(nil, "XUiPanelTaskDaily")

local DailyTimeSchedule = nil
local ProTime = 2
local GridTimeAnimation = 50
local IsMulting = false
local ShowRewardList = {}

function XUiPanelTaskDaily:Ctor(ui, parent)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Parent = parent

    XTool.InitUiObject(self)
    self.BtnWeekActive.CallBack = function() self:OnBtnBackClick() end

    self.PanelActive.gameObject:SetActiveEx(false)
    self:InitPanelActiveGrid()
    self.ItemObjList = {}

    -- 自适应调整
    self.OriginPosition = self.PanelActiveGrids[1].Transform.localPosition
    self.ActiveProgressRect = self.ImgDaylyActiveProgress:GetComponent("RectTransform")
    self.ActiveProgressPosition = self.ImgDaylyActiveProgress.transform.localPosition
    self.OffsetPanelPosition = self.PanelContent.localPosition
    self.PanelDailyListRect = self.PanelTaskDailyList

    -- self:UpdateActiveness()
    self:ShowDailyPanel()

    self.DynamicTable = XDynamicTableNormal.New(self.PanelTaskDailyList.gameObject)
    self.DynamicTable:SetProxy(XDynamicDailyTask)
    self.DynamicTable:SetDelegate(self)

    XRedPointManager.AddRedPointEvent(self.ImgWeek, self.CheckWeeKActiveRedDot, self, { XRedPointConditions.Types.CONDITION_TASK_WEEK_ACTIVE })
    XDataCenter.ItemManager.AddCountUpdateListener(XDataCenter.ItemManager.ItemId.DailyActiveness, function()
        self:UpdateActiveness()
        self.Parent:CheckDailyTask()
    end, self.TxtDailyActive)
end

--动态列表事件
function XUiPanelTaskDaily:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.DailyTasks[index]
        if data == nil then return end
        grid.RootUi = self.Parent
        grid:ResetData(data)
        self.GridCount = self.GridCount + 1
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        if not self.IsPlayAnimation then
            return
        end

        local grids = self.DynamicTable:GetGrids()
        self.GridIndex = 1
        self.CurAnimationTimerId = XScheduleManager.Schedule(function()
            local item = grids[self.GridIndex]
            if item then
                item.GameObject:SetActiveEx(true)
                item:PlayAnimation()
            end
            self.GridIndex = self.GridIndex + 1
        end, GridTimeAnimation, self.GridCount, 0)
    end
end

--
function XUiPanelTaskDaily:CheckWeeKActiveRedDot(count)
    self.ImgWeek.gameObject:SetActiveEx(count >= 0)
end

function XUiPanelTaskDaily:InitPanelActiveGrid()
    self.PanelActiveGrids = {}
    self.PanelActiveGridRects = {}
    for i = 1, 5, 1 do
        local grid = self.PanelActiveGrids[i]
        if not grid then
            if i == 1 then
                grid = XUiPanelActive.New(self.PanelActive, self.Parent, i, self)
            else
                local activeGO = CS.UnityEngine.Object.Instantiate(self.PanelActive)
                activeGO.transform:SetParent(self.PanelContent, false)
                grid = XUiPanelActive.New(activeGO, self.Parent, i, self)
            end
            self.PanelActiveGrids[i] = grid
            self.PanelActiveGridRects[i] = grid.Transform:GetComponent("RectTransform")
        end
    end
end

function XUiPanelTaskDaily:UpdateActiveness()
    local dActiveness = XDataCenter.ItemManager.GetDailyActiveness().Count
    local dailyActiveness = XTaskConfig.GetDailyActiveness()
    local dailyActivenessTotal = XTaskConfig.GetDailyActivenessTotal()

    if dailyActivenessTotal > 0 then
        local fillAmount = dActiveness / dailyActivenessTotal
        if self.Curfillamount ~= fillAmount then
            self.ImgDaylyActiveProgress:DOFillAmount(fillAmount, ProTime)
            self.Curfillamount = fillAmount
        end
    end

    self.TxtDailyActive.text = dActiveness
    for i = 1, 5 do
        self.PanelActiveGrids[i]:UpdateActiveness(dailyActiveness[i], dActiveness)
    end

    -- 自适应
    local activeProgressRectSize = self.ActiveProgressRect.rect.size
    local offsetWidth = self.OffsetPanelPosition.x - self.ActiveProgressPosition.x
    local itemOffset = activeProgressRectSize.x / #self.PanelActiveGrids
    for i = 1, #self.PanelActiveGrids do
        local itemWidth = self.PanelActiveGridRects[i].sizeDelta.x / 2
        local adjustPosition = CS.UnityEngine.Vector3(self.ActiveProgressPosition.x + i * itemOffset - offsetWidth - itemWidth, self.OriginPosition.y, self.OriginPosition.z)
        self.PanelActiveGridRects[i].anchoredPosition3D = adjustPosition
        self.PanelActiveGridRects[i].gameObject:SetActiveEx(true)
    end
end

function XUiPanelTaskDaily:OnBtnBackClick()
    self:ShowDailyPanel()
end

function XUiPanelTaskDaily:ShowDailyPanel()
    self.PanelDaily.gameObject:SetActiveEx(true)
end

function XUiPanelTaskDaily:ShowPanel(isPlayAnimation)
    self.GridCount = 0
    self.IsPlayAnimation = isPlayAnimation
    self:StartSchedule()
    self.GameObject:SetActiveEx(true)

    local tasks = self:GetTasks()
    self.DailyTasks = tasks
    self.PanelNoneDailyTask.gameObject:SetActiveEx(#self.DailyTasks <= 0)
    self.DynamicTable:SetDataSource(tasks)
    self.DynamicTable:ReloadDataASync()
end

function XUiPanelTaskDaily:GetTasks()
    local allAchieveTasks = {}
    local tasks = XDataCenter.TaskManager.GetDailyTaskList()
    for _, v in pairs(tasks) do
        if v.State == XDataCenter.TaskManager.TaskState.Achieved then
            table.insert(allAchieveTasks , v.Id) 
        end
    end

    local finalResultTaskDataList = {}
    if allAchieveTasks and next(allAchieveTasks) then
        self.ReceiveAll = true        -- 一键领取激活

        local receiveCb = function ()
            IsMulting = true
            XLuaUiManager.SetMask(true)
            XDataCenter.TaskManager.FinishMultiTaskRequest(allAchieveTasks, function(rewardGoodsList)
                -- 第一次请求返回 必不做弹窗奖励，插入奖励列表 等待refresh 检测同步的任务是否还有未领取
                for key, reward in pairs(rewardGoodsList) do
                    table.insert(ShowRewardList, reward)
                end
            end)
        end
        finalResultTaskDataList[1] = {ReceiveAll = true, AllAchieveTaskDatas = allAchieveTasks, ReceiveCb = receiveCb}

        for i = 1, #tasks do
            table.insert(finalResultTaskDataList, tasks[i])
        end
    else
        self.ReceiveAll = false
        finalResultTaskDataList = tasks 
    end

    return finalResultTaskDataList
end

function XUiPanelTaskDaily:HidePanel()
    self.IsPlayAnimation = false
    self:StopSchedule()
    self.GameObject:SetActiveEx(false)
end

function XUiPanelTaskDaily:CheckRefreshLeftNewTask()
    local tempTasks = self:GetTasks()
    -- 同步任务刷新 开始检查是否有剩余任务
    if self.ReceiveAll then --有剩余的未激活任务
        local leftTasks = tempTasks[1].AllAchieveTaskDatas
        if leftTasks and next(leftTasks) then
            XDataCenter.TaskManager.FinishMultiTaskRequest(leftTasks, function(rewardGoodsList)
                -- 有剩余任务 返回的奖励必不弹窗，插入奖励列表
                for key, reward in pairs(rewardGoodsList) do
                    table.insert(ShowRewardList, reward)
                end
            end)
        end
    elseif not self.ReceiveAll and ShowRewardList and next(ShowRewardList) then
        -- 没有剩余任务了，弹窗任务奖励
        local horizontalNormalizedPosition = 0
        XUiManager.OpenUiObtain(ShowRewardList, nil, nil, nil, horizontalNormalizedPosition)
        ShowRewardList = {} --刷新奖励列表
        IsMulting = false
        XLuaUiManager.SetMask(false)
    end

    return self.ReceiveAll
end

function XUiPanelTaskDaily:Refresh(isMulti)
    if isMulti and self:CheckRefreshLeftNewTask() then
        return
    end

    if IsMulting then  -- 一键领取未结束不刷新列表
        return
    end

    local tasks = self:GetTasks()
    self.DailyTasks = tasks
    self.PanelNoneDailyTask.gameObject:SetActiveEx(#self.DailyTasks <= 0)
    self.DynamicTable:SetDataSource(tasks)
    self.DynamicTable:ReloadDataSync()
    self:UpdateActiveness()
end

function XUiPanelTaskDaily:StartSchedule()
    self:StopSchedule()
    DailyTimeSchedule = XScheduleManager.ScheduleForever(function()
        if self.DynamicTable then
            for i = 1, #self.DailyTasks do
                local grid = self.DynamicTable:GetGridByIndex(i)
                if grid then
                    grid:UpdateTimes()
                end
            end
        end
    end, 1000 * 60)
end

function XUiPanelTaskDaily:StopSchedule()
    if DailyTimeSchedule then
        XScheduleManager.UnSchedule(DailyTimeSchedule)
        DailyTimeSchedule = nil
    end
    if self.CurAnimationTimerId then
        XScheduleManager.UnSchedule(self.CurAnimationTimerId)
        self.CurAnimationTimerId = nil
    end
end