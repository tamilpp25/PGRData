local XDynamicGridTask = require("XUi/XUiTask/XDynamicGridTask")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
---@class XUiTaikoMasterTask:XLuaUi
---@field _Control XTaikoMasterControl
local XUiTaikoMasterTask = XLuaUiManager.Register(XLuaUi, "UiTaikoMasterTask")

function XUiTaikoMasterTask:OnStart()
    self._Control:UpdateUiTaskData()
    
    self._TaskDataSource = false
    self._DynamicTable = false
    
    self:InitDynamicTableTask()
    self:InitTask()
    self:InitPanelAsset()
    self:InitAutoClose()
    self:AddBtnListener()
end

function XUiTaikoMasterTask:OnEnable()
    XUiTaikoMasterTask.Super.OnEnable(self)
    XEventManager.AddEventListener(XEventId.EVENT_TASK_SYNC, self.OnTaskUpdate, self)
end

function XUiTaikoMasterTask:OnDisable()
    XUiTaikoMasterTask.Super.OnDisable(self)
    XEventManager.RemoveEventListener(XEventId.EVENT_TASK_SYNC, self.OnTaskUpdate, self)
end

--region Ui - AutoClose
function XUiTaikoMasterTask:InitAutoClose()
    local uiData = self._Control:GetUiData()
    self:SetAutoCloseInfo(XFunctionManager.GetEndTimeByTimeId(uiData and uiData.TimeId),
    function(isClose)
        if isClose then
            self._Control:HandleActivityEnd()
        end
    end)
end
--endregion

--region Ui - PanelAsset
function XUiTaikoMasterTask:InitPanelAsset()
    if self.PanelSpecialTool then
        self._PanelAsset = XUiHelper.NewPanelActivityAssetSafe(self._Control:GetPanelAssetItemList(), self.PanelSpecialTool, self)
    end
end
--endregion

--region Ui - Task
function XUiTaikoMasterTask:InitTask()
    self._CurrentTaskType = XEnumConst.TAIKO_MASTER.TASK_TYPE.NORMAL
    if not self.BtnGroup then
        self:SetTask()
        return
    end
    self._BtnToggleList = {
        self.BtnDayTask, self.BtnRewardTask
    }
    self.BtnGroup:Init(self._BtnToggleList, function(index)
        if self._CurrentTaskType ~= index then
            self._CurrentTaskType = index
            self:SetTask()
        end
    end)
    self.BtnGroup:SelectIndex(XEnumConst.TAIKO_MASTER.TASK_TYPE.NORMAL)
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
    self._Control:UpdateUiTaskData()
    local uiData = self._Control:GetUiData()
    if self._CurrentTaskType == XEnumConst.TAIKO_MASTER.TASK_TYPE.NORMAL then
        self._TaskDataSource = uiData.TaskList
    else
        self._TaskDataSource = uiData.DailyTaskList
    end
    if #self._TaskDataSource > 0 then
        self._DynamicTable:SetDataSource(self._TaskDataSource)
        self._DynamicTable:ReloadDataASync(1)
    else
        self.ImgEmpty.gameObject:SetActiveEx(true)
        self.SViewTask.gameObject:SetActiveEx(false)
    end
end

function XUiTaikoMasterTask:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:ResetData(self._TaskDataSource[index])
    end
end
--endregion

--region Ui - BtnListener
function XUiTaikoMasterTask:AddBtnListener()
    self:BindExitBtns(self.BtnBack, self.BtnMainUi)
    
end
--endregion

return XUiTaikoMasterTask
