local XUiPanelPartnerLevel = XClass(nil, "XUiPanelPartnerLevel")
local XUiPanelLevelUp = require("XUi/XUiPartner/PartnerProperty/PanelPartnerLevel/XUiPanelLevelUp")
local XUiPanelLevelBreak = require("XUi/XUiPartner/PartnerProperty/PanelPartnerLevel/XUiPanelLevelBreak")
local XUiPanelLevelMax = require("XUi/XUiPartner/PartnerProperty/PanelPartnerLevel/XUiPanelLevelMax")

local panelState = {
    LevelUp = 1,
    LevelBreak = 2,
    LevelMax = 3,
    }

function XUiPanelPartnerLevel:Ctor(ui, base)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Base = base
    XTool.InitUiObject(self)
    self.LevelUpPanel = XUiPanelLevelUp.New(self.PanelLevelUp, self, self.Base)
    self.LevelBreakPanel = XUiPanelLevelBreak.New(self.PanelLevelBreak, self, self.Base)
    self.LevelMaxPanel = XUiPanelLevelMax.New(self.PanelLevelMax, self, self.Base)
end

function XUiPanelPartnerLevel:UpdatePanel(data)
    self.Data = data
    self:CheckPanelState()
    self:ShowPanel(data)
    self.GameObject:SetActiveEx(true)
    self.Base.BtnTabLevel:ShowTag(self.Data:GetIsMaxBreakthrough() and self.Data:GetIsLevelMax())
end

function XUiPanelPartnerLevel:HidePanel()
    self.GameObject:SetActiveEx(false)
end

function XUiPanelPartnerLevel:CheckPanelState()
    if not self.Data:GetIsLevelMax() then
        self.PanelState = panelState.LevelUp
    else
        if self.Data:GetIsMaxBreakthrough() then
            self.PanelState = panelState.LevelMax
        else
            self.PanelState = panelState.LevelBreak
        end
    end
end

function XUiPanelPartnerLevel:ShowPanel(data)
    self.LevelUpPanel:HidePanel()
    self.LevelBreakPanel:HidePanel()
    self.LevelMaxPanel:HidePanel()
    if self.PanelState == panelState.LevelUp then
        self.LevelUpPanel:UpdatePanel(data)
    elseif self.PanelState == panelState.LevelBreak then
        self.LevelBreakPanel:UpdatePanel(data)
    elseif self.PanelState == panelState.LevelMax then
        self.LevelMaxPanel:UpdatePanel(data)
    end
    self:PlayEnableAnime()
end

function XUiPanelPartnerLevel:PlayEnableAnime()
    XScheduleManager.ScheduleOnce(function()
            self.Animation:GetObject("AnimEnable"):PlayTimelineAnimation()
        end, 1)
end

return XUiPanelPartnerLevel
