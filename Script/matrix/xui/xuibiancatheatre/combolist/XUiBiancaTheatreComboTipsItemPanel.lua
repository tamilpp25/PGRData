--肉鸽2.0羁绊展示页面：羁绊列表控件
local XUiBiancaTheatreComboTipsItemPanel = XClass(nil, "XUiBiancaTheatreComboTipsItemPanel")
local XUiBiancaTheatreComboTipsItem = require("XUi/XUiBiancaTheatre/ComboList/XUiBiancaTheatreComboTipsItem")
local XUiBiancaTheatreComboTipsHeadIcon = require("XUi/XUiBiancaTheatre/ComboList/XUiBiancaTheatreComboTipsHeadIcon")
function XUiBiancaTheatreComboTipsItemPanel:Ctor(ui, rootUi, isShowDisplay)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    self.IsShowDisplay = isShowDisplay  --是否展示羁绊图鉴列表（不判断是否有角色）
    XTool.InitUiObject(self)
    self.GridBuff.gameObject:SetActiveEx(false)
    --self:InitDynamicTable()
    self.RoleTemplate.gameObject:SetActiveEx(false)
    self.BuffGrids = {}
end

function XUiBiancaTheatreComboTipsItemPanel:UpdateData(eCombo)
    self.ECombo = eCombo
    local phaseComboList = eCombo:GetPhaseCombo()
    for _, grid in pairs(self.BuffGrids or {}) do
        grid.GameObject:SetActiveEx(false)
    end
    
    local totalStarCount = eCombo:GetTotalRank()
    for index in pairs(phaseComboList) do
        if not self.BuffGrids[index] then
            local newGo = CS.UnityEngine.Object.Instantiate(self.GridBuff.gameObject, self.BuffContent)
            self.BuffGrids[index] = XUiBiancaTheatreComboTipsItem.New(newGo, self.RootUi, self.IsShowDisplay)
        end
        self.BuffGrids[index]:RefreshDatas(self.ECombo, index, totalStarCount)
        self.BuffGrids[index].GameObject:SetActiveEx(true)
    end
    self:UpdateEComboStatus()
end

function XUiBiancaTheatreComboTipsItemPanel:UpdateEComboStatus()
    self:ResetReference()
    if not self.ECombo then return end
    self.TxtName.text = self.ECombo:GetName()
    self.RImgIcon:SetRawImage(self.ECombo:GetIconPath())
    local active = self.ECombo:GetComboActive()
    self.On.gameObject:SetActiveEx(active and not self.IsShowDisplay)
    self.Off.gameObject:SetActiveEx(not active and not self.IsShowDisplay)
    if active then
        self.TextLevelNumber.text = CS.XTextManager.GetText("ExpeditionComboTipsPhaseTitle", self.ECombo:GetPhaseLevel())
    end
    local referenceList = self.ECombo:GetDisplayReferenceList(self.IsShowDisplay)
    local sampleRank = self.ECombo:GetConditionLevel(self.ECombo:GetPhase())
    if not self.RoleList then self.RoleList = {} end
    local count = #referenceList
    for i = 1, count do
        if not self.RoleList[i] then
            local prefab = XUiHelper.Instantiate(self.RoleTemplate, self.RolePanel)
            self.RoleList[i] = XUiBiancaTheatreComboTipsHeadIcon.New(prefab, self.IsShowDisplay)
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

function XUiBiancaTheatreComboTipsItemPanel:ResetReference()
    if not self.RoleList then return end
    for i = 1, #self.RoleList do
        if self.RoleList[i] then
            self.RoleList[i]:Hide()
        end
    end
end

return XUiBiancaTheatreComboTipsItemPanel