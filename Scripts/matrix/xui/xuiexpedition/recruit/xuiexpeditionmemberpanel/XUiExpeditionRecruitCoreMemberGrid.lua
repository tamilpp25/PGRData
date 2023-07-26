local XUiExpeditionRecruitCoreMemberGrid = XClass(nil, "XUiExpeditionRecruitCoreMemberGrid")

function XUiExpeditionRecruitCoreMemberGrid:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)
    self:RegisterUiEvents()
    
    self.Disable.gameObject:SetActiveEx(true)
    self.Normal.gameObject:SetActiveEx(false)
    self.PanelSelected.gameObject:SetActiveEx(false)
end

function XUiExpeditionRecruitCoreMemberGrid:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnCharacter, self.OnBtnCharacterClick)
end

function XUiExpeditionRecruitCoreMemberGrid:OnBtnCharacterClick()
    self.RootUi:OpenRoleDetailsPanel(self.EChara, XExpeditionConfig.MemberDetailsType.FireMember, nil,
            function()
                self.PanelSelected.gameObject:SetActiveEx(true)
            end,
            function()
                self.PanelSelected.gameObject:SetActiveEx(false)
            end)
end

function XUiExpeditionRecruitCoreMemberGrid:Refresh(eChara)
    self.Lock.gameObject:SetActiveEx(false)
    self.PanelDefaultMember.gameObject:SetActiveEx(eChara and eChara:GetIsDefaultTeamMember())
    self.Disable.gameObject:SetActiveEx(eChara == nil)
    self.Normal.gameObject:SetActiveEx(eChara ~= nil)
    
    if not eChara then
        return
    end
    self.EChara = eChara
    self.TxtFight.text = eChara:GetAbility()
    self.RImgHeadIcon:SetRawImage(eChara:GetSmallHeadIcon())
    local comboList = XDataCenter.ExpeditionManager.GetComboList()
    local showCombos = comboList:GetActiveComboIdsByEChara(eChara)
    for i = 1, 3 do
        local rImg = self["RImgCharElement" .. i]
        if rImg then
            if showCombos[i] then
                rImg.transform.parent.gameObject:SetActive(true)
                local combo = comboList:GetComboByComboId(showCombos[i])
                rImg:SetRawImage(combo:GetIconPath())
            else
                rImg.transform.parent.gameObject:SetActive(false)
            end
        end
    end
    self.TxtLevel.text = eChara:GetRankStr()
    if eChara:GetIsNew() then
        self.PanelEffectLvUp.gameObject:SetActiveEx(false)
        self.PanelEffectLvUp.gameObject:SetActiveEx(true)
    end
end

return XUiExpeditionRecruitCoreMemberGrid