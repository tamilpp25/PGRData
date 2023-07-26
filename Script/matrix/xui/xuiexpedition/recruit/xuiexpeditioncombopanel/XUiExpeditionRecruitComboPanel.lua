--虚像地平线招募界面：组合羁绊列表控件
local XUiExpeditionRecruitComboPanel = XClass(nil, "XUiExpeditionRecruitComboPanel")
local XUiExpeditionComboGrid = require("XUi/XUiExpedition/Recruit/XUiExpeditionComboPanel/XUiExpeditionComboGrid")
function XUiExpeditionRecruitComboPanel:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    self.GridSample = rootUi.GridCombo
    self.GridSample.gameObject:SetActiveEx(false)
    self.ImgEmpty = self.GameObject:FindGameObject("ImgEmpty")
    self.RootUi:RegisterClickEvent(self.GameObject, self.ClickEmpty, self)
    self:InitDynamicTable()
end

function XUiExpeditionRecruitComboPanel:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.GameObject)
    self.DynamicTable:SetProxy(XUiExpeditionComboGrid)
    self.DynamicTable:SetDelegate(self)
end

function XUiExpeditionRecruitComboPanel:ClickEmpty()
    XLuaUiManager.Open("UiExpeditionComboTips", nil)
end

--动态列表事件
function XUiExpeditionRecruitComboPanel:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(grid.DynamicGrid.gameObject, self.RootUi)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        if self.ComboList and self.ComboList[index] then
            grid:RefreshDatas(self.ComboList[index])
        end
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        if self.ComboList and self.ComboList[index] then
            XLuaUiManager.Open("UiExpeditionComboTips", self.ComboList[index])
        end
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        XEventManager.DispatchEvent(XEventId.EVENT_GUIDE_STEP_OPEN_EVENT)
    end
end

function XUiExpeditionRecruitComboPanel:UpdateData()
    self.ComboList = XDataCenter.ExpeditionManager.GetTeam():GetTeamComboList()
    self.DynamicTable:SetDataSource(self.ComboList)
    self.ImgEmpty:SetActiveEx(#self.ComboList == 0)
    self.DynamicTable:ReloadDataASync(1)
end

return XUiExpeditionRecruitComboPanel