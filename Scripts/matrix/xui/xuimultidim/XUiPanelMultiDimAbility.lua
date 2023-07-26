local XUiPanelMultiDimAbility = XClass(nil,"XUiPanelMultiDimAbility")

function XUiPanelMultiDimAbility:Ctor(transform)
    self.Transform = transform
    self.GameObject = transform.gameObject
    XTool.InitUiObject(self)
    end

function XUiPanelMultiDimAbility:Refresh(playerData)
    self.PlayerData = playerData
    local careerCfg = XMultiDimConfig.GetMultiDimCharacterCareer(playerData.FightNpcData.Character.Id)
    local lv = 0
    for _, id in pairs(playerData.CoreTalentIds) do
        local classId = XMultiDimConfig.GetMultiDimTalentClassId(id)
        if classId == careerCfg.Career then
            lv = lv + XMultiDimConfig.GetMultiDimTalentLevel(id)
        end
    end
    self.TxtLevel.text = "Lv "..lv
    self.TxtAbility.text = playerData.FightNpcData.Character.Ability
    self.RImgArms:SetRawImage(XMultiDimConfig.GetMultiDimCareerIcon(careerCfg.Career))
    self.TxtTitle.text = CS.XTextManager.GetText("MultiDimCareer"..careerCfg.Career)
end

return XUiPanelMultiDimAbility