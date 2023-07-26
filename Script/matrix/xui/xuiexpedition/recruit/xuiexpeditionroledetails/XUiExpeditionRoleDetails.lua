--虚像地平线招募界面角色详细子页面
local XUiExpeditionRoleDetails = XLuaUiManager.Register(XLuaUi, "UiExpeditionRoleDetails")
local XUiPanelExpeditionRecruitRoleDetails = require("XUi/XUiExpedition/Recruit/XUiExpeditionRoleDetails/XUiPanelExpeditionRecruitRoleDetails")
local XUiPanelExpeditionFireRoleDetails = require("XUi/XUiExpedition/Recruit/XUiExpeditionRoleDetails/XUiPanelExpeditionFireRoleDetails")

function XUiExpeditionRoleDetails:OnAwake()
    self.RecruitDetails.gameObject:SetActiveEx(false)
    self.FireDetails.gameObject:SetActiveEx(false)
    self:RegisterUiEvents()
end

function XUiExpeditionRoleDetails:OnStart()
    self.PanelRecruit = XUiPanelExpeditionRecruitRoleDetails.New(self.RecruitDetails, self)
    self.PanelFire = XUiPanelExpeditionFireRoleDetails.New(self.FireDetails, self)
end

function XUiExpeditionRoleDetails:RefreshData(eChara, type, gridIndex, onCloseCb)
    self.EChara = eChara
    self.Type = type or XExpeditionConfig.MemberDetailsType.RecruitMember
    self.GridIndex = gridIndex
    self.OnCloseCb = onCloseCb
    self:RefreshPanel()
end

function XUiExpeditionRoleDetails:RegisterUiEvents()
    self:RegisterClickEvent(self.BtnClose, self.OnBtnCloseClick)
end

function XUiExpeditionRoleDetails:RefreshPanel()
    self.RecruitDetails.gameObject:SetActiveEx(self.Type == XExpeditionConfig.MemberDetailsType.RecruitMember)
    self.FireDetails.gameObject:SetActiveEx(self.Type == XExpeditionConfig.MemberDetailsType.FireMember)
    if self.Type == XExpeditionConfig.MemberDetailsType.RecruitMember then
        self.ShowPanel = self.PanelRecruit
    else
        self.ShowPanel = self.PanelFire
    end
    self.ShowPanel:Refresh(self.EChara, self.GridIndex)
end

function XUiExpeditionRoleDetails:OnBtnCloseClick()
    if self.OnCloseCb then
        self.OnCloseCb()
    end
    self:Close()
end

function XUiExpeditionRoleDetails:OnDisable()
    if self.OnCloseCb then
        self.OnCloseCb()
    end
end