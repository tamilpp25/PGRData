XUiArchiveMonsterSkill = XClass(XUiNode, "XUiArchiveMonsterSkill")

local SkillMax = 15

function XUiArchiveMonsterSkill:OnStart(data, base)
    self.Data = data
    self.Base = base

    self.TxtContent = {
        self.TxtContent1,
        self.TxtContent2,
        self.TxtContent3,
        self.TxtContent4,
        self.TxtContent5,
        self.TxtContent6,
        self.TxtContent7,
        self.TxtContent8,
        self.TxtContent9,
        self.TxtContent10,
        self.TxtContent11,
        self.TxtContent12,
        self.TxtContent13,
        self.TxtContent14,
        self.TxtContent15,
    }
end

function XUiArchiveMonsterSkill:SelectType(index)
    self:Open()
    self:SetMonsterSkillData(index)
end

function XUiArchiveMonsterSkill:SetMonsterSkillData(type)
    local skillList = self._Control:GetArchiveMonsterSkillList(self.Data:GetNpcId(type))

    for index = 1, SkillMax do
        if skillList[index] then
            if not self.SkillItem then self.SkillItem = {} end

            if not self.SkillItem[index] then
                self.SkillItem[index] = {}
                self.SkillItem[index].Transform = self.TxtContent[index].transform
                self.SkillItem[index].GameObject = self.TxtContent[index].gameObject
                XTool.InitUiObject(self.SkillItem[index])
            end
            self.SkillItem[index].TxtTitle.text = skillList[index]:GetTitle()
            self.SkillItem[index].TxtDesc.text = skillList[index]:GetText()
            self.SkillItem[index].TxtLock.text = skillList[index]:GetLockDesc()
            self.SkillItem[index].UnLock.gameObject:SetActiveEx(not skillList[index]:GetIsLock())
            self.SkillItem[index].Lock.gameObject:SetActiveEx(skillList[index]:GetIsLock())
        end
        self.TxtContent[index].gameObject:SetActiveEx(skillList[index] and true or false)
    end
end

