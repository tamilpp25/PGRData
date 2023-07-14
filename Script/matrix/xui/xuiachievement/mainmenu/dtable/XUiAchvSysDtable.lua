--=============
--成就主界面动态列表
--=============
local XUiAchvSysDtable = XClass(nil, "XUiAchvSysDtable")

function XUiAchvSysDtable:Ctor(uiPrefab)
    XTool.InitUiObjectByUi(self, uiPrefab)
    self.GridAchievementTypeBanner.gameObject:SetActiveEx(false)
    self:InitDynamicTable()
end

function XUiAchvSysDtable:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelAchieveTypeList.gameObject)
    local XMenuGrid = require("XUi/XUiAchievement/MainMenu/PanelMenu/XUiAchvSysGridMenu")
    self.DynamicTable:SetProxy(XMenuGrid)
    self.DynamicTable:SetDelegate(self)
end
--================
--动态列表事件
--================
function XUiAchvSysDtable:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:RefreshData(self.DataList[index])
    end
end
--================
--刷新动态列表
--================
function XUiAchvSysDtable:Refresh()
    self.DataList = XAchievementConfigs.GetAllConfigs(
        XAchievementConfigs.TableKey.AchievementBaseType
    )
    self.DynamicTable:SetDataSource(self.DataList)
    self.DynamicTable:ReloadDataASync(1)
end

return XUiAchvSysDtable