local pairs = pairs
local table = table
local tableInsert = table.insert

XFightCharacterManager = XFightCharacterManager or {}

local function Awake()
end

local function GetQualityTemplate(templateId, quality)
    local qualityTemplate = XCharacterConfigs.GetQualityTemplate(templateId, quality)

    if not qualityTemplate then
        return XCode.CharacterManagerGetQualityTemplateNotFound, nil
    end

    return XCode.Success, qualityTemplate
end

local function GetGradeTemplates(templateId, grade)
    local gradeTemplate = XCharacterConfigs.GetGradeTemplates(templateId, grade)
    if not gradeTemplate then
        return XCode.CharacterManagerGetGradeTemplateNotFound, nil
    end

    return XCode.Success, gradeTemplate
end

local function GetCharSkillLevelEffectTemplate(skillId, level)
    local levelConfig = XCharacterConfigs.GetSkillLevelEffectTemplate(skillId, level)
    if not levelConfig then
        return XCode.CharacterSkillLevelEffectTemplateNotFound, nil
    end

    return XCode.Success, levelConfig
end

-----------------------------------------Attribs Begin---------------------------------------
---添加角色星数属性id
---当前品质，从1星累加到当前星
---@param characterData userdata 角色数据
---@param attribIds table 属性id列表
---@return XCode 状态码
local function DoAddStarAttribId(characterData, attribIds)
    if characterData.Star <= 0 then
        return XCode.Success
    end

    local code, template = GetQualityTemplate(characterData.Id, characterData.Quality)
    if code ~= XCode.Success then
        return code
    end

    local maxStar = #template.AttrId

    for i = 1, characterData.Star do
        if i > maxStar then
            break
        end

        local attribId = template.AttrId[i]
        if attribId > 0 then
            tableInsert(attribIds, attribId)
        end
    end

    return XCode.Success
end

---添加角色晋升属性id
---@param characterData userdata 角色数据
---@param attribIds table 属性id列表
---@return XCode 状态码
local function DoAddGradeAttribId(characterData, attribIds)
    local code, template = GetGradeTemplates(characterData.Id, characterData.Grade)
    if code ~= XCode.Success then
        return code
    end

    if template.AttrId > 0 then
        tableInsert(attribIds, template.AttrId)
    end

    return XCode.Success
end

--- 属性计算
--- 1、星星提供属性
--- 2、晋升提供属性
local function AddNumericAttribId(npcData, attribIds)
    if not npcData.Character then
        return XCode.Success
    end

    local code = DoAddStarAttribId(npcData.Character, attribIds)
    if code ~= XCode.Success then
        return code
    end

    code = DoAddGradeAttribId(npcData.Character, attribIds)
    if code ~= XCode.Success then
        return code
    end

    return XCode.Success
end
-----------------------------------------Attribs End-----------------------------------------
local function GetResonanceSkillLevelMap(npcData)
    local levelMap = {}

    local equips = npcData.Equips
    if not equips then
        return levelMap
    end

    XTool.LoopCollection(equips, function(equipData)
        if equipData.ResonanceInfo then
            XTool.LoopCollection(equipData.ResonanceInfo, function(resonance)
                if resonance.Type == CS.EquipResonanceType.CharacterSkill or resonance.Type == XEquipConfig.EquipResonanceType.CharacterSkill then
                    if resonance.CharacterId == npcData.Character.Id then
                        local skillId = resonance.TemplateId
                        local groupSkillIds = XCharacterConfigs.GetGroupSkillIds(skillId)

                        for _, groupSkillId in pairs(groupSkillIds) do
                            if levelMap[groupSkillId] then
                                levelMap[groupSkillId] = levelMap[groupSkillId] + 1
                            else
                                levelMap[groupSkillId] = 1
                            end
                        end
                    end
                end
            end)
        end
    end)

    return levelMap
end

