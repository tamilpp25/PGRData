local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local BasePanel = require("XUi/XUiSuperTower/Common/XUiSTChildPanel")
--==================
--超级爬塔 爬塔 结算界面插件面板控件
--==================
local XUiStTsPluginInfoPanel = XClass(BasePanel, "XUiStTsPluginInfoPanel")
function XUiStTsPluginInfoPanel:InitPanel()
    self.GridPlugin.gameObject:SetActiveEx(false)
    self:InitPluginInfos()
    self:InitDynamicTable()
    self:ShowList()
end

function XUiStTsPluginInfoPanel:InitPluginInfos()
    self.PluginData = self.RootUi.Theme:GetTierPluginInfos()
    local pluginSlotScript = require("XEntity/XSuperTower/XSuperTowerPluginSlotManager")
    self.PluginSlot = pluginSlotScript.New()
    self.PluginSlot:SetMaxCapacity(100) --设定一个奖励上限
    for _, data in pairs(self.PluginData) do
        self.PluginSlot:AddPluginById(data.Id, data.Count)
    end
end

function XUiStTsPluginInfoPanel:InitDynamicTable()
    local GridProxy = require("XUi/XUiSuperTower/Plugins/XUiSuperTowerPluginGrid")
    self.DynamicTable = XDynamicTableNormal.New(self.PanelItemScrollView.gameObject)
    self.DynamicTable:SetProxy(GridProxy)
    self.DynamicTable:SetDelegate(self)
end

function XUiStTsPluginInfoPanel:ShowList()
    self.PluginList = self.PluginSlot:GetPluginsSplit()
    self.DynamicTable:SetDataSource(self.PluginList)
    self.DynamicTable:ReloadDataASync(1)
end

--=============
--动态列表事件
--=============
function XUiStTsPluginInfoPanel:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(grid.DynamicGrid.gameObject, function(pluginGrid) self:OnGridClick(pluginGrid) end)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        if self.PluginList and self.PluginList[index] then
            grid:RefreshData(self.PluginList[index])
        end
    end
end

function XUiStTsPluginInfoPanel:GetPluginGetNum()
    return self.PluginList and #self.PluginList or 0
end

function XUiStTsPluginInfoPanel:OnGridClick(grid)
    XLuaUiManager.Open("UiSuperTowerPluginDetails", grid.Plugin, 0)
end

return XUiStTsPluginInfoPanel