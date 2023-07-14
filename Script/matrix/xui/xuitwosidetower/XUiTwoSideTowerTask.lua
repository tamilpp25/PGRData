local XUiTwoSideTowerTask = XLuaUiManager.Register(XLuaUi, "UiTwoSideTowerTask")
local XUiGridExpeditionTask = require("XUi/XUiExpedition/Task/XUiGridExpeditionTask")

function XUiTwoSideTowerTask:OnAwake()
    self:RegisterUiEvents()
    self.GridTask.gameObject:SetActiveEx(false)
end

function XUiTwoSideTowerTask:OnStart()
    self:InitDynamicTable()
    self.CurrentTaskGroupId = XDataCenter.TwoSideTowerManager.GetLimitTaskId()
end

function XUiTwoSideTowerTask:OnEnable()
    self:SetupDynamicTable()
end

function XUiTwoSideTowerTask:OnGetEvents()
    return { XEventId.EVENT_FINISH_TASK }
end

function XUiTwoSideTowerTask:OnNotify(event, ...)
    if event == XEventId.EVENT_FINISH_TASK then
        self:SetupDynamicTable()
    end
end

function XUiTwoSideTowerTask:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelTaskList)
    self.DynamicTable:SetProxy(XUiGridExpeditionTask, self)
    self.DynamicTable:SetDelegate(self)
end

function XUiTwoSideTowerTask:SetupDynamicTable()
    self.TaskDataList = XDataCenter.TaskManager.GetTimeLimitTaskListByGroupId(self.CurrentTaskGroupId)
    self.DynamicTable:SetDataSource(self.TaskDataList)
    self.DynamicTable:ReloadDataASync()
end

function XUiTwoSideTowerTask:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid.RootUi = self
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.TaskDataList[index])
    end
end

function XUiTwoSideTowerTask:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.OnBtnBackClick)
    XUiHelper.RegisterClickEvent(self, self.BtnBg, self.OnBtnBackClick)
end

function XUiTwoSideTowerTask:OnBtnBackClick()
    self:Close()
end

return XUiTwoSideTowerTask