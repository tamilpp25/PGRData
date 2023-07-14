local XUiPanelPartnerQuality = XClass(nil, "XUiPanelPartnerQuality")
local XUiPanelQualityUp = require("XUi/XUiPartner/PartnerProperty/PanelPartnerQuality/XUiPanelQualityUp")
local XUiPanelQualityStar = require("XUi/XUiPartner/PartnerProperty/PanelPartnerQuality/XUiPanelQualityStar")
local XUiPanelQualityMax = require("XUi/XUiPartner/PartnerProperty/PanelPartnerQuality/XUiPanelQualityMax")
local XUiPanelQualityUpConfirm = require("XUi/XUiPartner/PartnerProperty/PanelPartnerQuality/XUiPanelQualityUpConfirm")

local panelState = {
    QualityStar = 1,
    QualityUp = 2,
    QualityMax = 3,
    QualityUpConfirm = 4,
}

function XUiPanelPartnerQuality:Ctor(ui, base)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Base = base
    self.IsQualityUpFinish = false
    XTool.InitUiObject(self)
    self.QualityUpPanel = XUiPanelQualityUp.New(self.PanelQualityUp, self, self.Base)
    self.QualityStarPanel = XUiPanelQualityStar.New(self.PanelQualityStar, self, self.Base)
    self.QualityMaxPanel = XUiPanelQualityMax.New(self.PanelQualityMax, self, self.Base)
    self.QualityUpConfirmPanel = XUiPanelQualityUpConfirm.New(self.PanelQualityUpConfirm, self, self.Base)
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
end

function XUiPanelPartnerQuality:CheckPanelState()
    if self.IsQualityUpFinish then
        self.PanelState = panelState.QualityUpConfirm
    else
        if self.Data:GetIsMaxQuality() then
            self.PanelState = panelState.QualityMax
        else
            if not self.Data:GetCanUpQuality() then
                self.PanelState = panelState.QualityStar
            else
                self.PanelState = panelState.QualityUp
            end
        end
    end
end

function XUiPanelPartnerQuality:ShowPanel(data)
    self.QualityUpPanel:HidePanel()
    self.QualityStarPanel:HidePanel()
    self.QualityMaxPanel:HidePanel()
    self.QualityUpConfirmPanel:HidePanel()
    
    if self.PanelState == panelState.QualityStar then
        self.QualityStarPanel:UpdatePanel(data)
    elseif self.PanelState == panelState.QualityUp then
        self.QualityUpPanel:UpdatePanel(data)
    elseif self.PanelState == panelState.QualityMax then
        self.QualityMaxPanel:UpdatePanel(data)
    elseif self.PanelState == panelState.QualityUpConfirm then
        self.QualityUpConfirmPanel:UpdatePanel(data)
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
            end
        end, 1)
end

return XUiPanelPartnerQuality
