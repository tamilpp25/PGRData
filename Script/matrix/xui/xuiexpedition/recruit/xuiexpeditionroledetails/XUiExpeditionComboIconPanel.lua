--虚像地平线招募界面角色详细子页面:羁绊展示动态列表
local XUiExpeditionComboIconPanel = XClass(nil, "XUiExpeditionComboIconPanel")
local XUiExpeditionComboIconGrid = require("XUi/XUiExpedition/Recruit/XUiExpeditionRoleDetails/XUiExpeditionComboIconGrid")

function XUiExpeditionComboIconPanel:Ctor(ui, rootUi, detailsType)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    self.DetailsType = detailsType
    self:InitDynamicTable()
end

function XUiExpeditionComboIconPanel:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.GameObject)
    self.DynamicTable:SetProxy(XUiExpeditionComboIconGrid)
    self.DynamicTable:SetDelegate(self)
end

--动态列表事件
function XUiExpeditionComboIconPanel:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(grid.DynamicGrid.gameObject)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        if self.ComboList and self.ComboList[index] then
            grid:RefreshData(self.ComboList[index], self.DetailsType)
        end
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        if self.ComboList and self.ComboList[index] then
            XLuaUiManager.Open("UiExpeditionComboTips", XDataCenter.ExpeditionManager.GetComboByChildComboId(self.ComboList[index]))
        end
    end
end

function XUiExpeditionComboIconPanel:UpdateData(eChara)
    if self.DetailsType == XExpeditionConfig.MemberDetailsType.FireMember then
        self.ComboList = XDataCenter.ExpeditionManager.GetComboList():GetActiveComboIdsByEChara(eChara, true)
    elseif self.DetailsType == XExpeditionConfig.MemberDetailsType.RecruitMember then
        self.ComboList = XDataCenter.ExpeditionManager.GetComboList():GetPreviewCombosWhenRecruit(eChara, true)
    end
    self.DynamicTable:SetDataSource(self.ComboList)
    self.DynamicTable:ReloadDataASync(1)
end
return XUiExpeditionComboIconPanel