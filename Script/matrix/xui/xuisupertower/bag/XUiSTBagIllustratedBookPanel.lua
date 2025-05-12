local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local ChildPanel = require("XUi/XUiSuperTower/Common/XUiSTChildPanel")
--===========================
--超级爬塔芯片列表面板
--===========================
local XUiSTBagIllustratedBookPanel = XClass(ChildPanel, "XUiSTBagIllustratedBookPanel")

function XUiSTBagIllustratedBookPanel:InitPanel()
    self:InitDynamicTable()
    self:InitFilter()
end

function XUiSTBagIllustratedBookPanel:InitDynamicTable()
    local GridProxy = require("XUi/XUiSuperTower/Bag/XUiSTBagIllusBookGrid")
    self.DynamicTable = XDynamicTableNormal.New(self.GameObject)
    self.DynamicTable:SetProxy(GridProxy)
    self.DynamicTable:SetDelegate(self)
end

--=============
--动态列表事件
--=============
function XUiSTBagIllustratedBookPanel:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(grid.DynamicGrid.gameObject, function() self:OnGridClick(grid) end)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        if self.PluginsList and self.PluginsList[index] then
            grid:RefreshData(self.PluginsList[index], index, self.ListType)
        end
    end
end

function XUiSTBagIllustratedBookPanel:Refresh()
    --local currentList, otherList = self.RootUi.BagManager:GetIllusPluginList()
    --self:CreatePluginsList(currentList, otherList)
    local currentList = self.RootUi.BagManager:GetIllusPluginList(self.SelectFilterIndex)
    self:CreatePluginsList(currentList)
    self.DynamicTable:SetDataSource(self.PluginsList)
    self.DynamicTable:ReloadDataASync(1)
end

--[[function XUiSTBagIllustratedBookPanel:CreatePluginsList(currentList, otherList)
    self.PluginsList = {}
    for _, plugin in pairs(currentList) do
        local data = {Plugin = plugin, IsLock = true}
        table.insert(self.PluginsList, data)
    end
    for _, plugin in pairs(otherList) do
        local data = {Plugin = plugin, IsLock = true}
        table.insert(self.PluginsList, data)
    end
end]]  --注释掉需要区分历史有无获得过的条件

function XUiSTBagIllustratedBookPanel:CreatePluginsList(list)
    self.PluginsList = {}
    for _, plugin in pairs(list) do
        local data = {Plugin = plugin, IsLock = false}
        table.insert(self.PluginsList, data)
    end
end

function XUiSTBagIllustratedBookPanel:InitFilter()
    self.Filters = {}
    self.FilterButtons = {}
    self.SelectFilterIndex = {}
    local togButtonScript = require("XUi/XUiSuperTower/Bag/XUiSTBagIllusFilterButton")
    XTool.InitUiObjectByUi(self.Filters, self.PanelFilter)
    for i = 1, 6 do
        local togButton = self.Filters["TogStar" .. i]
        if togButton then
            self.FilterButtons[i] = togButtonScript.New(togButton, self, i)
        end
    end
end

function XUiSTBagIllustratedBookPanel:OnGridClick(grid)
    grid:SetActiveStatus(true)
    XLuaUiManager.Open("UiSuperTowerPluginDetails", grid.Plugin, 0, function() if not XTool.UObjIsNil(self.Transform) then grid:SetActiveStatus(false) end end)
end

function XUiSTBagIllustratedBookPanel:OnTogSelect(togIndex)
    if self.SelectFilterIndex[togIndex] then return end
    --3星的情况是3星以下所有
    if togIndex == 3 then
        self.SelectFilterIndex[1] = true
        self.SelectFilterIndex[2] = true
    end
    self.SelectFilterIndex[togIndex] = true
    self:Refresh()
end

function XUiSTBagIllustratedBookPanel:OnTogUnSelect(togIndex)
    if not self.SelectFilterIndex[togIndex] then return end
    --3星的情况是3星以下所有
    if togIndex == 3 then
        self.SelectFilterIndex[1] = nil
        self.SelectFilterIndex[2] = nil
    end
    self.SelectFilterIndex[togIndex] = nil
    self:Refresh()
end
return XUiSTBagIllustratedBookPanel