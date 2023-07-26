local XUiSlotMachineRulesPanel = require("XUi/XUiSlotMachine/XUiSlotMachineRulesPanel")
local XUiSlotMachineRulesResearchPanel = require("XUi/XUiSlotMachine/XUiSlotMachineRulesResearchPanel")

---@class XUiSlotMachineRules : XLuaUi
---@field RulesPanel XUiSlotMachineRulesPanel
---@field ResearchPanel XUiSlotMachineRulesResearchPanel
local XUiSlotMachineRules = XLuaUiManager.Register(XLuaUi, "UiSlotmachineRules")

function XUiSlotMachineRules:OnAwake()
    self:AutoAddListener()
    self.RulesPanel = XUiSlotMachineRulesPanel.New(self, self.PanelRules)
    self.ResearchPanel = XUiSlotMachineRulesResearchPanel.New(self, self.PanelResearch)
end

function XUiSlotMachineRules:OnStart()
    self:InitTabGroup()
end

function XUiSlotMachineRules:AutoAddListener()
    self.BtnClose.CallBack = function()
        self:Close()
    end
    self.BtnTanchuangClose.CallBack = function()
        self:Close()
    end
end

function XUiSlotMachineRules:Refresh(machineId)
    self.CurMachineEntity = XDataCenter.SlotMachineManager.GetSlotMachineDataEntityById(machineId)
    self.TabGroup:SelectIndex(self.LastSelectIndex or 1)
end

function XUiSlotMachineRules:InitTabGroup()
    self.TabList = {
        self.BtnTab1,
        self.BtnTab2,
    }
    self.TabGroup:Init(self.TabList, function(index)
        self:OnTaskPanelSelect(index)
    end)
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
    self:PlayAnimation("QieHuan")
end

return XUiSlotMachineRules