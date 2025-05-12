local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")

local XUiPivotCombatPanelEnv = XClass(nil, "XUiPivotCombatPanelEnv")
local XUiPivotCombatEnvGrid = require("XUi/XUiPivotCombat/XUiGrid/XUiPivotCombatEnvGrid")

--===========================================================================
 ---@desc 详情界面-->关卡环境
 ---@param {ui} scroll rect
--===========================================================================
function XUiPivotCombatPanelEnv:Ctor(ui)
    XTool.InitUiObjectByUi(self, ui)
    self:InitDynamicTable()
    self.GridDesc.gameObject:SetActiveEx(false)
end 

function XUiPivotCombatPanelEnv:Refresh(data)
    self.EnvData = data
    
    self.DynamicTable:SetDataSource(self.EnvData)
    self.DynamicTable:ReloadDataSync(1)
end

function XUiPivotCombatPanelEnv:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelTargetList)
    self.DynamicTable:SetProxy(XUiPivotCombatEnvGrid)
    self.DynamicTable:SetDelegate(self)
end

function XUiPivotCombatPanelEnv:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.EnvData[index])
    end
end

return XUiPivotCombatPanelEnv