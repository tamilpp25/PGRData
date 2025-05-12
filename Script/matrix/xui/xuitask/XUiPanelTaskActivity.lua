local XUiPanelTask = require("XUi/XUiMoneyReward/XUiPanelTask")
local XDynamicGridTask = require("XUi/XUiTask/XDynamicGridTask")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
---@class XUiPanelTaskActivity
local XUiPanelTaskActivity = XClass(nil, "XUiPanelTaskActivity")
local IsMulting = false
local ShowRewardList = {}

function XUiPanelTaskActivity:Ctor(ui, parent)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Parent = parent
    XTool.InitUiObject(self)

    self.DynamicTable = XDynamicTableNormal.New(self.PanelTaskActivityList)
    self.DynamicTable:SetProxy(XDynamicGridTask)
    self.DynamicTable:SetDelegate(self)
end

function XUiPanelTaskActivity:ShowPanel()
    self.GameObject:SetActive(true)

    self.ActivityTasks = self:GetTasks()
    self.PanelNoneActivityTask.gameObject:SetActive(#self.ActivityTasks <= 0)
    self.DynamicTable:SetDataSource(self.ActivityTasks)
    self.DynamicTable:ReloadDataASync(1)
end

function XUiPanelTaskActivity:HidePanel()
    self.GameObject:SetActive(false)
end

function XUiPanelTaskActivity:CheckRefreshLeftNewTask()
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

function XUiPanelTaskActivity:Refresh(isMulti)
    if isMulti and self:CheckRefreshLeftNewTask() then
        return
    end

    if IsMulting then  -- 一键领取未结束不刷新列表
        return
    end

    self.ActivityTasks = self:GetTasks()
    self.PanelNoneActivityTask.gameObject:SetActive(#self.ActivityTasks <= 0)
    self.DynamicTable:SetDataSource(self.ActivityTasks)
    self.DynamicTable:ReloadDataASync()
end

function XUiPanelTaskActivity:GetTasks()
    local allAchieveTasks = {}
    local tasks = XDataCenter.TaskManager.GetActivityTaskList()
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

--动态列表事件
function XUiPanelTaskActivity:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.ActivityTasks[index]
        grid.RootUi = self.Parent
        grid:ResetData(data)
    end
end

return XUiPanelTaskActivity