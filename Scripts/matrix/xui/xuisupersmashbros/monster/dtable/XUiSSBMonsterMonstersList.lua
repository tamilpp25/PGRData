--================
--怪物页面怪物组列表
--================
local XUiSSBMonsterMonstersList = XClass(nil, "XUiSSBMonsterMonstersList")

function XUiSSBMonsterMonstersList:Ctor(rootUi)
    self.RootUi = rootUi
    XTool.InitUiObjectByUi(self, rootUi.SViewMonsterList)
    self.GridMonster.gameObject:SetActiveEx(false)
    self:InitDynamicTable()
end
--================
--初始化动态列表
--================
function XUiSSBMonsterMonstersList:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.GameObject)
    local gridProxy = require("XUi/XUiSuperSmashBros/Monster/Grids/XUiSSBMonsterListGrid")
    self.DynamicTable:SetProxy(gridProxy)
    self.DynamicTable:SetDelegate(self)
end
--================
--动态列表事件
--================
function XUiSSBMonsterMonstersList:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(grid.DynamicGrid.gameObject, self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        if self.DataList and self.DataList[index] then
            grid:Refresh(self.DataList[index], index)
            if self.CurrentIndex == index then
                self:OnGridSelect(grid, index)
            end
        end
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self:OnGridSelect(grid, index)
    end
end
--================
--刷新动态列表
--================
function XUiSSBMonsterMonstersList:Refresh(dataList, index)
    self.DataList = dataList
    self.CurrentIndex = index or 1
    self.DynamicTable:SetDataSource(self.DataList)
    self.DynamicTable:ReloadDataASync(1)
end
--================
--选中项
--================
function XUiSSBMonsterMonstersList:OnGridSelect(grid, index)
    if self.CurrentGrid and self.CurrentGrid == grid then return end
    if self.CurrentGrid then self.CurrentGrid:SetSelect(false) end
    self.CurrentIndex = index
    self.CurrentGrid = grid
    self.CurrentGrid:SetSelect(true)
    self.RootUi:SelectMonster(self.DataList[index])
end

return XUiSSBMonsterMonstersList