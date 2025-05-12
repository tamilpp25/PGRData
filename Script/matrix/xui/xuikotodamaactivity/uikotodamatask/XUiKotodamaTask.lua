local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiGridKotodamaTask = require('XUi/XUiKotodamaActivity/UiKotodamaTask/XUiGridKotodamaTask')

local XUiKotodamaTask = XLuaUiManager.Register(XLuaUi, 'UiKotodamaTask')

function XUiKotodamaTask:OnAwake()
    self.BtnBack.CallBack = function()
        self:Close()
    end
    self.BtnMainUi.CallBack = function()
        XLuaUiManager.RunMain()
    end

    self.DynamicTable = XDynamicTableNormal.New(self.SViewTask)
    self.DynamicTable:SetDelegate(self)
    self.DynamicTable:SetProxy(XUiGridKotodamaTask, self)
    self.GridTask.gameObject:SetActiveEx(false)

    --self.SpecialToolPanel=XUiPanelAsset.New(self,self.PanelSpecialTool,XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
end

function XUiKotodamaTask:OnEnable()
    self:RefreshTaskList()
end

function XUiKotodamaTask:RefreshTaskList()
    local data = XDataCenter.TaskManager.GetTaskList(TaskType.Kotodama, XMVCA.XKotodamaActivity:GetCurActivityTaskId())
    table.sort(data, function(a, b)
        --先按任务状态排序
        if a.State ~= b.State then
            --待领取的在前
            if a.State == XDataCenter.TaskManager.TaskState.Achieved then
                return true
            end
            if b.State == XDataCenter.TaskManager.TaskState.Achieved then
                return false
            end
            --非已领取的在前
            if a.State == XDataCenter.TaskManager.TaskState.Finish then
                return false
            end
            if b.State == XDataCenter.TaskManager.TaskState.Finish then
                return true
            end
        end

        --优先级大的在前
        if a.Priority ~= b.Priority then
            return a.Priority > b.Priority
        end
        --Id次序
        return a.Id < b.Id
    end)
    self.DynamicTable:SetDataSource(data)
    self.DynamicTable:ReloadDataASync()
end

function XUiKotodamaTask:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:SetRoot(self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:ResetData(XDataCenter.TaskManager.GetTaskDataById(self.DynamicTable.DataSource[index].Id))
    end
end

return XUiKotodamaTask