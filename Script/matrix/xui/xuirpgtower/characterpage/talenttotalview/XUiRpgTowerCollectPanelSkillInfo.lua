-- 兵法蓝图天赋总览技能等级面板
local XUiRpgTowerCollectPanelSkillInfo = XClass(nil, "XUiRpgTowerCollectPanelSkillInfo")
local SkillDic = { -- 技能尾数编号字典
    RedBall = 1, -- 红球
    YellowBall = 6, -- 黄球
    BlueBall = 11, -- 蓝球
    NormalAttack = 16, -- 普通攻击
    FinalSkill = 17, -- 必杀
    CoreSkill = 21 -- 核心被动技能
}
function XUiRpgTowerCollectPanelSkillInfo:Ctor(ui)
    XTool.InitUiObjectByUi(self, ui)
end

function XUiRpgTowerCollectPanelSkillInfo:Refresh(rChara)
    self:ResetLevels()
    local skills = rChara:GetSkillPlusData()
    for skillId, skillLevel in pairs(skills) do
        local skillType = skillId % 100
        if skillType == SkillDic.RedBall then
            self.TxtRedNumber.text = skillLevel
        elseif skillType == SkillDic.YellowBall then
            self.TxtYellowNumber.text = skillLevel
        elseif skillType == SkillDic.BlueBall then
            self.TxtBlueNumber.text = skillLevel
        elseif skillType == SkillDic.NormalAttack then
            self.TxtAttackNumber.text = skillLevel
        elseif skillType == SkillDic.FinalSkill then
            self.TxtSpaceNumber.text = skillLevel
        elseif skillType == SkillDic.CoreSkill then
            self.TxtPassiveNumber.text = skillLevel
        end
    end
end

function XUiRpgTowerCollectPanelSkillInfo:ResetLevels()
    self.TxtRedNumber.text = 0
    self.TxtBlueNumber.text = 0
    self.TxtYellowNumber.text = 0
    self.TxtAttackNumber.text = 0
    self.TxtSpaceNumber.text = 0
    self.TxtPassiveNumber.text = 0
end

return XUiRpgTowerCollectPanelSkillInfo