---获取角色技能等级集合
---@param npcData userdata npc数据
---@return table 技能等级集合
local function GetCharSkillLevelMap(npcData)
    local levelMap = {}
    XTool.LoopCollection(npcData.Character.SkillList, function(skill)
        local skillId = skill.Id
        local skillLevel = skill.Level
        levelMap[skillId] = skillLevel
    end)

    local resLevelMap = GetResonanceSkillLevelMap(npcData)
    for skillId, level in pairs(resLevelMap) do
        if levelMap[skillId] then
            levelMap[skillId] = levelMap[skillId] + level
        end
    end

    if npcData.CharacterSkillPlus then
        XTool.LoopMap(npcData.CharacterSkillPlus, function(skillId, level)
            if levelMap[skillId] then
                levelMap[skillId] = levelMap[skillId] + level
            end
        end)
    end

    return levelMap
end

--- 技能等级
--- 1、角色技能加成
--- 2、共鸣提供加成
local function GetSkillLevel(npcData, levelMap)
    if not npcData.Character then
        return XCode.Success
    end

    local charLevelMap = GetCharSkillLevelMap(npcData)

    for skillId, level in pairs(charLevelMap) do
        local code, template = GetCharSkillLevelEffectTemplate(skillId, level)
        if code ~= XCode.Success then
            return code
        end

        for _, subSkillId in pairs(template.SubSkillId) do
            local curLevel = levelMap[subSkillId]
            if not curLevel or curLevel < level then
                levelMap[subSkillId] = level
            end
        end
    end

    return XCode.Success
end

--- 魔法等级
--- 1、角色技能加成
local function GetMagicLevel(npcData, levelMap)
    if not npcData.Character then
        return XCode.Success
    end

    local charLevelMap = GetCharSkillLevelMap(npcData)

    for skillId, level in pairs(charLevelMap) do
        local code, template = GetCharSkillLevelEffectTemplate(skillId, level)
        if code ~= XCode.Success then
            return code
        end

        for _, subMagicId in pairs(template.SubMagicId) do
            local curLevel = levelMap[subMagicId]
            if not curLevel or curLevel < level then
                levelMap[subMagicId] = level
            end
        end
    end

    return XCode.Success
end

--- 出生魔法属性等级
--- 1、角色技能加成
--- 2、共鸣提供加成
local function GetBornMagicLevel(npcData, levelMap)
    if not npcData.Character then
        return XCode.Success
    end

    local charLevelMap = GetCharSkillLevelMap(npcData)

    for skillId, level in pairs(charLevelMap) do
        local code, template = GetCharSkillLevelEffectTemplate(skillId, level)
        if code ~= XCode.Success then
            return code
        end

        for _, magic in pairs(template.BornMagic) do
            local curLevel = levelMap[magic]
            if not curLevel or curLevel < level then
                levelMap[magic] = level
            end
        end
    end

    return XCode.Success
end

function XFightCharacterManager.GetNpcId(characterData)
    local code, qualityTemplate = GetQualityTemplate(characterData.Id, characterData.Quality)
    if code ~= XCode.Success then
        return code, 0
    end

    return XCode.Success, qualityTemplate.NpcId
end

local function RegisterInterfaces()
    XAttribManager.RegisterNumericIdInterface(AddNumericAttribId)

    XMagicSkillManager.RegisterResonanceSkillLevelInterface(GetResonanceSkillLevelMap)
    XMagicSkillManager.RegisterSkillLevelInterface(GetSkillLevel)
    XMagicSkillManager.RegisterMagicLevelInterface(GetMagicLevel)
    XMagicSkillManager.RegisterBornMagicLevelInterface(GetBornMagicLevel)
end

function XFightCharacterManager.Init()
    Awake()
    RegisterInterfaces()
end

XFightCharacterManager.GetCharSkillLevelMap = GetCharSkillLevelMap
XFightCharacterManager.GetResonanceSkillLevelMap = GetResonanceSkillLevelMap