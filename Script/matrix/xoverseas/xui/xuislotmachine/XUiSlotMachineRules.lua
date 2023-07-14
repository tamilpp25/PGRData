local XUiSlotMachineRulesPanel = require("XOverseas/XUi/XUiSlotMachine/XUiSlotMachineRulesPanel")
local XUiSlotMachineRulesResearchPanel = require("XOverseas/XUi/XUiSlotMachine/XUiSlotMachineRulesResearchPanel")

local XUiSlotMachineRules = XLuaUiManager.Register(XLuaUi, "UiSlotmachineRules")

function XUiSlotMachineRules:OnAwake()
    self.RulesPanel = XUiSlotMachineRulesPanel.New(self, self.PanelRules)
    self.ResearchPanel = XUiSlotMachineRulesResearchPanel.New(self, self.PanelResearch)
end

function XUiSlotMachineRules:OnStart(father)
    self.Father = father
    self:AutoAddListener()
    self:InitTabGroup()
end

function XUiSlotMachineRules:OnEnable()
    self.CurMachineEntity = self.Father.CurMachineEntity
    self:Refresh(self.CurMachineEntity:GetId())
end

function XUiSlotMachineRules:AutoAddListener()
    self.BtnClose.CallBack = function() self:Close() end
    self.BtnTanchuangClose.CallBack = function() self:Close() end
end

function XUiSlotMachineRules:Refresh(machineId)
    self.CurMachineEntity = XDataCenter.SlotMachineManager.GetSlotMachineDataEntityById(machineId)
    self.TabGroup:SelectIndex(self.LastSelectIndex or 1)
end

function XUiSlotMachineRules:InitTabGroup()
    self.TabList = {}
    table.insert(self.TabList, self.BtnTab1)
    table.insert(self.TabList, self.BtnTab2)
    self.TabGroup:Init(self.TabList, function(index) self:OnTaskPanelSelect(index) end)
end

function XUiSlotMachineRules:OnTaskPanelSelect(index)
    self.LastSelectIndex = index
    if index == XSlotMachineConfigs.RulesPanelType.Rules then
        self.PanelRules.gameObject:SetActiveEx(true)
        self.PanelResearch.gameObject:SetActiveEx(false)
        self.RulesPanel:Refresh(self.CurMachineEntity:GetId())
    elseif index == XSlotMachineConfigs.RulesPanelType.Research then
        self.PanelRules.gameObject:SetActiveEx(false)
        self.PanelResearch.gameObject:SetActiveEx(true)
        self.ResearchPanel:Refresh(self.CurMachineEntity:GetId())
    end
end