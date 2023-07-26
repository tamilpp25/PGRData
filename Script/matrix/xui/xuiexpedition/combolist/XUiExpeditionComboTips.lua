--虚像地平线羁绊组合详细页面
local XUiExpeditionComboTips = XLuaUiManager.Register(XLuaUi, "UiExpeditionComboTips")
local XUiExpeditionComboTipsTab = require("XUi/XUiExpedition/ComboList/XUiExpeditionComboTipsTab")
local XUiExpeditionComboTipsItemPanel = require("XUi/XUiExpedition/ComboList/XUiExpeditionComboTipsItemPanel")
local TabType = {
    First = "BtnFirstHasSnd",
    SecondTop = "BtnSecondTop",
    SecondBottom = "BtnSecondBottom",
    Second = "BtnSecond",
    SecondAll = "BtnSecondAll"
}
local UiButtonState = CS.UiButtonState
function XUiExpeditionComboTips:OnAwake()
    XTool.InitUiObject(self)
    self:RegisterBtnEvent()
    self:SetBtnTemplateDisable()
end

function XUiExpeditionComboTips:OnStart(eCombo, team)
    self:InitComboTab(team)
    self.ItemPanel = XUiExpeditionComboTipsItemPanel.New(self.PanelPart, self)
    self.BtnContent:SelectIndex(eCombo and self.ChildTabList[eCombo:GetComboId()] or 1)
end

function XUiExpeditionComboTips:SetBtnTemplateDisable()
    self.BtnFirst.gameObject:SetActiveEx(false)
    self.BtnFirstHasSnd.gameObject:SetActiveEx(false)
    self.BtnSecondTop.gameObject:SetActiveEx(false)
    self.BtnSecond.gameObject:SetActiveEx(false)
    self.BtnSecondBottom.gameObject:SetActiveEx(false)
    self.BtnSecondAll.gameObject:SetActiveEx(false)
end

function XUiExpeditionComboTips:RegisterBtnEvent()
    self:RegisterClickEvent(self.BtnTanchuangCloseBig, function() self:Close() end)
end

function XUiExpeditionComboTips:InitComboTab(team)
    if not team then team = XDataCenter.ExpeditionManager.GetTeam() end
    self.ComboList = team:GetAllCombos()
    self.ComboTabDataList = self:InitComboTabDataList()
    self:CreateComboTab()
end

function XUiExpeditionComboTips:InitComboTabDataList()
    local comboList = {} -- {[BaseComboId] = {[1] = ComboListIndex…}}
    local baseComboTypeCfgs = XExpeditionConfig.GetBaseComboTypeConfig()
    for _, baseComboType in pairs(baseComboTypeCfgs) do
        local baseId = baseComboType.Id
        local orderId = baseComboType.OrderId
        for _, eCombo in pairs(self.ComboList) do
            if eCombo:GetComboTypeId() == baseId then
                if not comboList[orderId] then comboList[orderId] = {} end
                table.insert(comboList[orderId], eCombo)
            end
        end
    end
    local dataList = {}
    local tabCount = 1
    for orderId, childComboList in pairs(comboList) do
        local comboTypeCfg = XExpeditionConfig.GetBaseComboTypeCfgByOrderId(orderId)
        local tabData = {
            TabType = TabType.First,
            Name = comboTypeCfg.Name,
            TabId = tabCount,
            BaseComboId = comboTypeCfg.Id
        }
        table.insert(dataList, tabData)
        local fatherTabId = tabCount
        tabCount = tabCount + 1
        local childNum = #childComboList
        local childCount = 0
        local activeChildCount = 0
        for _, childCombo in pairs(childComboList) do
            childCount = childCount + 1
            local childTabData = {
                Name = childCombo:GetName(),
                TabId = tabCount,
                FatherTabId = fatherTabId,
                ComboId = childCombo:GetComboId(),
                Combo = childCombo,
                IsActive = childCombo:GetComboActive()
            }
            if childNum == 1 then
                childTabData.TabType = TabType.SecondAll
            elseif childNum > 1 and childCount == 1 then
                childTabData.TabType = TabType.SecondTop
            elseif childNum > 1 and childCount < childNum then
                childTabData.TabType = TabType.Second
            elseif childNum > 1 and childCount == childNum then
                childTabData.TabType = TabType.SecondBottom
            end
            table.insert(dataList, childTabData)
            tabCount = tabCount + 1
            if childCombo:GetComboActive() then activeChildCount = activeChildCount + 1 end
        end
        tabData.ChildCount = childCount
        tabData.ActiveChildCount = activeChildCount
    end
    return dataList
end

function XUiExpeditionComboTips:CreateComboTab()
    self.TabList = {}
    self.FirstTabList = {}
    self.ChildTabList = {}
    self.BtnList = {}
    for i = 1, #self.ComboTabDataList do
        local data = self.ComboTabDataList[i]
        local btnPrefab = CS.UnityEngine.Object.Instantiate(self[data.TabType].gameObject)
        btnPrefab.transform:SetParent(self.BtnContent.transform, false)
        self.TabList[i] = XUiExpeditionComboTipsTab.New(btnPrefab, self, i, data,
            function(index, tabType, isSelect) self:OnTabClick(index, tabType, isSelect) end)
        btnPrefab.gameObject:SetActiveEx(data.TabType == TabType.First)
        self.BtnList[i] = btnPrefab:GetComponent("XUiButton")
        if data.TabType == TabType.First then
            self.FirstTabList[data.BaseComboId] = i
        end
        if data.TabType ~= TabType.First then
            self.BtnList[i].SubGroupIndex = data.FatherTabId
            self.ChildTabList[data.ComboId] = i
        end
        self.BtnList[i]:SetButtonState(UiButtonState.Normal)
    end
    self.BtnContent:Init(self.BtnList, function(index) self.TabList[index]:OnClick() end)
end

function XUiExpeditionComboTips:RefreshComboList(childComboData)
    self.ItemPanel:UpdateData(childComboData)
end