-- 虚像地平线无尽关羁绊动态列表控件
local XUiExpeditionInfinityComboList = XClass(nil, "XUiExpeditionInfinityComboList")
local XUiExpeditionComboGrid = require("XUi/XUiExpedition/Recruit/XUiExpeditionComboPanel/XUiExpeditionComboGrid")
function XUiExpeditionInfinityComboList:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self:InitDynamicTable()
end

function XUiExpeditionInfinityComboList:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.GameObject)
    self.DynamicTable:SetProxy(XUiExpeditionComboGrid)
    self.DynamicTable:SetDelegate(self)
end

--动态列表事件
function XUiExpeditionInfinityComboList:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(grid.DynamicGrid.gameObject)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        if self.ComboList and self.ComboList[index] then
            grid:RefreshDatas(self.ComboList[index])
        end
    end
end

function XUiExpeditionInfinityComboList:RefreshData()
    self.ComboList = XDataCenter.ExpeditionManager.GetTeam():GetActiveTeamComboList()
    self.DynamicTable:SetDataSource(self.ComboList)
    self.DynamicTable:ReloadDataASync(1)
end
return XUiExpeditionInfinityComboList