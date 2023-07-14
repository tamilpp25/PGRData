--虚像地平线成员列表页面：羁绊列表
local XUiExpeditionRoleListComboList = XClass(nil, "XUiExpeditionRoleListComboList")
local XUiExpeditionComboGrid = require("XUi/XUiExpedition/Recruit/XUiExpeditionComboPanel/XUiExpeditionComboGrid")

function XUiExpeditionRoleListComboList:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    self.GridSample = rootUi.GridCombo
    self.GridSample.gameObject:SetActiveEx(false)
    self.ImgEmpty = self.GameObject:FindGameObject("ImgEmpty")
    self.RootUi:RegisterClickEvent(self.GameObject, self.ClickEmpty, self)
    self:InitDynamicTable()
end

function XUiExpeditionRoleListComboList:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.GameObject)
    self.DynamicTable:SetProxy(XUiExpeditionComboGrid)
    self.DynamicTable:SetDelegate(self)
end

function XUiExpeditionRoleListComboList:ClickEmpty()
    XLuaUiManager.Open("UiExpeditionComboTips", nil)
end

--动态列表事件
function XUiExpeditionRoleListComboList:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(grid.DynamicGrid.gameObject, self.RootUi)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        if self.ComboList and self.ComboList[index] then
            grid:RefreshDatas(self.ComboList[index])
        end
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        if self.ComboList and self.ComboList[index] then
            XLuaUiManager.Open("UiExpeditionComboTips", self.ComboList[index], self.RootUi.PreviewTeam)
        end
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        XEventManager.DispatchEvent(XEventId.EVENT_GUIDE_STEP_OPEN_EVENT)
    end
end

function XUiExpeditionRoleListComboList:UpdateData()
    if self.RootUi.IsPreviewDefault then
        self.ComboList = self.RootUi.PreviewTeam:GetTeamComboList()
    else
        self.ComboList = XDataCenter.ExpeditionManager.GetTeam():GetTeamComboList()
    end
    self.DynamicTable:SetDataSource(self.ComboList)
    self.ImgEmpty:SetActiveEx(#self.ComboList == 0)
    if #self.ComboList > 0 then
        self.DynamicTable:ReloadDataASync(1)
    end
end

function XUiExpeditionRoleListComboList:OnEnable()
    XEventManager.AddEventListener(XEventId.EVENT_EXPEDITION_ACTIVECOMBOLIST_CHANGE, self.UpdateData, self)
end

function XUiExpeditionRoleListComboList:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_EXPEDITION_ACTIVECOMBOLIST_CHANGE, self.UpdateData, self)
end
return XUiExpeditionRoleListComboList