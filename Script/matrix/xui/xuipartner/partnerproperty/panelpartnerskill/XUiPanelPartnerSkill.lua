local XUiPanelPartnerSkill = XClass(nil, "XUiPanelPartnerSkill")
local XUiPanelSkillMain = require("XUi/XUiPartner/PartnerProperty/PanelPartnerSkill/XUiPanelSkillMain")
local XUiPanelSkillInfo = require("XUi/XUiPartner/PartnerProperty/PanelPartnerSkill/XUiPanelSkillInfo")
local XUiPanelSkillUpConfirm = require("XUi/XUiPartner/PartnerProperty/PanelPartnerSkill/XUiPanelSkillUpConfirm")
local panelState = {
    SkillMain = 1,
    SkillInfo = 2,
    SkillUpConfirm = 3,
}

function XUiPanelPartnerSkill:Ctor(ui, base)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Base = base
    self.IsSkillUpFinish = false
    XTool.InitUiObject(self)
    self.PanelState = panelState.SkillMain
    self.SelectSkillIndex = 1
    self.SkillMainPanel = XUiPanelSkillMain.New(self.PanelSkillMain, self, self.Base)
    self.SkillInfoPanel = XUiPanelSkillInfo.New(self.PanelSkillInfo, self, self.Base)
    self.SkillUpConfirmPanel = XUiPanelSkillUpConfirm.New(self.PanelSkillUpConfirm, self, self.Base)
end

function XUiPanelPartnerSkill:UpdatePanel(data)
    self.Data = data
    if not self.Base.Base.IsUpdateByEvent then
        self:SetSkillMainState()
    end
    self:ShowPanel()
    self.GameObject:SetActiveEx(true)
    self.Base.BtnTabSkill:ShowTag(self.Data:GetIsTotalSkillLevelMax())
    if self.PanelState == panelState.SkillMain then
        self:PlayEnableAnime()
    end
end

function XUiPanelPartnerSkill:HidePanel()
    --还原状态
    self:SetSkillMainState()
    
    self.GameObject:SetActiveEx(false)
end

function XUiPanelPartnerSkill:ShowPanel()
    self.SkillMainPanel:HidePanel()
    self.SkillInfoPanel:HidePanel()
    self.SkillUpConfirmPanel:HidePanel()

    if self.PanelState == panelState.SkillMain then
        self.SkillMainPanel:UpdatePanel(self.Data)
        self.SkillMainPanel:PlayEnableAnime()
    elseif self.PanelState == panelState.SkillInfo then
        self.SkillInfoPanel:UpdatePanel(self.Data, self.SelectSkillIndex)
        self.SkillInfoPanel:PlayEnableAnime()
    elseif self.PanelState == panelState.SkillUpConfirm then
        XScheduleManager.ScheduleOnce(function()
            self:SetSkillInfoState()
            self:ShowPanel()
            XLuaUiManager.Open("UiPartnerPopupTip",CS.XTextManager.GetText("PartnerSkillUpConfirm"))
        end, 2)
        --self.SkillUpConfirmPanel:UpdatePanel(self.Data, self.SkillUpInfo)
        --self.SkillUpConfirmPanel:PlayEnableAnime()
    end
end

function XUiPanelPartnerSkill:SetSkillMainState()
    self.PanelState = panelState.SkillMain
end

function XUiPanelPartnerSkill:SetSkillInfoState(selectIndex)
    self.PanelState = panelState.SkillInfo
    self.SelectSkillIndex = selectIndex or self.SelectSkillIndex
end

function XUiPanelPartnerSkill:SetSkillUpInfo(info, data)
    self.SkillUpInfo = info
    self.Data = data
    self.PanelState = panelState.SkillUpConfirm
end

function XUiPanelPartnerSkill:IsInfoSkillState()
    return self.PanelState == panelState.SkillInfo
end

function XUiPanelPartnerSkill:PlayEnableAnime()
    XScheduleManager.ScheduleOnce(function()
        self.Animation:GetObject("AnimEnable"):PlayTimelineAnimation()
        end, 1)
end

return XUiPanelPartnerSkill