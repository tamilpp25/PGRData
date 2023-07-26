
local XUiSSBMonsterWordsList = XClass(nil, "XUiSSBMonsterWordsList")

function XUiSSBMonsterWordsList:Ctor(rootUi, uiPrefab)
    XTool.InitUiObjectByUi(self, uiPrefab)
    self:InitDynamicTable()
    self.GridBuff.gameObject:SetActiveEx(false)
end

function XUiSSBMonsterWordsList:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.GameObject)
    local gridProxy = require("XUi/XUiSuperSmashBros/Monster/Grids/XUiSSBMonsterBuffGrid")
    self.DynamicTable:SetProxy(gridProxy)
    self.DynamicTable:SetDelegate(self)
end
--================
--动态列表事件
--================
function XUiSSBMonsterWordsList:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(grid.DynamicGrid.gameObject, self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.DataList[index])
    end
end

function XUiSSBMonsterWordsList:Refresh(monsterGroup)
    self.DataList = monsterGroup:GetBuffList()
    self.DynamicTable:SetDataSource(self.DataList)
    self.DynamicTable:ReloadDataASync(1)
end

return XUiSSBMonsterWordsList