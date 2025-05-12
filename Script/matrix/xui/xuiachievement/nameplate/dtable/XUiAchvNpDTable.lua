local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
--=============
--铭牌页面动态列表
--=============
local XUiAchvNpDTable = XClass(nil, "XUiAchvNpDTable")

function XUiAchvNpDTable:Ctor(uiPrefab)
    XTool.InitUiObjectByUi(self, uiPrefab)
    self.GridNameplate.gameObject:SetActiveEx(false)
    self.EmptyText.text = CS.XTextManager.GetText("NotHaveNameplate")
    self:InitDynamicTable()
end

function XUiAchvNpDTable:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.GameObject)
    local XNameplate = require("XUi/XUiNameplate/XUiGridNameplate")
    self.DynamicTable:SetProxy(XNameplate)
    self.DynamicTable:SetDelegate(self)
end
--================
--动态列表事件
--================
function XUiAchvNpDTable:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:UpdateData(self.DataList[index], true, true)
    end
end
--================
--刷新动态列表
--================
function XUiAchvNpDTable:Refresh()
    self.DataList = XDataCenter.MedalManager.GetNameplateGroupList()
    self.DynamicTable:SetDataSource(self.DataList)
    self.DynamicTable:ReloadDataASync(1)
    self.PanelNone.gameObject:SetActiveEx(not next(self.DataList))
end

return XUiAchvNpDTable