local XUiPartnerShowSkillGrid = XClass(nil, "XUiPartnerShowSkillGrid")

function XUiPartnerShowSkillGrid:Ctor(ui)
   self.GameObject = ui.gameObject
   self.Transform = ui.transform
   -- XPartnerPassiveGroupSkill
   self.Skill = nil
   self.IsLock = nil
   self.OpenSkillFunc = nil
   XTool.InitUiObject(self)
   self:RegisterUiEvents()
end

-- skill : XPartnerPassiveGroupSkill
-- isLock : 技能槽是否被锁住
function XUiPartnerShowSkillGrid:SetData(skill, isLock, isNone, openSkillFunc)
    self.GameObject:SetActiveEx(true)
    self.Skill = skill
    self.IsLock = isLock
    self.OpenSkillFunc = openSkillFunc
    local isNullSkill = skill == nil
    -- 如果没有锁住并存在技能直接初始化技能相关信息
    if not isLock and not isNullSkill and not isNone then
        self.RImgSkillIcon:SetRawImage(skill:GetSkillIcon())
        self.TxtLevel.text = skill:GetLevelStr()    
    end
    self.PanelLock.gameObject:SetActiveEx(isLock and not isNone)
    self.PanelSkill.gameObject:SetActiveEx(not isLock and not isNullSkill and not isNone)
    self.PanelNoSkill.gameObject:SetActiveEx(not isLock and isNullSkill and not isNone)
    self.PanelNone.gameObject:SetActiveEx(isNone)
end

--########################## 私有方法 ##############################

function XUiPartnerShowSkillGrid:RegisterUiEvents()
    self.BtnSelf.CallBack = function() self:OnBtnSelfClicked() end
end

function XUiPartnerShowSkillGrid:OnBtnSelfClicked()
    -- 未解锁
    if self.IsLock then
        XUiManager.TipError(CS.XTextManager.GetText("PartnerSeatNotLock"))
        return
    end
    -- 已解锁，未装备
    if self.Skill == nil then
        XUiManager.TipError(CS.XTextManager.GetText("PartnerSkillUnequipped"))
        return
    end
    if self.OpenSkillFunc then
        self.OpenSkillFunc(self.Skill)
    end
end

return XUiPartnerShowSkillGrid