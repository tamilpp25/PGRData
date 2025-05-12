local XUiPanelPartnerQuality = XClass(nil, "XUiPanelPartnerQuality")
local XUiPanelQualityUp = require("XUi/XUiPartner/PartnerProperty/PanelPartnerQuality/XUiPanelQualityUp")
local XUiPanelQualityStar = require("XUi/XUiPartner/PartnerProperty/PanelPartnerQuality/XUiPanelQualityStar")
local XUiPanelQualityMax = require("XUi/XUiPartner/PartnerProperty/PanelPartnerQuality/XUiPanelQualityMax")
local XUiPanelQualityUpConfirm = require("XUi/XUiPartner/PartnerProperty/PanelPartnerQuality/XUiPanelQualityUpConfirm")
local XUiPanelQualityMain = require("XUi/XUiPartner/PartnerProperty/PanelPartnerQuality/XUiPanelQualityMain")

local panelState = {
    QualityStar = 1,
    QualityUp = 2,
    QualityMax = 3,
    QualityUpConfirm = 4,
    QualityMain = 5,
}

function XUiPanelPartnerQuality:Ctor(ui, base)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Base = base
    self.IsQualityUpFinish = false
    self.IsShowStarPanel = false
    XTool.InitUiObject(self)
    self.QualityUpPanel = XUiPanelQualityUp.New(self.PanelQualityUp, self, self.Base)
    self.QualityStarPanel = XUiPanelQualityStar.New(self.PanelQualityStar, self, self.Base)
    self.QualityMaxPanel = XUiPanelQualityMax.New(self.PanelQualityMax, self, self.Base)
    self.QualityUpConfirmPanel = XUiPanelQualityUpConfirm.New(self.PanelQualityUpConfirm, self, self.Base)
    self.QualityMainPanel = XUiPanelQualityMain.New(self.PanelQualityMain, self, self.Base)
end

function XUiPanelPartnerQuality:UpdatePanel(data)
    self.Data = data
    self:CheckPanelState()
    self:ShowPanel(data)
    self.GameObject:SetActiveEx(true)
    self.Base.BtnTabQuality:ShowTag(self.Data:GetIsMaxQuality())
end

function XUiPanelPartnerQuality:HidePanel()
    self.GameObject:SetActiveEx(false)
    self.Base:ShowTabs()
    self.IsShowStarPanel = false
end

function XUiPanelPartnerQuality:CheckPanelState()
    if self.IsQualityUpFinish then
        self.PanelState = panelState.QualityUpConfirm
    else
        if self.Data:GetIsMaxQuality() then
            self.PanelState = panelState.QualityMax
        else
            if not self.Data:GetCanUpQuality() then
                self.PanelState = self.IsShowStarPanel and panelState.QualityStar or panelState.QualityMain
            else
                self.PanelState = panelState.QualityUp
                --激活满切换到进化界面，重置self.IsShowStarPanel
                self.IsShowStarPanel = false 
            end
        end
    end
end

function XUiPanelPartnerQuality:OpenStarPanel()
    self.IsShowStarPanel = true
    self:CheckPanelState()
    self:ShowPanel(self.Data)
end

function XUiPanelPartnerQuality:CloseStarPanel()
    self.IsShowStarPanel = false
    self:CheckPanelState()
    self:ShowPanel(self.Data)
end

function XUiPanelPartnerQuality:ShowPanel(data)
    self.QualityUpPanel:HidePanel()
    self.QualityStarPanel:HidePanel()
    self.QualityMaxPanel:HidePanel()
    self.QualityUpConfirmPanel:HidePanel()
    self.QualityMainPanel:HidePanel()
    self.Base:ShowTabs()

    if self.PanelState == panelState.QualityStar then
        self.QualityStarPanel:UpdatePanel(data)
        self.Base:HideTabs()
    elseif self.PanelState == panelState.QualityUp then
        self.QualityUpPanel:UpdatePanel(data)
    elseif self.PanelState == panelState.QualityMax then
        self.QualityMaxPanel:UpdatePanel(data)
    elseif self.PanelState == panelState.QualityUpConfirm then
        self.QualityUpConfirmPanel:UpdatePanel(data)
    elseif self.PanelState == panelState.QualityMain then
        self.QualityMainPanel:UpdatePanel(data)
    end
    
    if self.PanelState == panelState.QualityStar then
        self:HideRoleModel()
    else
        self:ShowRoleModel()
    end
    
    self:PlayEnableAnime()
end

function XUiPanelPartnerQuality:SetQualityUpFinish(IsFinish)
    self.IsQualityUpFinish = IsFinish
end

function XUiPanelPartnerQuality:ShowRoleModel()
    self.Base:ShowRoleModel()
end

function XUiPanelPartnerQuality:HideRoleModel()
    self.Base:HideRoleModel()
end

function XUiPanelPartnerQuality:PlayEnableAnime()
    XScheduleManager.ScheduleOnce(function()
            if self.PanelState == panelState.QualityStar then
                self.Animation:GetObject("PanelQualityStarEnable"):PlayTimelineAnimation()
                self.Animation:GetObject("PanelQualityStarLoop").gameObject:SetActiveEx(false)
                self.Animation:GetObject("PanelQualityStarLoop").gameObject:SetActiveEx(true)
            elseif self.PanelState == panelState.QualityUp then
                self.Animation:GetObject("PanelQualityUpEnable"):PlayTimelineAnimation()
            elseif self.PanelState == panelState.QualityMax then
                self.Animation:GetObject("PanelQualityMaxEnable"):PlayTimelineAnimation()
            elseif self.PanelState == panelState.QualityUpConfirm then
                XLuaUiManager.SetMask(true)
                self.Animation:GetObject("PanelQualityUpConfirmEnable"):PlayTimelineAnimation(function ()
                        XLuaUiManager.SetMask(false)
                end)
            elseif self.PanelState == panelState.QualityMain then
                self.Animation:GetObject("PanelQualityMain"):PlayTimelineAnimation()
                self.Animation:GetObject("PanelQualityMainLoop").gameObject:SetActiveEx(false)
                self.Animation:GetObject("PanelQualityMainLoop").gameObject:SetActiveEx(true)
            end
        end, 1)
end

return XUiPanelPartnerQuality
