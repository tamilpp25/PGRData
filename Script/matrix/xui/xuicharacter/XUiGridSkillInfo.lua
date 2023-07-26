-- V1.29 角色技能优化 该类不在使用 具体使用在 UiSkillDetails
XUiGridSkillInfo = XClass(nil, "XUiGridSkillInfo")

function XUiGridSkillInfo:Ctor(ui, skill, detailClickCb)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self.BtnDetails.CallBack = function() detailClickCb(self.SkillId) end
    self.BtnNounParsing.CallBack = handler(self, self.OnClickBtnNounParsing)
    self:UpdateData(skill)
end

function XUiGridSkillInfo:SetIndex(index)
    self.Index = index
end

function XUiGridSkillInfo:UpdateEntryBtn()
    if not XTool.IsNumberValid(self.SubSkillId) then
        self.BtnNounParsing.gameObject:SetActiveEx(false)
        return
    end

    self.EntryList = XCharacterConfigs.GetSkillGradeDesConfigEntryList(self.SubSkillId, self.SubSkillLevel)
    if XTool.IsTableEmpty(self.EntryList) then
        self.BtnNounParsing.gameObject:SetActiveEx(false)
        return
    end

    self.BtnNounParsing.gameObject:SetActiveEx(true)
end

function XUiGridSkillInfo:OnClickBtnNounParsing()
    if XTool.IsTableEmpty(self.EntryList) then return end

    if not XLuaUiManager.IsUiShow("UiCharSkillOtherParsing") then
        XLuaUiManager.Open("UiCharSkillOtherParsing", self.EntryList)
    end
end

function XUiGridSkillInfo:UpdateData(skill)
    self.Skill = skill
    self.TxtSkillLevel.text = skill.totalLevel
    self.TxtSkillName.text = skill.configDes.Name
    self.TxtSkillDesc.text = skill.configDes.Intro
end

function XUiGridSkillInfo:SetSubInfo(characterId, index, level, skillId)
    self.SkillId = skillId

    local config = self.Skill.subSkills[index]
    local levelStr = level

    local addLevel = 0
    local addLevelStr = ""
    local resonanceLevel = XDataCenter.CharacterManager.GetResonanceSkillLevel(characterId, skillId)
    local assignLevel = XDataCenter.FubenAssignManager.GetSkillLevel(characterId, skillId)

    if (resonanceLevel and resonanceLevel > 0) then
        addLevel = addLevel + resonanceLevel
    end

    if (assignLevel and assignLevel > 0) then
        addLevel = addLevel + assignLevel
    end

    if addLevel ~= 0 then
        addLevelStr = addLevelStr .. CS.XTextManager.GetText("CharacterSkillLevelDetail", addLevel)
        levelStr = level .. addLevelStr
        self.BtnDetails.gameObject:SetActiveEx(true)
    else
        self.BtnDetails.gameObject:SetActiveEx(false)
    end

    self.SubSkillId = config.SubSkillId
    self.SubSkillLevel = level + addLevel

    local gradeConfig = XCharacterConfigs.GetSkillGradeDesConfig(self.SubSkillId, self.SubSkillLevel)
    self.TxtSkillLevel.text = levelStr
    self.TxtSkillDesc.text = gradeConfig.Intro
    self.TxtSkillName.text = gradeConfig.Name

    self:UpdateEntryBtn()
end

function XUiGridSkillInfo:SetSubInfoByCharacterData(npcData, index, level, skillId, assignChapterRecords)
    self.SkillId = skillId

    local config = self.Skill.subSkills[index]
    local levelStr = level

    local addLevel = 0
    local addLevelStr = ""
    local resonanceSkillLevelMap = XMagicSkillManager.GetResonanceSkillLevelMap(npcData)
    local resonanceLevel = resonanceSkillLevelMap[skillId] or 0

    local assignLevel = XDataCenter.FubenAssignManager.GetSkillLevelByCharacterData(npcData.Character, skillId, assignChapterRecords)

    if (resonanceLevel and resonanceLevel > 0) then
        addLevel = addLevel + resonanceLevel
    end

    if (assignLevel and assignLevel > 0) then
        addLevel = addLevel + assignLevel
    end

    if addLevel ~= 0 then
        addLevelStr = addLevelStr .. CS.XTextManager.GetText("CharacterSkillLevelDetail", addLevel)
        levelStr = level .. addLevelStr
        self.BtnDetails.gameObject:SetActiveEx(true)
    else
        self.BtnDetails.gameObject:SetActiveEx(false)
    end

    local gradeConfig = XCharacterConfigs.GetSkillGradeDesConfig(config.SubSkillId, level + addLevel)
    self.TxtSkillLevel.text = levelStr
    self.TxtSkillDesc.text = gradeConfig.Intro
    self.TxtSkillName.text = gradeConfig.Name

    self:UpdateEntryBtn()
end