XDlcHuntSkillConfigs = XDlcHuntSkillConfigs or {}

---@type XConfig
local _ConfigSkill

---@type XConfig
local _ConfigSkillLevelEffect

---@type XConfig
local _ConfigSkillType

---@type XConfig
local _ConfigSkillGate

---@type XConfig
local _ConfigSkillTypeInfo

---@type XConfig
local _ConfigSkillUpgradeDes

---@type XConfig
local _ConfigSkillTeach

function XDlcHuntSkillConfigs.Init()
    _ConfigSkillGate = XConfig.New("Client/DlcHunt/Character/Skill/DlcHuntSkillGate.tab", XTable.XTableDlcHuntSkillGate, "Id")
    _ConfigSkillTypeInfo = XConfig.New("Client/DlcHunt/Character/Skill/DlcHuntSkillTypeInfo.tab", XTable.XTableDlcHuntSkillTypeInfo, "Type")
    _ConfigSkillUpgradeDes = XConfig.New("Client/DlcHunt/Character/Skill/DlcHuntSkillUpgradeDes.tab", XTable.XTableDlcHuntSkillUpgradeDes, "Id")
    _ConfigSkillTeach = XConfig.New("Client/DlcHunt/Character/Skill/DlcHuntSkillTeach.tab", XTable.XTableDlcHuntSkillTeach, "Id")
    _ConfigSkill = XConfig.New("Share/DlcHunt/Character/Skill/DlcHuntCharacterSkill.tab", XTable.XTableDlcHuntCharacterSkill, "CharacterId")
    _ConfigSkillLevelEffect = XConfig.New("Share/DlcHunt/Character/Skill/DlcHuntCharacterSkillLevelEffect.tab", XTable.XTableDlcHuntCharacterSkillLevelEffect, "Id")
    _ConfigSkillType = XConfig.New("Share/DlcHunt/Character/Skill/DlcHuntCharacterSkillType.tab", XTable.XTableDlcHuntCharacterSkillType, "Id")
end

local _DescConfig = false
local function GetSkillDescConfig(skillId)
    if not _DescConfig then
        _DescConfig = {}
        for _, config in pairs(_ConfigSkillUpgradeDes:GetConfigs()) do
            local skillId = config.SkillId
            _DescConfig[skillId] = config
        end
    end
    return _DescConfig[skillId]
end

---@param character XDlcHuntCharacter
function XDlcHuntSkillConfigs.GetData4Display(character)
    local characterId = character:GetCharacterId()
    local skillList = _ConfigSkill:GetProperty(characterId, "SkillIds")
    local posList = _ConfigSkill:GetProperty(characterId, "Pos")

    local skillData = {}

    -- 先分大类
    local gateConfigs = _ConfigSkillGate:GetConfigs()
    for i = 1, #gateConfigs do
        local gate = gateConfigs[i]
        skillData[i] = {
            Name = gate.Name,
            Icon = gate.Icon,
            Skills = {}
        }
    end

    -- 将技能塞进去
    for i = 1, #skillList do
        local skillId = skillList[i]
        local descConfig = GetSkillDescConfig(skillId)
        if descConfig then
            local pos = posList[i]

            local data = skillData[pos]
            if data then
                local list = data.Skills
                --local type = _ConfigSkillType:GetProperty(skillId, "Type")
                --local typeDesc = _ConfigSkillTypeInfo:GetProperty(type, "Name")
                list[#list + 1] = {
                    Name = descConfig.Name,
                    Icon = descConfig.Icon,
                    Title = descConfig.Title,
                    BriefDes = descConfig.BriefDes,
                    SpecificDes = descConfig.SpecificDes,
                    TypeDes = descConfig.TypeDes,
                }
            end
        end
    end

    -- 将空的大类移除
    for i = #skillData, 1, -1 do
        local data = skillData[i]
        if #data.Skills == 0 then
            table.remove(skillData, i)
        end
    end

    return skillData
end
