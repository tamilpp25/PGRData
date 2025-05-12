local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiReform2ndPanelTasks = XClass(nil, "XUiReform2ndPanelTasks")
local XUiReform2ndTaskGrid = require("XUi/XUiReform2nd/MainPage/XUiReform2ndTaskGrid")

function XUiReform2ndPanelTasks:Ctor(rootUi, uiPrefab, data)
    XTool.InitUiObjectByUi(self, uiPrefab)
    
    self.RootUi = rootUi
    self.TaskGridList = {}
    self.Data = data
    self.DynamicTable = XDynamicTableNormal.New(self.TaskPanelList)
    self.DynamicTable:SetProxy(XUiReform2ndTaskGrid)
    self.DynamicTable:SetDelegate(self)
    self.TaskPanelGrid.gameObject:SetActiveEx(false)
    
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.ClosePanel)
    XUiHelper.RegisterClickEvent(self, self.BtnCloseBg, self.ClosePanel)
end

function XUiReform2ndPanelTasks:ClosePanel()
    self.GameObject:SetActiveEx(false)
    self.RootUi:Refresh()
end

function XUiReform2ndPanelTasks:SetData(data)
    self.Data = data
end

function XUiReform2ndPanelTasks:Refresh()
    self.DynamicTable:SetDataSource(self.Data)
    self.DynamicTable:ReloadDataSync(1)
end

---@param grid XUiReform2ndTaskGrid
function XUiReform2ndPanelTasks:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:SetRootUi(self.RootUi)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.DynamicTable:GetData(index)
        
        grid:SetData(data)
        grid:Refresh()
    end
end

return XUiReform2ndPanelTasks
