local XDynamicGridTask = require("XUi/XUiTask/XDynamicGridTask")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
---@class XUiPcgTask : XLuaUi
---@field private _Control XPcgControl
local XUiPcgTask = XLuaUiManager.Register(XLuaUi, "UiPcgTask")

function XUiPcgTask:OnAwake()
    self:RegisterUiEvents()
    self:InitTabGroup()
    self:InitDynamicTable()
end

function XUiPcgTask:OnStart()
end

function XUiPcgTask:OnEnable()
    self:Refresh()
end

function XUiPcgTask:OnDisable()
    
end

function XUiPcgTask:OnNotify(evt, ...)
    if evt == XEventId.EVENT_FINISH_TASK or evt == XEventId.EVENT_TASK_SYNC then
        self:RefreshDynamicTable()
    end
end

function XUiPcgTask:OnGetEvents()
    return { XEventId.EVENT_FINISH_TASK, XEventId.EVENT_TASK_SYNC }
end

function XUiPcgTask:RegisterUiEvents()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
end

function XUiPcgTask:OnBtnBackClick()
    self:Close()
end

function XUiPcgTask:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiPcgTask:InitTabGroup()
    self.TaskGroupIds = self._Control:GetActivityTaskGroupIds()
    self.TaskGroupNames = self._Control:GetActivityTaskGroupNames()
    self.TabBtns = {}
    for i, name in ipairs(self.TaskGroupNames) do
        local tmpBtn = self["BtnTabTask" .. i]
        if tmpBtn then
            tmpBtn:SetName(name)
            table.insert(self.TabBtns, tmpBtn)
        end
    end
    self.BtnGroup:Init(self.TabBtns, function(index) self:OnBtnTabClick(index) end)
end

function XUiPcgTask:OnBtnTabClick(index)
    if self.SelIndex == index then
        return
    end
    self.SelIndex = index
    self:RefreshDynamicTable()
end

-- 刷新界面
function XUiPcgTask:Refresh()
    self.BtnGroup:SelectIndex(self.SelIndex or 1)
end

function XUiPcgTask:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.TaskList)
    self.DynamicTable:SetProxy(XDynamicGridTask, self)
    self.DynamicTable:SetDelegate(self)
    self.GridTask.gameObject:SetActiveEx(false)
end

function XUiPcgTask:RefreshDynamicTable()
    local taskGroupId = self.TaskGroupIds[self.SelIndex]
    self.TaskDataList = XDataCenter.TaskManager.GetTimeLimitTaskListByGroupId(taskGroupId)
    local allAchieveTasks = {}
    for _, v in pairs(self.TaskDataList) do
        if v.State == XDataCenter.TaskManager.TaskState.Achieved then
            table.insert(allAchieveTasks, v.Id)
        end
    end
    if not XTool.IsTableEmpty(allAchieveTasks) then
        table.insert(self.TaskDataList, 1, { ReceiveAll = true, AllAchieveTaskDatas = allAchieveTasks }) -- 领取全部
    end
    self.DynamicTable:SetDataSource(self.TaskDataList)
    self.DynamicTable:ReloadDataASync()
    self.ImgEmpty.gameObject:SetActiveEx(XTool.IsTableEmpty(self.TaskDataList))
    self:RefreshRedPoint()
end

---@param grid XDynamicGridTask
function XUiPcgTask:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX or event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        local taskData = self.TaskDataList[index]
        grid:ResetData(taskData)
        grid:SetTaskLock(false)
    end
end

function XUiPcgTask:RefreshRedPoint()
    for i, btn in ipairs(self.TabBtns) do
        local taskGroupId = self.TaskGroupIds[i]
        local isShowRed = XDataCenter.TaskManager.CheckLimitTaskList(taskGroupId)
        btn:ShowReddot(isShowRed)
    end
end

return XUiPcgTask
