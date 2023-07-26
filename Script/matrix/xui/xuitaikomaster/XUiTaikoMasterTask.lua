---@class XUiTaikoMasterTask:XLuaUi
local XUiTaikoMasterTask = XLuaUiManager.Register(XLuaUi, "UiTaikoMasterTask")

function XUiTaikoMasterTask:Ctor()
    self._TaskDataSource = false
    self._DynamicTable = false
end

function XUiTaikoMasterTask:OnStart()
    self:BindExitBtns(self.BtnBack, self.BtnMainUi)
    self:InitDynamicTableTask()
    if not self:SetTask() then
        self.ImgEmpty.gameObject:SetActiveEx(false)
        self.SViewTask.gameObject:SetActiveEx(false)
    end
    XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.Coin)
    self:SetAutoCloseInfo(
        XDataCenter.TaikoMasterManager.GetActivityEndTime(),
        function(isClose)
            if isClose then
                XDataCenter.TaikoMasterManager.HandleActivityEnd()
            end
        end
    )
end

function XUiTaikoMasterTask:OnEnable()
    XUiTaikoMasterTask.Super.OnEnable(self)
    XEventManager.AddEventListener(XEventId.EVENT_TASK_SYNC, self.OnTaskUpdate, self)
end

function XUiTaikoMasterTask:OnDisable()
    XUiTaikoMasterTask.Super.OnDisable(self)
    XEventManager.RemoveEventListener(XEventId.EVENT_TASK_SYNC, self.OnTaskUpdate, self)
end

function XUiTaikoMasterTask:OnTaskUpdate()
    self:SetTask()
end

function XUiTaikoMasterTask:InitDynamicTableTask()
    self.GridTask.gameObject:SetActiveEx(false)
    self._DynamicTable = XDynamicTableNormal.New(self.SViewTask)
    self._DynamicTable:SetProxy(XDynamicGridTask, self)
    self._DynamicTable:SetDelegate(self)
end

function XUiTaikoMasterTask:SetTask()
    local taskDataList = XDataCenter.TaikoMasterManager.GetTaskList()
    self._TaskDataSource = taskDataList
    self._DynamicTable:SetDataSource(taskDataList)
    self._DynamicTable:ReloadDataASync(1)
    return #taskDataList > 0
end

function XUiTaikoMasterTask:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:ResetData(self._TaskDataSource[index])
    end
end

return XUiTaikoMasterTask
