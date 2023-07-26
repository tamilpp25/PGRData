local XUiFubenMaverickSkillGrid = XClass(nil, "XUiFubenMaverickSkillGrid")

function XUiFubenMaverickSkillGrid:Ctor(ui)
    XTool.InitUiObjectByUi(self, ui)
    CsXUiHelper.RegisterClickEvent(ui, function()
        if not self.Skill then
            return
        end
        
        local data = { IsSkill = true }
        for k, v in pairs(self.Skill) do
            data[k] = v
        end
        XLuaUiManager.Open("UiFubenMaverickSkillTips", data)
    end)
end

function XUiFubenMaverickSkillGrid:Refresh(skill)
    self.Skill = skill
    
    if self.Skill then
        self.Text.text = self.Skill.Name
        self.Icon:SetRawImage(self.Skill.Icon)
        self.GameObject:SetActiveEx(true)
    else
        self.GameObject:SetActiveEx(false)
    end
end

return XUiFubenMaverickSkillGrid