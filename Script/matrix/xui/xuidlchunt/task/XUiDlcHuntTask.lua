local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiDlcHuntTaskGrid = require("XUi/XUiDlcHunt/Task/XUiDlcHuntTaskGrid")

local TabType = {
    Daily = 1,
    Always = 2
}

---@class XUiDlcHuntTask:XLuaUi
local XUiDlcHuntTask = XLuaUiManager.Register(XLuaUi, "UiDlcHuntTask")

function XUiDlcHuntTask:OnAwake()
    self:BindExitBtns()
    self.TaskDic = {}
    self.SelectIndex = TabType.Daily
    self.TaskGroupIds = { XDlcHuntConfigs.GetWeekTaskGroupId(), XDlcHuntConfigs.GetTaskGroupId() }
    self:InitDynamicTable()
    self:InitButtonGroup()
    self.GridTask.gameObject:SetActiveEx(false)
    self.PanelSpecialTool.gameObject:SetActiveEx(false)
end

function XUiDlcHuntTask:OnEnable()
    XUiDlcHuntTask.Super.OnEnable(self)
    self:RefreshDynamicTable()
    self:RefreshRedPoint()
end

function XUiDlcHuntTask:OnGetEvents()
    return {
        XEventId.EVENT_FINISH_TASK,
        XEventId.EVENT_TASK_SYNC
    }
end

function XUiDlcHuntTask:OnNotify(event, ...)
    if event == XEventId.EVENT_FINISH_TASK or event == XEventId.EVENT_TASK_SYNC then
        self:RefreshRedPoint()
        self:RefreshDynamicTable()
    end
end

function XUiDlcHuntTask:InitButtonGroup()
    local tabList = {
        self.BtnDayTask,
        self.BtnRewardTask
    }
    self.Tags:Init(tabList, function(index)
        self:OnSelectTab(index)
        self:PlayAnimation("QieHuan")
    end)
    self.Tags:SelectIndex(self.SelectIndex)
end

function XUiDlcHuntTask:OnSelectTab(index)
    self.SelectIndex = index
    self:RefreshDynamicTable()
end

function XUiDlcHuntTask:RefreshDynamicTable()
    self.TaskDic[TabType.Daily] = XDataCenter.TaskManager.GetTaskByTypeAndGroup(XDataCenter.TaskManager.TaskType.DlcHunt, self.TaskGroupIds[1])
    self.TaskDic[TabType.Always] = XDataCenter.TaskManager.GetTaskByTypeAndGroup(XDataCenter.TaskManager.TaskType.DlcHunt, self.TaskGroupIds[2])

    local dataSource = self.TaskDic[self.SelectIndex]
    self.DynamicTable:SetDataSource(dataSource)
    self.DynamicTable:ReloadDataASync(1)
    self.PanelNoneStoryTask.gameObject:SetActiveEx(#dataSource == 0)
end

function XUiDlcHuntTask:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelTaskStoryList)
    self.DynamicTable:SetProxy(XUiDlcHuntTaskGrid, self)
    self.DynamicTable:SetDelegate(self)
end

function XUiDlcHuntTask:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:ResetData(self.TaskDic[self.SelectIndex][index])
    end
end

function XUiDlcHuntTask:RefreshRedPoint()
    local isShowDayRedDot = XDataCenter.TaskManager.CheckLimitTaskList(self.TaskGroupIds[1])
    local isShowChallengeRedDot = XDataCenter.TaskManager.CheckLimitTaskList(self.TaskGroupIds[2])
    self.BtnDayTask:ShowReddot(isShowDayRedDot)
    self.BtnRewardTask:ShowReddot(isShowChallengeRedDot)
end

return XUiDlcHuntTask