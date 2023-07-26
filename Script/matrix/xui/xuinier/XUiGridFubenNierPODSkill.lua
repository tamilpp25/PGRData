local XUiGridFubenNierPODSkill = XClass(nil, "XUiGridFubenNierPODSkill")

function XUiGridFubenNierPODSkill:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)

    self.PanelSkillNormal.CallBack = function() self:OnBtnSkillClick() end
end

function XUiGridFubenNierPODSkill:RefreshData(info, index)
    self.NierPOD = XDataCenter.NieRManager.GetNieRPODData()
    local skillId = info.SkillId
    local isActive = info.IsActive
    self.Index = index
    local skillName = self.NierPOD:GetNieRPODSkillName(skillId)
    local skillIcon = self.NierPOD:GetNieRPODSkillIcon(skillId)
    local skillLvStr = CS.XTextManager.GetText("NieRPODSkillLevel", self.NierPOD:GetNieRPODSkillLevelById(skillId))
    self.PanelSkillNormal:SetRawImage(skillIcon)
    self.PanelSkillNormal:SetNameByGroup(1, skillLvStr)
    self.PanelSkillNormal:SetNameByGroup(0, skillName)

    if self.PanelIconTip then
        if isActive then
            self.PanelIconTip.gameObject:SetActiveEx(false)
        else
            self.PanelIconTip.gameObject:SetActiveEx(true)
        end
    end
    
end

function XUiGridFubenNierPODSkill:SetSelectStatue(isSel)
    self.Normal.gameObject:SetActiveEx(not isSel)
    self.Select.gameObject:SetActiveEx(isSel)
end

function XUiGridFubenNierPODSkill:OnBtnSkillClick()
    self.RootUi:OnBtnSkillClick(self.Index)
end

return XUiGridFubenNierPODSkill