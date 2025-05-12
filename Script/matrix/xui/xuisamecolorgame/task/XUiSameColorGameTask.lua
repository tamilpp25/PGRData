local XDynamicGridTask = require("XUi/XUiTask/XDynamicGridTask")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
---@class XUiSameColorGameTask:XLuaUi
---@field _Control XSameColorControl
local XUiSameColorGameTask = XLuaUiManager.Register(XLuaUi, "UiSameColorGameTask")

function XUiSameColorGameTask:OnAwake()
    self.SameColorGameManager = XDataCenter.SameColorActivityManager
    self:InitPanelAsset()
    self:AddBtnListener()
end

function XUiSameColorGameTask:OnStart()
    self:InitTaskList()
    self:InitAutoClose()
end

function XUiSameColorGameTask:OnEnable()
    XUiSameColorGameTask.Super.OnEnable(self)
    self:CheckBtnRed()
end

function XUiSameColorGameTask:OnGetEvents()
    return {
        XEventId.EVENT_FINISH_TASK,
    }
end

function XUiSameColorGameTask:OnNotify(event, ...)
    if event == XEventId.EVENT_FINISH_TASK then
        self:RefreshTaskList(self.CurrentTaskType)
        self:CheckBtnRed()
    end
end

function XUiSameColorGameTask:CheckBtnRed()
    XRedPointManager.CheckOnceByButton(self.BtnDayTask, { XRedPointConditions.Types.CONDITION_SAMECOLOR_TASK }, XEnumConst.SAME_COLOR_GAME.TASK_TYPE.DAY)
    XRedPointManager.CheckOnceByButton(self.BtnRewardTask, { XRedPointConditions.Types.CONDITION_SAMECOLOR_TASK }, XEnumConst.SAME_COLOR_GAME.TASK_TYPE.REWARD)
end

--region Ui - AutoClose
function XUiSameColorGameTask:InitAutoClose()
    --local endTime = self.SameColorGameManager.GetEndTime()
    --self:SetAutoCloseInfo(endTime, function(isClose)
    --    if isClose then
    --        self.SameColorGameManager.HandleActivityEndTime()
    --    end
    --end)
end
--endregion

--region Ui - PanelAsset
function XUiSameColorGameTask:InitPanelAsset()
    --local itemIds = self._Control:GetCfgAssetItemIds()
    --XUiHelper.NewPanelActivityAssetSafe(itemIds, self.PanelAsset, self, nil , function(uiSelf, index)
    --    local itemId = itemIds[index]
    --    XLuaUiManager.Open("UiSameColorGameSkillDetails", nil, itemId)
    --end)
end
--endregion

--region Ui - TaskList
function XUiSameColorGameTask:InitTaskList()
    self.DynamicTable = XDynamicTableNormal.New(self.TaskList)
    self.DynamicTable:SetProxy(XDynamicGridTask, self)
    self.DynamicTable:SetDelegate(self)
    self.GridTask.gameObject:SetActiveEx(false)
    self.CurrentTasks = nil
    -- XSameColorGameConfigs.TaskType
    self.CurrentTaskType = nil
    
    local btnTabList = { self.BtnDayTask, self.BtnRewardTask }
    self.BtnGroup:Init(btnTabList, function(index)
        if self.CurrentTaskType ~= index then
            self:RefreshTaskList(index)
        end
    end)
    self.BtnGroup:SelectIndex(XEnumConst.SAME_COLOR_GAME.TASK_TYPE.DAY)
end

-- taskType : XSameColorGameConfigs.TaskType
function XUiSameColorGameTask:RefreshTaskList(taskType)
    self.CurrentTaskType = taskType
    self.CurrentTasks = self._Control:GetTaskData(taskType)
    self.DynamicTable:SetDataSource(self.CurrentTasks)
    self.DynamicTable:ReloadDataSync(1)
    self.AnimRefresh:Play()
end

---@param grid XDynamicGridTask
function XUiSameColorGameTask:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid.OpenUiObtain = function(gridSelf, ...)
            local rewardGoodsList = ...
            XLuaUiManager.Open("UiSameColorGameRewardDetails", rewardGoodsList)
        end
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local taskData = self.CurrentTasks[index]
        grid:ResetData(taskData)

        -- 特殊处理背景图和名称
        if not grid.Bg then
            grid.Bg = XUiHelper.TryGetComponent(grid.Transform, "PanelAnimation/PanelBg")
        end
        if not grid.Bg2 then
            grid.Bg2 = XUiHelper.TryGetComponent(grid.Transform, "PanelAnimation/PanelBgPress")
        end
        if not grid.TxtTaskName2 then
            grid.TxtTaskName2 = XUiHelper.TryGetComponent(grid.Transform, "PanelAnimation/TxtTaskName2", "Text")
        end
        local config = XDataCenter.TaskManager.GetTaskTemplate(taskData.Id)
        grid.TxtTaskName2.text = config.Title

        local isFinish = taskData.State == XDataCenter.TaskManager.TaskState.Finish
        if grid.Bg then
            grid.Bg.gameObject:SetActiveEx(not isFinish)
        end
        if grid.Bg2 then
            grid.Bg2.gameObject:SetActiveEx(isFinish)
        end
        if grid.TxtTaskName then
            grid.TxtTaskName.gameObject:SetActiveEx(not isFinish)
        end
        if grid.TxtTaskName2 then
            grid.TxtTaskName2.gameObject:SetActiveEx(isFinish)
        end

        -- 特殊处理进度显示
        if grid.TxtTaskNumQian then
            local splite = string.Split(grid.TxtTaskNumQian.text, "/")
            local currentValue = tonumber(splite[1])
            local maxValue = tonumber(splite[2])
            if currentValue >= 1000000 then
                currentValue = math.floor(currentValue / 10000)  .. XUiHelper.GetText("TenThousand")
            end
            if maxValue >= 1000000 then
                maxValue = math.floor(maxValue / 10000)  .. XUiHelper.GetText("TenThousand")
            end
            grid.TxtTaskNumQian.text = currentValue .. "/" .. maxValue
        end
    end
end
--endregion

--region Ui - BtnListener
function XUiSameColorGameTask:AddBtnListener()
    self.BtnBack.CallBack = function() self:Close() end
    self.BtnMainUi.CallBack = function() XLuaUiManager.RunMain() end
end
--endregion

return XUiSameColorGameTask