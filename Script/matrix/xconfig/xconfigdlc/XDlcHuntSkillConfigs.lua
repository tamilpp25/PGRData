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
end

local function __InitConfigSkillGate()
    if not _ConfigSkillGate then
        _ConfigSkillGate = XConfig.New("Client/DlcHunt/Character/Skill/DlcHuntSkillGate.tab", XTable.XTableDlcHuntSkillGate, "Id")
    end
end

local function __InitConfigSkillTypeInfo()
    if not _ConfigSkillTypeInfo then
        _ConfigSkillTypeInfo = XConfig.New("Client/DlcHunt/Character/Skill/DlcHuntSkillTypeInfo.tab", XTable.XTableDlcHuntSkillTypeInfo, "Type")
    end
end

local function __InitConfigSkillUpgradeDes()
    if not _ConfigSkillUpgradeDes then
        _ConfigSkillUpgradeDes = XConfig.New("Client/DlcHunt/Character/Skill/DlcHuntSkillUpgradeDes.tab", XTable.XTableDlcHuntSkillUpgradeDes, "Id")
    end
end

local function __InitConfigSkillTeach()
    if not _ConfigSkillTeach then
        _ConfigSkillTeach = XConfig.New("Client/DlcHunt/Character/Skill/DlcHuntSkillTeach.tab", XTable.XTableDlcHuntSkillTeach, "Id")
    end
end

local function __InitConfigSkill()
    if not _ConfigSkill then
        _ConfigSkill = XConfig.New("Share/DlcHunt/Character/Skill/DlcHuntCharacterSkill.tab", XTable.XTableDlcHuntCharacterSkill, "CharacterId")
    end
end

local function __InitConfigSkillType()
    if not _ConfigSkillType then
        _ConfigSkillType = XConfig.New("Share/DlcHunt/Character/Skill/DlcHuntCharacterSkillType.tab", XTable.XTableDlcHuntCharacterSkillType, "Id")
    end
end

local function __InitConfigSkillLevelEffect()
    if not _ConfigSkillLevelEffect then
        _ConfigSkillLevelEffect = XConfig.New("Share/DlcHunt/Character/Skill/DlcHuntCharacterSkillLevelEffect.tab", XTable.XTableDlcHuntCharacterSkillLevelEffect, "Id")
    end
end

local _DescConfig = false
local function GetSkillDescConfig(skillId)
    __InitConfigSkillUpgradeDes()
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
    __InitConfigSkill()
    local characterId = character:GetCharacterId()
    local skillList = _ConfigSkill:GetProperty(characterId, "SkillIds")
    local posList = _ConfigSkill:GetProperty(characterId, "Pos")

    local skillData = {}

    -- 先分大类
    __InitConfigSkillGate()
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
