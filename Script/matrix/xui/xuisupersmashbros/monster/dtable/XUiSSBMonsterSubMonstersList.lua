
local XUiSSBMonsterSubMonstersList = XClass(nil, "XUiSSBMonsterSubMonstersList")

function XUiSSBMonsterSubMonstersList:Ctor(rootUi, uiPrefab)
    XTool.InitUiObjectByUi(self, uiPrefab)
    self:InitDynamicTable()
    self.GridSubMonster.gameObject:SetActiveEx(false)
end

function XUiSSBMonsterSubMonstersList:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.GameObject)
    local gridProxy = require("XUi/XUiSuperSmashBros/Monster/Grids/XUiSSBSubMonsterGrid")
    self.DynamicTable:SetProxy(gridProxy)
    self.DynamicTable:SetDelegate(self)
end

--================
--动态列表事件
--================
function XUiSSBMonsterSubMonstersList:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(grid.DynamicGrid.gameObject, self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.DataList[index])
    end
end

function XUiSSBMonsterSubMonstersList:Refresh(monsterGroup)
    self.DataList = monsterGroup:GetSubMonsterIds()
    self.DynamicTable:SetDataSource(self.DataList)
    self.DynamicTable:ReloadDataASync(1)
    self.PanelBlank.gameObject:SetActiveEx(not next(self.DataList))
end

return XUiSSBMonsterSubMonstersList