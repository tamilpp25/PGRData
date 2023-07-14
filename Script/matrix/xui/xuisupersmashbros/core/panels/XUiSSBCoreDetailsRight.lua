--=============
--
--=============
local XUiSSBCoreDetailsRight = XClass(nil, "XUiSSBCoreDetailsRight")

local TAB_INDEX = {
    Evolution = 1,
    GrowthRate = 2,
}

function XUiSSBCoreDetailsRight:Ctor(uiPrefab)
    XTool.InitUiObjectByUi(self, uiPrefab)
    self:InitPanels()
end

function XUiSSBCoreDetailsRight:InitPanels()
    self:InitTabs()
    self:InitPanelEvolution()
    -- self:InitPanelGrowthRate() -- cxldV2 二期关闭增幅系统
end

function XUiSSBCoreDetailsRight:InitTabs()
    local tabs = {}
    -- XTool.InitUiObjectByUi(tabs, self.PanelTabGroup) -- cxldV2 二期关闭增幅系统
    -- self.PanelTabGroup:Init({tabs.BtnEvolution, tabs.BtnGrowthRate}, function(index) self:SelectIndex(index) end)
end

function XUiSSBCoreDetailsRight:SelectIndex(index)
    self.PanelEvolution.gameObject:SetActiveEx(index == TAB_INDEX.Evolution)
    self.PanelGrowthRate.gameObject:SetActiveEx(index == TAB_INDEX.GrowthRate)
end

function XUiSSBCoreDetailsRight:InitPanelEvolution()
    local script = require("XUi/XUiSuperSmashBros/Core/Panels/XUiSSBCoreEvoPanel")
    self.EvoPanel = script.New(self.PanelEvolution, self.Core)
end

function XUiSSBCoreDetailsRight:InitPanelGrowthRate()
    local script = require("XUi/XUiSuperSmashBros/Core/Panels/XUiSSBCoreGrowthPanel")
    self.GrowthPanel = script.New(self.PanelGrowthRate, self.Core)
end

function XUiSSBCoreDetailsRight:Refresh(core)
    self.Core = core
    -- self.PanelTabGroup:SelectIndex(TAB_INDEX.Evolution)
    self.EvoPanel:Refresh(core)
    -- self.GrowthPanel:Refresh(core) -- cxldV2 二期关闭增幅系统
end

function XUiSSBCoreDetailsRight:OnlyRefreshPanel(core, isCoreLevelUp)
    self.EvoPanel:Refresh(core, isCoreLevelUp)
    -- self.GrowthPanel:Refresh() -- cxldV2 二期关闭增幅系统
end

function XUiSSBCoreDetailsRight:RefreshEvolution()
    self.EvoPanel:RefreshStar(self.Core:GetStar())
    self.EvoPanel:RefreshText(self.Core:GetStar())
    self.EvoPanel:RefreshCost()
    self.EvoPanel.BtnEvoConfirm:SetButtonState(self.Core:CheckSkillIsMax() and CS.UiButtonState.Disable or CS.UiButtonState.Normal)
end

return XUiSSBCoreDetailsRight