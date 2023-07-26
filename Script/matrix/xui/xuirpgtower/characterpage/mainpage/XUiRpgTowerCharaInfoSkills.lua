-- 兵器蓝图角色页面角色状态面板技能栏
local XUiRpgTowerCharaInfoSkills = XClass(nil, "XUiRpgTowerCharaInfoSkills")
local XUiRpgTowerCharaInfoSkillGrid = require("XUi/XUiRpgTower/CharacterPage/MainPage/XUiRpgTowerCharaInfoSkillGrid")
function XUiRpgTowerCharaInfoSkills:Ctor(ui)
    XTool.InitUiObjectByUi(self, ui)
    self.GridSkill.gameObject:SetActiveEx(false)
    self.SkillList = {}
end
--================
--刷新技能信息
--================
function XUiRpgTowerCharaInfoSkills:RefreshSkills(rCharacter)
    local skills = rCharacter:GetRoleListSkill()
    self:ResetSkillList()
    local index = 1
    for _, skillInfo in pairs(skills) do
        if not self.SkillList[index] then
            local skillUi = CS.UnityEngine.GameObject.Instantiate(self.GridSkill)
            skillUi.transform:SetParent(self.PanelSkills.transform, false)
            self.SkillList[index] = XUiRpgTowerCharaInfoSkillGrid.New(skillUi)
        end
        self.SkillList[index]:RefreshSkill(skillInfo)
        self.SkillList[index].GameObject:SetActiveEx(true)
        index = index + 1
    end
end
--================
--刷新技能列表
--================
function XUiRpgTowerCharaInfoSkills:ResetSkillList()
    for _, grid in pairs(self.SkillList) do
        grid.GameObject:SetActiveEx(false)
    end
end

return XUiRpgTowerCharaInfoSkills