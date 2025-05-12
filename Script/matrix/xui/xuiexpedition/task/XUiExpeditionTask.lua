local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiExpeditionTask = XLuaUiManager.Register(XLuaUi, "UiExpeditionTask")
local XUiGridExpeditionTask = require("XUi/XUiExpedition/Task/XUiGridExpeditionTask")

function XUiExpeditionTask:OnAwake()
    self:RegisterUiEvents()
    self.GridTask.gameObject:SetActiveEx(false)
end

function XUiExpeditionTask:OnStart()
    self:InitDynamicTable()
    local eActivity = XDataCenter.ExpeditionManager.GetEActivity()
    self.CurrentTaskGroupId = eActivity:GetTaskGroupId()
end

function XUiExpeditionTask:OnEnable()
    self:SetupDynamicTable()
end

function XUiExpeditionTask:OnGetEvents()
    return { XEventId.EVENT_FINISH_TASK }
end

function XUiExpeditionTask:OnNotify(event, ...)
    if event == XEventId.EVENT_FINISH_TASK then
        self:SetupDynamicTable()
    end
end

function XUiExpeditionTask:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelTaskList)
    self.DynamicTable:SetProxy(XUiGridExpeditionTask, self)
    self.DynamicTable:SetDelegate(self)
end

function XUiExpeditionTask:SetupDynamicTable()
    self.TaskDataList = XDataCenter.TaskManager.GetTimeLimitTaskListByGroupId(self.CurrentTaskGroupId)
    self.DynamicTable:SetDataSource(self.TaskDataList)
    self.DynamicTable:ReloadDataASync()
end

function XUiExpeditionTask:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid.RootUi = self
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.TaskDataList[index])
    end
end

function XUiExpeditionTask:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.OnBtnBackClick)
    XUiHelper.RegisterClickEvent(self, self.BtnBg, self.OnBtnBackClick)
end

function XUiExpeditionTask:OnBtnBackClick()
    self:Close()
end

return XUiExpeditionTask