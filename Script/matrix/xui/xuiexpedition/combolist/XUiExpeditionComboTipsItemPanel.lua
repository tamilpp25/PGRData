local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
--虚像地平线羁绊展示页面：羁绊列表控件
local XUiExpeditionComboTipsItemPanel = XClass(nil, "XUiExpeditionComboTipsItemPanel")
local XUiExpeditionComboTipsItem = require("XUi/XUiExpedition/ComboList/XUiExpeditionComboTipsItem")
local XUiExpeditionComboTipsHeadIcon = require("XUi/XUiExpedition/ComboList/XUiEXpeditionComboTipsHeadIcon")
function XUiExpeditionComboTipsItemPanel:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)
    self.GridBuff.gameObject:SetActiveEx(false)
    --self:InitDynamicTable()
    self.RoleTemplate.gameObject:SetActiveEx(false)
    self.BuffGrids = {}
end
--[[
function XUiExpeditionComboTipsItemPanel:InitDynamicTable()
self.DynamicTable = XDynamicTableNormal.New(self.PanelBufftList.gameObject)
self.DynamicTable:SetProxy(XUiExpeditionComboTipsItem)
self.DynamicTable:SetDelegate(self)
end

--动态列表事件
function XUiExpeditionComboTipsItemPanel:OnDynamicTableEvent(event, index, grid)
if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
grid:Init(grid.DynamicGrid.gameObject, self.RootUi)
elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
if self.ComboList and self.ComboList[index] then
grid:RefreshDatas(self.ComboList[index], self.ECombo, index)
end
end
end
]]
function XUiExpeditionComboTipsItemPanel:UpdateData(eCombo)
    self.ECombo = eCombo
    self.ComboList = eCombo:GetPhaseCombo()
    for _, grid in pairs(self.BuffGrids or {}) do
        grid.GameObject:SetActiveEx(false)
    end
    for index, combo in pairs(self.ComboList) do
        if not self.BuffGrids[index] then
            local newGo = CS.UnityEngine.Object.Instantiate(self.GridBuff.gameObject, self.BuffContent)
            self.BuffGrids[index] = XUiExpeditionComboTipsItem.New(newGo, self.RootUi)
        end
        self.BuffGrids[index]:RefreshDatas(combo, self.ECombo, index)
        self.BuffGrids[index].GameObject:SetActiveEx(true)
    end
    self:UpdateEComboStatus()
end

function XUiExpeditionComboTipsItemPanel:UpdateEComboStatus()
    self:ResetReference()
    if not self.ECombo then return end
    self.TxtName.text = self.ECombo:GetName()
    self.RImgIcon:SetRawImage(self.ECombo:GetIconPath())
    local active = self.ECombo:GetComboActive()
    self.On.gameObject:SetActiveEx(active)
    self.Off.gameObject:SetActiveEx(not active)
    if active then
        self.TextLevelNumber.text = CS.XTextManager.GetText("ExpeditionComboTipsPhaseTitle", self.ECombo:GetPhase())
    end
    local referenceList = self.ECombo:GetDisplayReferenceList()
    local sampleRank = self.ECombo:GetConditionLevel(self.ECombo:GetPhase())
    if not self.RoleList then self.RoleList = {} end
    local count = #referenceList
    for i = 1, count do
        if not self.RoleList[i] then
            local prefab = CS.UnityEngine.Object.Instantiate(self.RoleTemplate.gameObject)
            prefab.transform:SetParent(self.RolePanel.transform, false)
            self.RoleList[i] = XUiExpeditionComboTipsHeadIcon.New(prefab)
        end
        self.RoleList[i]:Show()
        self.RoleList[i]:RefreshData(referenceList[i], sampleRank)
    end
    for i = count + 1, #self.RoleList do
        if self.RoleList[i] then
            self.RoleList[i]:Hide()
        end
    end
end

function XUiExpeditionComboTipsItemPanel:ResetReference()
    if not self.RoleList then return end
    for i = 1, #self.RoleList do
        if self.RoleList[i] then
            self.RoleList[i]:Hide()
        end
    end
end

return XUiExpeditionComboTipsItemPanel