local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XDynamicGridTask = require("XUi/XUiTask/XDynamicGridTask")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
---@class XUiScoreTowerTask : XLuaUi
---@field private _Control XScoreTowerControl
---@field BtnGroup XUiButtonGroup
local XUiScoreTowerTask = XLuaUiManager.Register(XLuaUi, "UiScoreTowerTask")

function XUiScoreTowerTask:OnAwake()
    self:RegisterUiEvents()
    self.GridTask.gameObject:SetActiveEx(false)
end

function XUiScoreTowerTask:OnStart()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.ScoreTowerCoin)
    self:SetAutoCloseInfo(XMVCA.XScoreTower:GetActivityEndTime(), function(isClose)
        if isClose then
            XMVCA.XScoreTower:HandleActivityEnd()
        end
    end)

    self.TaskGroupIds = {}
    self.CurTabSelectIndex = -1
    self.CurSelectTaskGroupId = 0
    self:InitTagGroup()
    self:InitDynamicTable()
    -- 动画间隔
    self.AnimInterval = self._Control:GetClientConfig("GridTaskAnimInterval", 1, true)
end

function XUiScoreTowerTask:OnEnable()
    self.Super.OnEnable(self)
    local index = self.CurTabSelectIndex > 0 and self.CurTabSelectIndex or 1
    self.BtnGroup:SelectIndex(index)
    self:RefreshRedPoint()
end

function XUiScoreTowerTask:OnGetLuaEvents()
    return {
        XEventId.EVENT_FINISH_TASK,
        XEventId.EVENT_FINISH_MULTI,
    }
end

function XUiScoreTowerTask:OnNotify(event, ...)
    if event == XEventId.EVENT_FINISH_TASK or event == XEventId.EVENT_FINISH_MULTI then
        self:SetupDynamicTable()
        self:RefreshRedPoint()
    end
end

function XUiScoreTowerTask:OnDisable()
    self.Super.OnDisable(self)
    self:StopDynamicGridTime()
    self:SetGridTaskAlpha(1)
end

function XUiScoreTowerTask:InitTagGroup()
    self.TaskGroupIds = self._Control:GetAllTaskGroupIdList()
    if XTool.IsTableEmpty(self.TaskGroupIds) then
        self.BtnGroup.gameObject:SetActiveEx(false)
        return
    end
    local btnGroup = {}
    for index, groupId in ipairs(self.TaskGroupIds) do
        ---@type XUiComponent.XUiButton
        local btn = self[string.format("BtnTabTask%d", index)]
        if btn then
            btn.gameObject:SetActiveEx(true)
            btn:SetNameByGroup(0, self._Control:GetTaskGroupName(groupId))
            btnGroup[index] = btn
        end
    end
    self.BtnGroup:Init(btnGroup, function(index) self:OnSwitchTaskTab(index) end)
end

function XUiScoreTowerTask:OnSwitchTaskTab(index)
    if self.CurTabSelectIndex == index then
        return
    end
    self.CurTabSelectIndex = index
    self.CurSelectTaskGroupId = self.TaskGroupIds[index]
    self:SetupDynamicTable(true)
end

function XUiScoreTowerTask:InitDynamicTable()
    ---@type XDynamicTableNormal
    self.DynamicTable = XDynamicTableNormal.New(self.TaskList)
    self.DynamicTable:SetProxy(XDynamicGridTask, self)
    self.DynamicTable:SetDelegate(self)
end

---@param isAnim boolean 是否播放动画
function XUiScoreTowerTask:SetupDynamicTable(isAnim)
    if not XTool.IsNumberValid(self.CurSelectTaskGroupId) then
        return
    end
    self.TaskDataList = self._Control:GetTaskDataListByGroupId(self.CurSelectTaskGroupId)
    local isEmpty = XTool.IsTableEmpty(self.TaskDataList)
    self.ImgEmpty.gameObject:SetActiveEx(isEmpty)
    if isEmpty then
        return
    end
    local allAchieveTaskIds = {}
    for _, data in pairs(self.TaskDataList) do
        if data.State == XDataCenter.TaskManager.TaskState.Achieved then
            table.insert(allAchieveTaskIds, data.Id)
        end
    end
    if not XTool.IsTableEmpty(allAchieveTaskIds) then
        table.insert(self.TaskDataList, 1, { ReceiveAll = true, AllAchieveTaskDatas = allAchieveTaskIds }) -- 领取全部
    end
    self.IsAnim = isAnim or false
    self.DynamicTable:SetDataSource(self.TaskDataList)
    self.DynamicTable:ReloadDataSync(1)
end

---@param grid XDynamicGridTask
function XUiScoreTowerTask:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:ResetData(self.TaskDataList[index])
        grid:SetTaskLock(false)
        if grid.BgGroup then
            local isReceiveAll = grid.Data and grid.Data.ReceiveAll or false
            grid.BgGroup.gameObject:SetActiveEx(not isReceiveAll)
        end
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        if self.IsAnim then
            self:PlayGridTaskAnim()
        end
    end
end

-- 刷新按钮红点
function XUiScoreTowerTask:RefreshRedPoint()
    if XTool.IsTableEmpty(self.TaskGroupIds) then
        return
    end
    for index, groupId in pairs(self.TaskGroupIds) do
        ---@type XUiComponent.XUiButton
        local btn = self[string.format("BtnTabTask%d", index)]
        if btn then
            local isShowRedPoint = self._Control:CheckHasCanReceiveTaskReward(groupId)
            btn:ShowReddot(isShowRedPoint)
        end
    end
end

-- 播放任务动画
function XUiScoreTowerTask:PlayGridTaskAnim()
    if not self.DynamicTable then
        return
    end
    ---@type XDynamicGridTask[]
    local grids = self.DynamicTable:GetGrids()
    if XTool.IsTableEmpty(grids) then
        return
    end
    self:StopDynamicGridTime()
    self:SetGridTaskAlpha(0)
    local animIndex = 1
    local gridCount = table.nums(grids)
    XLuaUiManager.SetMask(true)
    self._DynamicGridTimeId = XScheduleManager.Schedule(function()
        local grid = grids[animIndex]
        if grid then
            if grid.GridTaskTimeline then
                grid.GridTaskTimeline:PlayTimelineAnimation()
            end
        end
        animIndex = animIndex + 1
    end, self.AnimInterval, gridCount)
    -- 动画结束 动画间隔 * 格子数量 + 500ms(最后一个格子动画播放时间)
    XScheduleManager.ScheduleOnce(function()
        self:StopDynamicGridTime()
        self:SetGridTaskAlpha(1)
        XLuaUiManager.SetMask(false)
    end, self.AnimInterval * gridCount + 500)
end

-- 停止任务动画
function XUiScoreTowerTask:StopDynamicGridTime()
    if self._DynamicGridTimeId then
        XScheduleManager.UnSchedule(self._DynamicGridTimeId)
        self._DynamicGridTimeId = nil
    end
end

-- 设置任务格子透明度
function XUiScoreTowerTask:SetGridTaskAlpha(alpha)
    if not self.DynamicTable then
        return
    end
    ---@type XDynamicGridTask[]
    local grids = self.DynamicTable:GetGrids()
    if XTool.IsTableEmpty(grids) then
        return
    end
    for _, grid in pairs(grids) do
        if grid.GridTask then
            grid.GridTask.alpha = alpha
        end
    end
end

function XUiScoreTowerTask:RegisterUiEvents()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
end

function XUiScoreTowerTask:OnBtnBackClick()
    self:Close()
end

function XUiScoreTowerTask:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

return XUiScoreTowerTask
