local XSlotMachineTaskGrid = require("XUi/XUiSlotMachine/XUiSlotMachineTaskGrid")
---@class XUiSlotMachineTaskContentPanel
local XUiSlotMachineTaskContentPanel = XClass(nil, "XUiSlotMachineTaskContentPanel")

function XUiSlotMachineTaskContentPanel:Ctor(rootUi, ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RectTransform = ui
    self.RootUi = rootUi
    XTool.InitUiObject(self)
    self:Init()
end

function XUiSlotMachineTaskContentPanel:Init()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelTaskList.gameObject)
    self.DynamicTable:SetProxy(XSlotMachineTaskGrid, self.RootUi)
    self.DynamicTable:SetDelegate(self)
end

---@param grid XSlotMachineTaskGrid
function XUiSlotMachineTaskContentPanel:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:UpdateGrid(self.DataList[index])
    end
end

function XUiSlotMachineTaskContentPanel:Refresh(taskTimeLimitId)
    if XTool.IsNumberValid(taskTimeLimitId) then
        self.DataList = XDataCenter.TaskManager.GetTimeLimitTaskListByGroupId(taskTimeLimitId)
        self.DynamicTable:SetDataSource(self.DataList)
        self.DynamicTable:ReloadDataASync()
    end
end

return XUiSlotMachineTaskContentPanel