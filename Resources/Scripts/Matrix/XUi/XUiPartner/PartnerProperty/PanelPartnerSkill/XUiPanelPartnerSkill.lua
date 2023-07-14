local XUiPanelPartnerSkill = XClass(nil, "XUiPanelPartnerSkill")
local XUiPanelSkillUp = require("XUi/XUiPartner/PartnerProperty/PanelPartnerSkill/XUiPanelSkillUp")
local XUiPanelSkillUpConfirm = require("XUi/XUiPartner/PartnerProperty/PanelPartnerSkill/XUiPanelSkillUpConfirm")
local XUiPanelAnimationControl = require("XUi/XUiPartner/PartnerProperty/PanelPartnerSkill/XUiPanelAnimationControl")
local panelState = {
    SkillUp = 1,
    SkillUpConfirm = 2,
}

function XUiPanelPartnerSkill:Ctor(ui, base)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Base = base
    self.IsSkillUpFinish = false
    XTool.InitUiObject(self)
    self.SkillUpPanel = XUiPanelSkillUp.New(self.PanelSkillUp, self, self.Base)
    self.SkillUpConfirmPanel = XUiPanelSkillUpConfirm.New(self.PanelSkillUpConfirm, self, self.Base)
    self.AnimationControlPanel = XUiPanelAnimationControl.New(self.PanelAnimationControl, self, self.Base)
end

function XUiPanelPartnerSkill:UpdatePanel(data)
    self.Data = data
    self:CheckPanelState()
    self:ShowPanel(data)
    self.GameObject:SetActiveEx(true)
    self.Base.BtnTabSkill:ShowTag(self.Data:GetIsTotalSkillLevelMax())
end

function XUiPanelPartnerSkill:HidePanel()
    self.GameObject:SetActiveEx(false)
end

function XUiPanelPartnerSkill:CheckPanelState()
    if self.IsSkillUpFinish then
        self.PanelState = panelState.SkillUpConfirm
    else
        self.PanelState = panelState.SkillUp
    end
end

function XUiPanelPartnerSkill:ShowPanel(data)
    self.SkillUpPanel:HidePanel()
    self.SkillUpConfirmPanel:HidePanel()

    if self.PanelState == panelState.SkillUp then
        self.SkillUpPanel:UpdatePanel(data)
        self.SkillUpPanel:PlayEnableAnime()
    elseif self.PanelState == panelState.SkillUpConfirm then
        self.SkillUpConfirmPanel:UpdatePanel(data, self.SkillUpInfo)
        self.SkillUpConfirmPanel:PlayEnableAnime()
    end
    
    self.AnimationControlPanel:UpdatePanel()
end

function XUiPanelPartnerSkill:SetSkillUpFinish(IsFinish)
    self.IsSkillUpFinish = IsFinish
end

function XUiPanelPartnerSkill:SetSkillUpInfo(info)
    self.SkillUpInfo = info
end

return XUiPanelPartnerSkill