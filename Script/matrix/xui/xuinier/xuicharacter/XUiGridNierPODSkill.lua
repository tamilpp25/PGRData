local XUiGridNierPODSkill = XClass(nil, "XUiGridNierPODSkill")

function XUiGridNierPODSkill:Ctor(ui, rootUi)
    self.RootUi = rootUi
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    
    XTool.InitUiObject(self)

    self.BtnSkill.CallBack = function() self:OnBtnSkillClick() end
    self:SetSelectStatue(false)
end

function XUiGridNierPODSkill:RefreShData(skillInfo, index)
    self.NierPOD = XDataCenter.NieRManager.GetNieRPODData()
    self.Index = index
    local skillId = skillInfo.SkillId
    local skillName = self.NierPOD:GetNieRPODSkillName(skillId)
    local skillIcon = self.NierPOD:GetNieRPODSkillIcon(skillId)
    local condit, desc = self.NierPOD:CheckNieRPODSkillActive(skillId)
    local levelStr =  CS.XTextManager.GetText("NieRPODSkillLevel", self.NierPOD:GetNieRPODSkillLevelById(skillId))

    self.TxtNameNor.text = skillName
    self.TxtNameSel.text = skillName
    self.TxtLevelNor.text = levelStr
    self.TxtLevelSel.text = levelStr
    if not condit then
        self.PanelIconTip.gameObject:SetActiveEx(true)
    else
        self.PanelIconTip.gameObject:SetActiveEx(false)
    end
    self.RImgSubSkillIconNormal:SetRawImage(skillIcon)
    self.ImgSubSkillIconSelected:SetRawImage(skillIcon)
    
    local isRed = false
    if condit and self.NierPOD:CheckNieRPODSkillUpLevel(skillId) then
        local cousumId, consumCount = self.NierPOD:GetNieRPODSkillUpLevelItem(skillId)
        if cousumId ~= 0 then
            local haveCount = XDataCenter.ItemManager.GetCount(cousumId)
            if haveCount >= consumCount then
                isRed = true
            end
        end
        
    end
    if self.ImgBeidong then
        if not self.NierPOD:CheckNieRPODSkillActiveSkill(skillId) then
            self.ImgBeidong.gameObject:SetActiveEx(true)
        else
            self.ImgBeidong.gameObject:SetActiveEx(false)
        end
    end
    self.Red.gameObject:SetActiveEx(isRed)
end

function XUiGridNierPODSkill:SetSelectStatue(isSel)
    self.ImgBgSelected.gameObject:SetActiveEx(isSel)
    self.NomalLevel.gameObject:SetActiveEx(not isSel)
    self.SlectlLevel.gameObject:SetActiveEx(isSel)
end

function XUiGridNierPODSkill:OnBtnSkillClick()
    self.RootUi:OnSkillClick(self.Index)
end
return XUiGridNierPODSkill