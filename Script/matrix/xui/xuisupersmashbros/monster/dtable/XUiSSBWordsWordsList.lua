local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
--================
--怪物词缀详细页面动态列表
--================
local XUiSSBWordsWordsList = XClass(nil, "XUiSSBWordsWordsList")

function XUiSSBWordsWordsList:Ctor(rootUi)
    self.RootUi = rootUi
    XTool.InitUiObjectByUi(self, rootUi.DTableWords)
    self:InitDynamicTable()
    self.GridWords.gameObject:SetActiveEx(false)
end

function XUiSSBWordsWordsList:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.GameObject)
    local gridProxy = require("XUi/XUiSuperSmashBros/Monster/Grids/XUiSSBWordsWordsListGrid")
    self.DynamicTable:SetProxy(gridProxy)
    self.DynamicTable:SetDelegate(self)
end
--================
--动态列表事件
--================
function XUiSSBWordsWordsList:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(grid.DynamicGrid.gameObject, self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.DataList[index])
    end
end
--================
--刷新动态列表
--================
function XUiSSBWordsWordsList:Refresh(dataList)
    self.DataList = dataList
    self.DynamicTable:SetDataSource(self.DataList)
    self.DynamicTable:ReloadDataASync(1)
end
return XUiSSBWordsWordsList