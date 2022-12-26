local ChildPanel = require("XUi/XUiSuperTower/Common/XUiSTChildPanel")
local LIST_TYPE = {
    Bag = 1, --背包列表
    Decomposion = 2, --分解列表
}
--local DETAIL_OFFSET = 300 --详细窗口离屏幕边缘的像素距离
--===========================
--超级爬塔芯片列表面板
--===========================
local XUiSTBagPluginsPanel = XClass(ChildPanel, "XUiSTBagPluginsPanel")

function XUiSTBagPluginsPanel:InitPanel()
    self:InitDynamicTable()
    self.ListType = LIST_TYPE.Bag
end

function XUiSTBagPluginsPanel:InitDynamicTable()
    local GridProxy = require("XUi/XUiSuperTower/Bag/XUiSTBagPluginsGrid")
    self.DynamicTable = XDynamicTableNormal.New(self.GameObject)
    self.DynamicTable:SetProxy(GridProxy)
    self.DynamicTable:SetDelegate(self)
end
--=============
--动态列表事件
--=============
function XUiSTBagPluginsPanel:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(grid.DynamicGrid.gameObject, function(pluginGrid) self:OnGridClick(pluginGrid) end)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        if self.PluginsList and self.PluginsList[index] then
            grid:RefreshData(self.PluginsList[index], index, self.ListType)
            if self.ListType == LIST_TYPE.Decomposion then
                if self.SelectIndex[index] then
                    grid:SetSelect(true)
                else
                    grid:SetSelect(false)
                end
            end
        end
    end
end

function XUiSTBagPluginsPanel:RefreshBag()
    self.ListType = LIST_TYPE.Bag
    self.PluginsList = self.RootUi.BagManager:GetPluginsByPrior()
    self.ObjEmpty.gameObject:SetActiveEx(not next(self.PluginsList))
    self.DynamicTable:SetDataSource(self.PluginsList)
    self.DynamicTable:ReloadDataASync(1)
end

function XUiSTBagPluginsPanel:RefreshDecomposion()
    self.ListType = LIST_TYPE.Decomposion
    self.SelectIndex = {}
    self.PluginsList = self.RootUi.BagManager:GetPluginsByPrior()
    self.DynamicTable:SetDataSource(self.PluginsList)
    self.DynamicTable:ReloadDataASync(1)
end

function XUiSTBagPluginsPanel:ResetDecomposion()
    self.SelectIndex = {}
    for index, plugin in ipairs(self.PluginsList or {}) do
        if self.SelectIndex[index] then
            local grid = self.DynamicTable:GetGridByIndex(index)
            if grid then
                self:OnDecomposionGridClick(grid, true)
            end
        end
    end
end

function XUiSTBagPluginsPanel:SelectStar(star)
    if self.ListType ~= LIST_TYPE.Decomposion then return end
    for index, plugin in ipairs(self.PluginsList or {}) do
        if plugin:GetStar() == star then
            if not self.SelectIndex[index] then
                local grid = self.DynamicTable:GetGridByIndex(index)
                if grid then
                    self:OnDecomposionGridClick(grid, true)
                end
            end
        end
    end
    self.RootUi:OnDecomposeListRefresh(self:GetSelectPlugins())
end

function XUiSTBagPluginsPanel:UnSelectStar(star)
    if self.ListType ~= LIST_TYPE.Decomposion then return end
    for index, plugin in ipairs(self.PluginsList or {}) do
        if plugin:GetStar() == star then
            if self.SelectIndex[index] then
                local grid = self.DynamicTable:GetGridByIndex(index)
                if grid then
                    self:OnDecomposionGridClick(grid, true)
                end
            end
        end
    end
    self.RootUi:OnDecomposeListRefresh(self:GetSelectPlugins())
end

function XUiSTBagPluginsPanel:OnGridClick(grid)
    if self.ListType == LIST_TYPE.Bag then
        self:OnBagGridClick(grid)
    elseif self.ListType == LIST_TYPE.Decomposion then
        self:OnDecomposionGridClick(grid)
    end
end

function XUiSTBagPluginsPanel:OnBagGridClick(grid)
    grid:SetSelect(true)
    --local offset = CS.UnityEngine.Screen.width / 2 - DETAIL_OFFSET
    XLuaUiManager.Open("UiSuperTowerPluginDetails", grid.Plugin, 0, function() if not XTool.UObjIsNil(self.Transform) then grid:SetSelect(false) end end)
end

function XUiSTBagPluginsPanel:OnDecomposionGridClick(grid, noEvent)
    if self.SelectIndex[grid.Index] then
        grid:SetSelect(false)
        self.SelectIndex[grid.Index] = nil
    else
        grid:SetSelect(true)
        self.SelectIndex[grid.Index] = true
    end
    if not noEvent then
        self.RootUi:OnDecomposeListRefresh(self:GetSelectPlugins())
    end
end

function XUiSTBagPluginsPanel:GetSelectPlugins()
    local selectPlugins = {}
    for index, plugin in pairs(self.PluginsList or {}) do
        if self.SelectIndex[index] then
            table.insert(selectPlugins, plugin)
        end
    end
    return selectPlugins
end

function XUiSTBagPluginsPanel:OnPluginRefresh()
    if self.ListType == LIST_TYPE.Bag then
        self:RefreshBag()
    elseif self.ListType == LIST_TYPE.Decomposion then
        self:RefreshDecomposion()
    end
end

function XUiSTBagPluginsPanel:AddEventListener()
    XEventManager.AddEventListener(XEventId.EVENT_ST_PLUGIN_REFRESH, self.OnPluginRefresh, self)
end

function XUiSTBagPluginsPanel:RemoveEventListener()
    XEventManager.RemoveEventListener(XEventId.EVENT_ST_PLUGIN_REFRESH, self.OnPluginRefresh, self)
end


return XUiSTBagPluginsPanel