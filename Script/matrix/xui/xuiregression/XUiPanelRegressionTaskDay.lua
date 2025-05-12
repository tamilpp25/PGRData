local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XDynamicDailyTask = require("XUi/XUiTask/XDynamicDailyTask")
--
--Author: wujie
--Note: 回归活动每日任务动态表

local XUiPanelRegressionTaskDay = XClass(XUiNode, "XUiPanelRegressionTaskDay")

function XUiPanelRegressionTaskDay:OnStart()
    self:InitDynamicTable()
end

function XUiPanelRegressionTaskDay:InitRootUi(rootUi)
    self.RootUi = rootUi
end

function XUiPanelRegressionTaskDay:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.GameObject)
    self.DynamicTable:SetProxy(XDynamicDailyTask,self)
    self.DynamicTable:SetDelegate(self)
end

function XUiPanelRegressionTaskDay:UpdateDynamicTable(taskList)
    self.DynamicTableDataList = taskList
    self.DynamicTable:SetDataSource(self.DynamicTableDataList)
    self.DynamicTable:ReloadDataASync(#self.DynamicTableDataList > 0 and 1 or -1)
end


--事件相关------------------------------------>>>
function XUiPanelRegressionTaskDay:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid.RootUi = self.RootUi
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.DynamicTableDataList[index]
        grid:ResetData(data)
    end
end

--事件相关------------------------------------<<<

return XUiPanelRegressionTaskDay