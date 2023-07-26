--================
--勋章页面动态列表
--================
local XUiAchvMedalDTable = XClass(nil, "XUiAchvMedalDTable")

function XUiAchvMedalDTable:Ctor(uiPrefab)
    XTool.InitUiObjectByUi(self, uiPrefab)
    self.GridMedal.gameObject:SetActiveEx(false)
    self:InitDynamicTable()
end

function XUiAchvMedalDTable:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.DTableMedal.gameObject)
    --local gridProxy = require("XUi/XUiSuperSmashBros/Character/Grids/XUiSSBCharacterGrid")
    self.DynamicTable:SetProxy(XUiGridMedal)
    self.DynamicTable:SetDelegate(self)
end
--================
--动态列表事件
--================
function XUiAchvMedalDTable:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:UpdateGrid(self.DataList[index])
    end
end
--================
--刷新动态列表
--================
function XUiAchvMedalDTable:Refresh()
    self.DataList = XDataCenter.MedalManager.GetMedals()
    self.DynamicTable:SetDataSource(self.DataList)
    self.DynamicTable:ReloadDataASync(1)
    self.PanelNone.gameObject:SetActiveEx(not next(self.DataList))
    self.EmptyText.text = CS.XTextManager.GetText("NotHaveMedal")
end

return XUiAchvMedalDTable