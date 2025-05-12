local XDynamicGridTask = require("XUi/XUiTask/XDynamicGridTask")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
---@class XUiLineArithmeticTask : XLuaUi
---@field _Control XLineArithmeticControl
local XUiLineArithmeticTask = XLuaUiManager.Register(XLuaUi, "UiLineArithmeticTask")

function XUiLineArithmeticTask:OnAwake()
    self.GridTask.gameObject:SetActiveEx(false)
    self:AddBtnListener()
end

function XUiLineArithmeticTask:OnStart()
    self.DynamicTable = XDynamicTableNormal.New(self.SViewTask)
    self.DynamicTable:SetProxy(XDynamicGridTask, self)
    self.DynamicTable:SetDelegate(self)

    XEventManager.AddEventListener(XEventId.EVENT_FINISH_TASK, self.OnTaskChangeSync, self)
    XEventManager.AddEventListener(XEventId.EVENT_TASK_SYNC, self.OnTaskChangeSync, self)
    XEventManager.AddEventListener(XEventId.EVENT_FINISH_MULTI, self.OnTaskChangeSync, self)
    XEventManager.AddEventListener(XEventId.EVENT_TASK_FINISH_FAIL, self.OnTaskChangeSync, self)
end

function XUiLineArithmeticTask:OnEnable()
    self:OnTaskChangeSync()
end

function XUiLineArithmeticTask:OnDisable()

end

function XUiLineArithmeticTask:OnDestroy()
    XEventManager.RemoveEventListener(XEventId.EVENT_FINISH_TASK, self.OnTaskChangeSync, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_TASK_SYNC, self.OnTaskChangeSync, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FINISH_MULTI, self.OnTaskChangeSync, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_TASK_FINISH_FAIL, self.OnTaskChangeSync, self)
end

--region Ui - BtnListener
function XUiLineArithmeticTask:AddBtnListener()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.OnBtnBackClick)
    XUiHelper.RegisterClickEvent(self, self.BtnMainUi, self.OnBtnMainUiClick)
end

function XUiLineArithmeticTask:OnBtnBackClick()
    self:Close()
end

function XUiLineArithmeticTask:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end
--endregion

function XUiLineArithmeticTask:OnTaskChangeSync()
    local taskDatas = XDataCenter.TaskManager.GetLineArithmeticTaskList()
    if not XTool.IsTableEmpty(taskDatas) then
        self.DynamicTable:SetDataSource(taskDatas)
        self.DynamicTable:ReloadDataSync(1)
    end
end

function XUiLineArithmeticTask:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:ResetData(self.DynamicTable.DataSource[index])
    end
end

return XUiLineArithmeticTask