
local XUiPivotCombatPanelEfficiency = XClass(nil, "XUiPivotCombatPanelEfficiency")
local XUiPivotCombatEfficiencyGrid = require("XUi/XUiPivotCombat/XUiGrid/XUiPivotCombatEfficiencyGrid")

--===========================================================================
---@desc 详情界面-->供能描述
---@param {ui} scroll rect
--===========================================================================
function XUiPivotCombatPanelEfficiency:Ctor(ui)
    XTool.InitUiObjectByUi(self, ui)
    self:InitDynamicTable()
    self.GridEfficiency.gameObject:SetActiveEx(false)
end

function XUiPivotCombatPanelEfficiency:Refresh(data)
    self.EfficiencyData = data

    self.DynamicTable:SetDataSource(self.EfficiencyData)
    self.DynamicTable:ReloadDataSync(1)
end

function XUiPivotCombatPanelEfficiency:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelTargetList)
    self.DynamicTable:SetProxy(XUiPivotCombatEfficiencyGrid)
    self.DynamicTable:SetDelegate(self)
end

function XUiPivotCombatPanelEfficiency:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.EfficiencyData[index])
    end
end

return XUiPivotCombatPanelEfficiency