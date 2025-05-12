local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local Base = require("XUi/XUiSuperTower/Common/XUiSTChildPanel")
--=====================
--爬塔掉落页面动态列表面板
--=====================
local XUiStTdDynamicTablePanel = XClass(Base, "XUiStTdDynamicTablePanel")
local SHOW_TYPE = {
    Enhance = 1, --增益页面
    Plugin = 2, --插件掉落页面
}
function XUiStTdDynamicTablePanel:InitPanel()
    self:InitDynamicTable()
end

function XUiStTdDynamicTablePanel:InitDynamicTable()
    local GridProxy = require("XUi/XUiSuperTower/Plugins/XUiSuperTowerMixGrid")
    self.DynamicTable = XDynamicTableNormal.New(self.GameObject)
    self.DynamicTable:SetProxy(GridProxy)
    self.DynamicTable:SetDelegate(self)
end

--=============
--动态列表事件
--=============
function XUiStTdDynamicTablePanel:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(grid.DynamicGrid.gameObject, function(mixGrid) self:OnGridClick(mixGrid) end)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        self:SetFirstGridActive() --每次重新加载列表时默认选择第一个显示
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        if self.DataList and self.DataList[index] then
            grid:RefreshCfg(self:GetDataCfg(self.DataList[index]))
            grid:SetIndex(index)
            if self.RootUi.ShowType == SHOW_TYPE.Enhance then
                grid:SetFloorLock(not self.DataList[index].IsExist)
                grid:SetLockText(CS.XTextManager.GetText("STTdEnhanceLock"))
            elseif self.RootUi.ShowType == SHOW_TYPE.Plugin then
                grid:SetFloorLock(not self.DataList[index].IsExist)
                grid:SetLockText(CS.XTextManager.GetText("STTdPluginLock", self.DataList[index].Level))
            end
            if self.SelectIndex == index then
                grid:SetActiveStatus(true)
            else
                grid:SetActiveStatus(false)
            end
        end
    end
end

function XUiStTdDynamicTablePanel:GetDataCfg(data)
    if self.RootUi.ShowType == SHOW_TYPE.Enhance then
        return XSuperTowerConfigs.GetEnhanceCfgById(data.EnhanceId)
    elseif self.RootUi.ShowType == SHOW_TYPE.Plugin then
        return XSuperTowerConfigs.GetPluginCfgById(data.PluginId)
    end
end

function XUiStTdDynamicTablePanel:Refresh()
    self.SelectIndex = nil
    self.SelectGrid = nil
    self:SetList()
end

function XUiStTdDynamicTablePanel:SetList()
    if self.RootUi.ShowType == SHOW_TYPE.Enhance then
        self.DataList = self.RootUi.Theme:GetTierEnhanceDropShowList(self.RootUi.ShowAll)
    elseif self.RootUi.ShowType == SHOW_TYPE.Plugin then
        self.DataList = self.RootUi.Theme:GetTierPluginDropShowList(true)
    end
    self.DynamicTable:SetDataSource(self.DataList)
    self.DynamicTable:ReloadDataASync(1)
end

function XUiStTdDynamicTablePanel:OnGridClick(grid)
    if self.SelectIndex ~= grid.Index then
        if self.SelectGrid then self.SelectGrid:SetActiveStatus(false) end
        self.SelectGrid = grid
        self.SelectIndex = grid.Index
        self.SelectGrid:SetActiveStatus(true)
    end
    self.RootUi:OnSelectGrid(grid.ItemCfg)
end
--=================
--每次刷新页签默认选取第一个插件显示
--=================
function XUiStTdDynamicTablePanel:SetFirstGridActive()
    local grid = self.DynamicTable:GetGridByIndex(1)
    if grid then
        self:OnGridClick(grid)
    end
end
return XUiStTdDynamicTablePanel