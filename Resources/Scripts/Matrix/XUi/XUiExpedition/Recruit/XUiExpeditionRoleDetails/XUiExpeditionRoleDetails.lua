--虚像地平线招募界面角色详细子页面
local XUiExpeditionRoleDetails = XLuaUiManager.Register(XLuaUi, "UiExpeditionRoleDetails")
local XUiExpeditionSkillIconGrid = require("XUi/XUiExpedition/Recruit/XUiExpeditionRoleDetails/XUiExpeditionSkillIconGrid")
local XUiExpeditionComboIconPanel = require("XUi/XUiExpedition/Recruit/XUiExpeditionRoleDetails/XUiExpeditionComboIconPanel")
local DetailsType = {
    RecruitMember = 1,
    FireMember = 2
    }
function XUiExpeditionRoleDetails:OnAwake()
    XTool.InitUiObject(self)
    self.RecruitPanel = { Transform = self.RecruitDetails.transform }
    XTool.InitUiObject(self.RecruitPanel)
    self.RecruitComboList = XUiExpeditionComboIconPanel.New(self.RecruitPanel.SViewComboList, self, DetailsType.RecruitMember)
    self.FirePanel = { Transform = self.FireDetails.transform }
    XTool.InitUiObject(self.FirePanel)
    self.FireComboList = XUiExpeditionComboIconPanel.New(self.FirePanel.SViewComboList, self, DetailsType.FireMember)
    self:AddListener()
    self.RecruitPanel.GridSubSkill.gameObject:SetActiveEx(false)
    self.FirePanel.GridSubSkill.gameObject:SetActiveEx(false)
    self.FirePanel.GridCombo.gameObject:SetActiveEx(false)
end

function XUiExpeditionRoleDetails:OnStart(rootUi, eChara, type, gridIndex)
    self.RootUi = rootUi
    self.RootUi.RoleDetails = self
    if eChara then self:RefreshData(eChara, type, gridIndex) end
end

function XUiExpeditionRoleDetails:RefreshData(eChara, type, gridIndex)
    self.EChara = eChara
    self.Type = type or DetailsType.RecruitMember
    self.GridIndex = gridIndex
    self:RefreshPanel()
end

function XUiExpeditionRoleDetails:AddListener()
    self:RegisterClickEvent(self.BtnRecruit, self.OnBtnRecruitClick)
    self:RegisterClickEvent(self.BtnMessage, self.OnBtnMessageClick)
    self:RegisterClickEvent(self.BtnFired, self.OnBtnFiredClick)
    self:RegisterClickEvent(self.BtnClose, self.OnBtnCloseClick)
end

function XUiExpeditionRoleDetails:RefreshPanel()
    self.RecruitDetails.gameObject:SetActiveEx(self.Type == DetailsType.RecruitMember)
    self.FireDetails.gameObject:SetActiveEx(self.Type == DetailsType.FireMember)
    if self.Type == DetailsType.RecruitMember then
        self.ShowPanel = self.RecruitPanel
    else
        self.ShowPanel = self.FirePanel
    end
    self.ShowPanel.TxtLv.text = self.EChara:GetAbility()
    local attrib = self.EChara:GetCharaAttributes()
    self.ShowPanel.TxtAttack.text = FixToInt(attrib[XNpcAttribType.AttackNormal])
    self.ShowPanel.TxtLife.text = FixToInt(attrib[XNpcAttribType.Life])
    self.ShowPanel.TxtDefense.text = FixToInt(attrib[XNpcAttribType.DefenseNormal])
    self.ShowPanel.TxtCrit.text = FixToInt(attrib[XNpcAttribType.Crit])
    self.ShowPanel.RImgTypeIcon:SetRawImage(self.EChara:GetJobTypeIcon())
    self.ShowPanel.TxtName.text = self.EChara:GetCharaName()
    self.ShowPanel.TxtNameOther.text = self.EChara:GetCharacterTradeName()
    self.ShowPanel.TxtLevel.text = self.EChara:GetRankStr()
    local elementList = self.EChara:GetCharacterElements()
    for i = 1, 3 do
        local rImg = self.ShowPanel["RImgCharElement" .. i]
        if elementList[i] then
            rImg.gameObject:SetActive(true)
            local elementConfig = XExpeditionConfig.GetCharacterElementById(elementList[i])
            rImg:SetRawImage(elementConfig.Icon)
        else
            rImg.gameObject:SetActive(false)
        end
    end
    self:RefreshSkill()
    if self.Type == DetailsType.FireMember then
        self.FireComboList:UpdateData(self.EChara)
        self:PlayAnimation("PanelRoleDetails2Enable")
    else
        self.RecruitComboList:UpdateData(self.EChara)
        self:PlayAnimation("PanelRoleDetails1Enable")
    end
end

function XUiExpeditionRoleDetails:RefreshSkill()
    self.Skills = self.EChara:GetLockSkill()
    if not self.ShowPanel.SkillGrids then
        self.ShowPanel.SkillGrids = {}
        for i = 1, #self.Skills do
            local skillInfo = self.Skills[i]
            local skillPrefab = CS.UnityEngine.Object.Instantiate(self.ShowPanel.GridSubSkill.gameObject)
            skillPrefab.transform:SetParent(self.ShowPanel.PanelSubSkillList.transform, false)
            self.ShowPanel.SkillGrids[i] = XUiExpeditionSkillIconGrid.New(skillPrefab)
            self.ShowPanel.SkillGrids[i]:RefreshData(skillInfo)
            self.ShowPanel.SkillGrids[i].GameObject:SetActiveEx(true)
            self:RegisterClickEvent(self.ShowPanel.SkillGrids[i].BtnSubSkillIconBg, function()
                    XLuaUiManager.Open("UiExpeditionBuffTips", XDataCenter.ExpeditionManager.BuffTipsType.Skill, self.Skills)
                    end
                )
        end
    else
        for i = 1, #self.ShowPanel.SkillGrids do
            if self.Skills[i] then
            local skillInfo = self.Skills[i]
                self.ShowPanel.SkillGrids[i]:RefreshData(skillInfo)
                self.ShowPanel.SkillGrids[i].GameObject:SetActiveEx(true)
            else
                self.ShowPanel.SkillGrids[i].GameObject:SetActiveEx(false)
            end
        end
    end
end

function XUiExpeditionRoleDetails:OnBtnRecruitClick()
    self:Close()
    XDataCenter.ExpeditionManager.RecruitMember(self.GridIndex)
end

function XUiExpeditionRoleDetails:OnBtnMessageClick()
    --XLuaUiManager.Open("UiExpeditionGuesBook", self.ECharacterCfg, self.HadCommented)
end

function XUiExpeditionRoleDetails:OnBtnCloseClick()
    self:Close()
end

function XUiExpeditionRoleDetails:OnBtnFiredClick()
    self:Close()
    XDataCenter.ExpeditionManager.FireMember(self.EChara:GetBaseId(), self.EChara:GetECharaId())
end