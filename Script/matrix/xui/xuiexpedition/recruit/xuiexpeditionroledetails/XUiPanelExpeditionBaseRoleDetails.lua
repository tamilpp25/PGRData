local XUiPanelExpeditionBaseRoleDetails = XClass(nil, "XUiPanelExpeditionBaseRoleDetails")
local XUiExpeditionSkillIconGrid = require("XUi/XUiExpedition/Recruit/XUiExpeditionRoleDetails/XUiExpeditionSkillIconGrid")
local XUiExpeditionComboIconPanel = require("XUi/XUiExpedition/Recruit/XUiExpeditionRoleDetails/XUiExpeditionComboIconPanel")
local XUiPanelExpeditionEquipment = require("XUi/XUiExpedition/Recruit/XUiExpeditionRoleDetails/XUiPanelExpeditionEquipment")

function XUiPanelExpeditionBaseRoleDetails:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    self.DetailsType = XExpeditionConfig.MemberDetailsType.RecruitMember
    XTool.InitUiObject(self)
    self:RegisterUiEvents()
    self:InitView()
    self.GridSubSkill.gameObject:SetActiveEx(false)
    self.GridCombo.gameObject:SetActiveEx(false)
    self.RecruitComboList = XUiExpeditionComboIconPanel.New(self.SViewComboList, self, self.DetailsType)
    self.EquipmentPanel = XUiPanelExpeditionEquipment.New(self.Equipment, self)
end

function XUiPanelExpeditionBaseRoleDetails:RegisterUiEvents()
    
end

function XUiPanelExpeditionBaseRoleDetails:InitView()

end

function XUiPanelExpeditionBaseRoleDetails:Refresh(eChara, gridIndex)
    self.EChara = eChara
    self.GridIndex = gridIndex
    -- 基本信息
    self:RefreshContent()
    -- 装备和意识信息
    self.EquipmentPanel:Refresh(eChara)
    -- 技能信息
    self:RefreshSkill()
    -- 成员组合信息
    self.RecruitComboList:UpdateData(eChara)
end

function XUiPanelExpeditionBaseRoleDetails:RefreshContent()
    self.TxtLv.text = self.EChara:GetAbility()
    self.RImgTypeIcon:SetRawImage(self.EChara:GetJobTypeIcon())
    self.TxtName.text = self.EChara:GetCharaName()
    self.TxtNameOther.text = self.EChara:GetCharacterTradeName()
    self.TxtLevel.text = self.EChara:GetRankStr()
    local elementList = self.EChara:GetCharacterElements()
    for i = 1, 3 do
        local rImg = self["RImgCharElement" .. i]
        if elementList[i] then
            rImg.gameObject:SetActive(true)
            local elementConfig = XExpeditionConfig.GetCharacterElementById(elementList[i])
            rImg:SetRawImage(elementConfig.Icon)
        else
            rImg.gameObject:SetActive(false)
        end
    end
    if self.RImgIconHear then
        self.RImgIconHear:SetRawImage(self.EChara:GetSmallHeadIcon())
    end
end

function XUiPanelExpeditionBaseRoleDetails:RefreshSkill()
    self.Skills = self.EChara:GetLockSkill()
    if not self.SkillGrids then
        self.SkillGrids = {}
        for i = 1, #self.Skills do
            local skillInfo = self.Skills[i]
            local skillPrefab = CS.UnityEngine.Object.Instantiate(self.GridSubSkill.gameObject)
            skillPrefab.transform:SetParent(self.PanelSubSkillList.transform, false)
            self.SkillGrids[i] = XUiExpeditionSkillIconGrid.New(skillPrefab)
            self.SkillGrids[i]:RefreshData(skillInfo)
            self.SkillGrids[i].GameObject:SetActiveEx(true)
            XUiHelper.RegisterClickEvent(self, self.SkillGrids[i].BtnSubSkillIconBg, function()
                XLuaUiManager.Open("UiExpeditionBuffTips", XDataCenter.ExpeditionManager.BuffTipsType.Skill, self.Skills)
            end
            )
        end
    else
        for i = 1, #self.SkillGrids do
            if self.Skills[i] then
                local skillInfo = self.Skills[i]
                self.SkillGrids[i]:RefreshData(skillInfo)
                self.SkillGrids[i].GameObject:SetActiveEx(true)
            else
                self.SkillGrids[i].GameObject:SetActiveEx(false)
            end
        end
    end
end

return XUiPanelExpeditionBaseRoleDetails