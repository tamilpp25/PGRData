--
--Author: wujie
--Note:回归活动每周任务动态表

local XUiPanelRegressionTaskWeek = XClass(nil, "XUiPanelRegressionTaskWeek")

function XUiPanelRegressionTaskWeek:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self:InitDynamicTable()
end

function XUiPanelRegressionTaskWeek:InitRootUi(rootUi)
    self.RootUi = rootUi
end

function XUiPanelRegressionTaskWeek:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.GameObject)
    self.DynamicTable:SetProxy(XDynamicDailyTask)
    self.DynamicTable:SetDelegate(self)
end

function XUiPanelRegressionTaskWeek:UpdateDynamicTable(taskList)
    self.DynamicTableDataList = taskList
    self.DynamicTable:SetDataSource(self.DynamicTableDataList)
    self.DynamicTable:ReloadDataASync(#self.DynamicTableDataList > 0 and 1 or -1)
end

--事件相关------------------------------------>>>
function XUiPanelRegressionTaskWeek:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid.RootUi = self.RootUi
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.DynamicTableDataList[index]
        grid:ResetData(data)
    end
end

--事件相关------------------------------------<<<

return XUiPanelRegressionTaskWeek