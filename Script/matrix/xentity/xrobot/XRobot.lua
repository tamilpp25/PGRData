local type = type
local tonumber = tonumber
local mathFloor = math.floor
local stringSplit = string.Split
local tableInsert = table.insert
local XCharacterViewModel = require("XEntity/XCharacter/XCharacterViewModel")
local XWeaponViewModel = require("XEntity/XEquip/XWeaponViewModel")
local XAwarenessViewModel = require("XEntity/XEquip/XAwarenessViewModel")
local XPartner = require("XEntity/XPartner/XPartner")
local XPartnerMainSkillGroup = require("XEntity/XPartner/XPartnerMainSkillGroup")
---@class XRobot
local XRobot = XClass(nil, "XRobot")

local Default = {
    Id = 0,
    Ability = 0,
    CharacterId = 0,
    Character = {},
    Equips = {},
    Partner = {},
    Attribs = {},
    NpcData = {}
}

function XRobot:Ctor(id)
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end

    self.Id = id
    -- XCharacterViewModel
    self.CharacterViewModel = nil
    -- XWeaponViewModel
    self.WeaponViewModel = nil
    -- XAwarenessViewModel dic
    self.AwarenessViewModelDic = nil
    self:Init()
end

function XRobot:Init()
    self:InitBase()
    self:InitCharacter()
    self:InitEquips()
    self:InitPartner()
    self:UpdateAttribs()
    self:UpdateAbility()
end

function XRobot:InitBase()
    local robotId = self.Id
    local robotCfg = XRobotManager.GetRobotTemplate(robotId)

    self.CharacterId = robotCfg.CharacterId
end

function XRobot:InitCharacter()
    local robotId = self.Id
    local robotCfg = XRobotManager.GetRobotTemplate(robotId)

    self.Character = {
        Id = robotCfg.CharacterId,
        Quality = robotCfg.CharacterQuality,
        Level = robotCfg.CharacterLevel,
        Grade = robotCfg.CharacterGrade,
        Star = robotCfg.CharacterStar,
        SkillList = self:GenarateRobotSkillList(),
        EnhanceSkillList = self:GenarateRobotEnhanceSkillList(),
    }
end

function XRobot:InitEquips()
    local equips = {}

    local robotId = self.Id
    local robotCfg = XRobotManager.GetRobotTemplate(robotId)

    --武器
    if XTool.IsNumberValid(robotCfg.WeaponId) then
        local weapon = {
            TemplateId = robotCfg.WeaponId,
            Level = robotCfg.WeaponLevel,
            Breakthrough = robotCfg.WeaponBeakThrough,
            ResonanceInfo = self:GenarateRobotEquipResonanceInfo()
        }
        tableInsert(equips, weapon)
    end

    --意识
    for _, pos in pairs(XEquipConfig.EquipSite.Awareness) do
        local equipId = robotCfg.WaferId[pos]

        if XTool.IsNumberValid(equipId) then
            local newAware = {
                TemplateId = equipId,
                Level = robotCfg.WaferLevel[pos],
                Breakthrough = robotCfg.WaferBreakThrough[pos],
                ResonanceInfo = self:GenarateRobotEquipResonanceInfo(pos),
                AwakeSlotList = self:GenarateRobotAwakeSlotList(pos),
                __SlotPos = pos
            }
            tableInsert(equips, newAware)
        end
    end

    self.Equips = equips
end

local CreatePartnerSkillData = function(robotPartnerCfg, charId) --未配技能置项均为默认值
    local skillList = {}
    local unlockSkillGroup = {}
    local mainSkillGroup = robotPartnerCfg.MainSkillGroup
    local mainskill = XPartnerMainSkillGroup.New(robotPartnerCfg.MainSkillGroup)
    local charElement = XCharacterConfigs.GetCharacterElement(charId)
    local mainskillId = mainskill:GetSkillIdByElement(charElement)

    local tmpData = {
        Type = XPartnerConfigs.SkillType.MainSkill,
        Level = robotPartnerCfg.MainSkillLevel,
        IsWear = true,
        Id = mainskillId
    }
    table.insert(skillList, tmpData)
    table.insert(unlockSkillGroup, mainskillId)

    for index, skillId in pairs(robotPartnerCfg.PassiveSkillId) do
        local tmpData = {
            Type = XPartnerConfigs.SkillType.PassiveSkill,
            Level = robotPartnerCfg.PassiveSkillLevel[index] or 1,
            IsWear = true,
            Id = skillId
        }
        table.insert(skillList, tmpData)
    end

    return skillList, unlockSkillGroup
end

function XRobot:InitPartner()
    local robotId = self.Id
    local robotCfg = XRobotManager.GetRobotTemplate(robotId)

    if robotCfg.RobotPartnerId and robotCfg.RobotPartnerId > 0 then
        local robotPartnerCfg = XRobotManager.GetRobotPartnerTemplate(robotCfg.RobotPartnerId)

        self.Partner = XPartner.New(robotCfg.RobotPartnerId, robotPartnerCfg.PartnerId, true)
        local skillList, unlockSkillGroup = CreatePartnerSkillData(robotPartnerCfg, robotCfg.CharacterId)
        local tmpData = {
            CharacterId = robotCfg.CharacterId,
            Level = robotPartnerCfg.Level,
            BreakThrough = robotPartnerCfg.BreakThrough,
            Quality = robotPartnerCfg.Quality,
            StarSchedule = robotPartnerCfg.StarSchedule,
            SkillList = skillList,
            UnlockSkillGroup = unlockSkillGroup
        }

        self.Partner:UpdateData(tmpData)
    end
end

function XRobot:UpdateAttribs()
    local npcData = self:GetNpcData()
    self.Attribs = XAttribManager.GetNpcAttribs(npcData)
end

function XRobot:UpdateAbility()
    local robotId = self.Id
    local characterId = self.CharacterId
    local npcData = self:GetNpcData()

    --属性战力
    local baseAbility = XAttribManager.GetAttribAbility(self.Attribs) or 0

    --构建机器人技能数据
    local skillData = XFightCharacterManager.GetCharSkillLevelMap(npcData)
    local skillAbility = XDataCenter.CharacterManager.GetSkillAbility(skillData)

    --装备共鸣战力
    local resonanceSkillLevel = XFightCharacterManager.GetResonanceSkillLevelMap(npcData)
    local resonanceSkillAbility = XDataCenter.CharacterManager.GetResonanceSkillAbility(resonanceSkillLevel, skillData)

    --装备技能战力
    local equipAbility = XDataCenter.EquipManager.GetEquipSkillAbilityOther(self.Character, self.Equips)

    --伙伴战力
    local partnerAbility =
        not XTool.IsTableEmpty(self.Partner) and XDataCenter.PartnerManager.GetCarryPartnerAbility(self.Partner) or 0

    self.Ability = mathFloor(baseAbility + skillAbility + resonanceSkillAbility + equipAbility + partnerAbility)
end
function XRobot:GetConfig()
    return XRobotManager.GetRobotTemplate(self.Id)
end

------------属性生成 begin----------------
--武器/意识共鸣列表
function XRobot:GenarateRobotEquipResonanceInfo(pos)
    local resonanceList = {}

    local robotId = self.Id
    local config = XRobotManager.GetRobotTemplate(robotId)

    local configResonance, configResonanceType
    if pos then
        configResonanceType = config.WaferResonanceType[pos]
        configResonance = config.WaferResonance[pos]
    else
        configResonanceType = config.WeaponResonanceType
        configResonance = config.WeaponResonance
    end

    local templateIdList = stringSplit(configResonance)
    local resonanceTypeList = stringSplit(configResonanceType)

    for slot, templateId in pairs(templateIdList) do
        templateId = tonumber(templateId)
        local resonanceType = tonumber(resonanceTypeList[slot])

        if not XTool.IsNumberValid(templateId) or not XTool.IsNumberValid(resonanceType) then
            local path = XRobotManager.GetConfigPath()
            XLog.Error(
                "XRobot:GenarateRobotEquipResonanceInfo error: 机器人共鸣类型（WaferResonanceType）与共鸣技能Id（WaferResonance）不匹配, robotId: " ..
                    robotId .. ", path: " .. path
            )
            break
        end

        local resonanceInfo = {
            Slot = slot,
            Type = resonanceType,
            CharacterId = config.CharacterId,
            TemplateId = templateId
        }
        tableInsert(resonanceList, resonanceInfo)
    end

    return resonanceList
end

--意识觉醒列表
function XRobot:GenarateRobotAwakeSlotList(pos)
    local awakenSlotList = {}

    local robotId = self.Id
    local config = XRobotManager.GetRobotTemplate(robotId)

    local waferAwekenCount = config.WaferAwakeCount[pos]
    for slot = 1, waferAwekenCount do
        tableInsert(awakenSlotList, slot)
    end

    return awakenSlotList
end

--技能列表
--@param needMaxMin:是否要读取适用技能等级上下限
function XRobot:GenarateRobotSkillList()
    local skillList = {}

    local robotId = self.Id
    local config = XRobotManager.GetRobotTemplate(robotId)
    local removeDic = XRobotManager.GetRobotSkillRemoveDic(robotId)
    local characterId = XRobotManager.GetCharacterId(robotId)
    local robotSkillLevel = config.SkillLevel

    local skillDic = XCharacterConfigs.GetChracterSkillPosToGroupIdDic(characterId)
    for _, skillGroup in pairs(skillDic) do
        for _, skillGroupId in pairs(skillGroup) do
            local skillIds = XCharacterConfigs.GetGroupSkillIdsByGroupId(skillGroupId)

            local skillId = skillIds[1]
            if XTool.IsNumberValid(skillId) and not removeDic[skillId] then
                local skillInfo = {
                    Id = skillId,
                    Level = XCharacterConfigs.ClampSubSkillLeveByLevel(skillId, robotSkillLevel)
                }
                tableInsert(skillList, skillInfo)
            end
        end
    end

    return skillList
end

--增强技能列表
function XRobot:GenarateRobotEnhanceSkillList()
    local enhanceSkillList = {}

    local robotId = self.Id
    local config = XRobotManager.GetRobotTemplate(robotId)
    local removeDic = XRobotManager.GetRobotSkillRemoveDic(robotId)
    local characterId = XRobotManager.GetCharacterId(robotId)
    local robotEnhanceSkillLevel = config.EnhanceSkillLevel

    local groupIdList = XCharacterConfigs.GetEnhanceSkillConfig(characterId).SkillGroupId
    for _, skillGroupId in pairs(groupIdList or {}) do
        local groupConfig = XCharacterConfigs.GetEnhanceSkillGroupConfig(skillGroupId)

        local skillId = groupConfig.SkillId[1]
        if XTool.IsNumberValid(skillId) and not removeDic[skillId] then
            local maxLevel = XCharacterConfigs.GetEnhanceSkillMaxLevelBySkillId(skillId)
            local skillInfo = {
                Id = skillId,
                Level = math.min(maxLevel,robotEnhanceSkillLevel)
            }
            tableInsert(enhanceSkillList, skillInfo)
        end
    end

    return enhanceSkillList
end
------------属性生成 end----------------
------------外部Setter接口（需调用后XRobotManager.GetRobotTemp再使用） begin----------------
function XRobot:SetEquips(equips)
    self.Equips = equips

    self:UpdateAttribs()
    self:UpdateAbility()
end

function XRobot:SetPartner(partner)
    self.Partner = partner

    self:UpdateAbility()
end
------------外部Setter接口（需调用后XRobotManager.GetRobotTemp再使用） end----------------
------------外部Getter接口 begin----------------
function XRobot:GetNpcData()
    local npcData = {
        Character = self.Character,
        Equips = self.Equips
    }
    return npcData
end

function XRobot:GetAtrributes()
    return self.Attribs
end

function XRobot:GetAbility()
    return self.Ability or 0
end

--生成装备共鸣增加额外属性列表（Debug调试用）
function XRobot:ConstructResonanceAbilityList()
    local list = {}

    for _, equip in pairs(self.Equips) do
        local infoList = equip.ResonanceInfo
        if not XTool.IsTableEmpty(infoList) then
            for _, info in pairs(infoList) do
                if tonumber(info.Type) == tonumber(XEquipConfig.EquipResonanceType.Attrib) then
                    local _, attrs = XAttribManager.GetAttribGroupTemplate(info.TemplateId)
                    tableInsert(
                        list,
                        {
                            EquipId = equip.Id,
                            Site = XDataCenter.EquipManager.GetEquipSiteByEquipData(equip),
                            Slot = info.Slot,
                            Attr = attrs
                        }
                    )
                end
            end
        end
    end

    return list
end

--生成装备觉醒（超频）增加额外属性列表（Debug调试用）
function XRobot:ConstructAwakenAbilityList()
    local list = {}

    for _, equip in pairs(self.Equips) do
        local infoList = equip.AwakeSlotList
        if not XTool.IsTableEmpty(infoList) then
            local template = XEquipConfig.GetEquipAwakeCfg(equip.TemplateId)
            for _, slot in pairs(infoList) do
                local attribId = template.AttribId[slot]
                local _, attrs = XAttribManager.GetAttribByAttribId(attribId)
                tableInsert(
                    list,
                    {
                        EquipId = equip.Id,
                        Site = XDataCenter.EquipManager.GetEquipSiteByEquipData(equip),
                        Slot = slot,
                        Attr = attrs
                    }
                )
            end
        end
    end

    return list
end

function XRobot:GetSkillLevelDic(forDisplay)
    if forDisplay and (not self.Character.DisplaySkillList) then
        self.Character.DisplaySkillList = self:GenarateRobotSkillList()
    end
    local skillLevelDic = {}
    for _, skillData in pairs(forDisplay and self.Character.DisplaySkillList or self.Character.SkillList) do
        skillLevelDic[skillData.Id] = skillData.Level
    end
    return skillLevelDic
end

---机器人单独技能等级
---于v2.4添加,由于升阶拆分更改了核心被动技能等级robot表又只有一个字段控制所有技能
---导致个别玩法机器人SS品质配1级技能却没有升阶拆分的技能,因此添加了字段单独配置某个技能的等级供其他玩法使用
---目前用到:肉鸽1期
function XRobot:GetAfterSpSkillLevel(skillId)
    local robotId = self.Id
    local config = XRobotManager.GetRobotTemplate(robotId)
    local skillList = config.SpSkillIds
    local skillLevelList = config.SpSkillLevels
    if XTool.IsTableEmpty(skillList) or XTool.IsTableEmpty(skillLevelList) then
        return false
    end
    local index = table.indexof(skillList, skillId)
    if index then
        return XCharacterConfigs.ClampSubSkillLeveByLevel(skillId, skillLevelList[index])
    end
    return false
end

function XRobot:GetPartner()
    if self.Partner ~= nil and next(self.Partner) == nil then
        return nil
    end
    return self.Partner
end

-- 优先获取展示的机器人战力
function XRobot:GetAbilityWithCheckShowAbility()
    local ability = XRobotManager.GetRobotShowAbility(self.Id)
    if XTool.IsNumberValid(ability) then
        return ability
    end
    return self:GetAbility()
end

function XRobot:GetId()
    return self.Id
end

function XRobot:GetCharacterId()
    return XRobotManager.GetCharacterId(self.Id)
end
------------外部Getter接口 end----------------
------------ 视图数据 begin----------------
function XRobot:GetCharacterViewModel()
    if self.CharacterViewModel == nil then
        local robotConfig = XRobotManager.GetRobotTemplate(self.Id)
        self.CharacterViewModel = XCharacterViewModel.New(robotConfig.CharacterId)
        self.CharacterViewModel:UpdateWithData(self.Character)
        self.CharacterViewModel:UpdateAbility(self:GetAbilityWithCheckShowAbility())
        self.CharacterViewModel:UpdateFashionId(robotConfig.FashionId)
        self.CharacterViewModel:UpdateLiberateLv(robotConfig.LiberateLv)
        self.CharacterViewModel:UpdateSourceEntityId(self.Id)
    end
    return self.CharacterViewModel
end

function XRobot:GetWeaponViewModel()
    if self.WeaponViewModel == nil then
        local templateId = nil
        for _, euqipData in pairs(self.Equips) do
            templateId = euqipData.TemplateId
            if XDataCenter.EquipManager.IsClassifyEqualByTemplateId(templateId, XEquipConfig.Classify.Weapon) then
                self.WeaponViewModel = XWeaponViewModel.New(templateId)
                self.WeaponViewModel:UpdateWithData(euqipData)
                break
            end
        end
    end
    return self.WeaponViewModel
end

function XRobot:GetAwarenessViewModelDic()
    if self.AwarenessViewModelDic == nil then
        self.AwarenessViewModelDic = {}
        local templateId = nil
        for _, euqipData in pairs(self.Equips) do
            templateId = euqipData.TemplateId
            if XDataCenter.EquipManager.IsClassifyEqualByTemplateId(templateId, XEquipConfig.Classify.Awareness) then
                self.AwarenessViewModelDic[euqipData.__SlotPos] = XAwarenessViewModel.New(templateId)
                self.AwarenessViewModelDic[euqipData.__SlotPos]:UpdateWithData(euqipData)
            end
        end
    end
    return self.AwarenessViewModelDic
end

function XRobot:GetEquipViewModels()
    local result = {self:GetWeaponViewModel()}
    for _, v in pairs(self:GetAwarenessViewModelDic()) do
        table.insert(result, v)
    end
    return result
end
------------ 视图数据 end----------------
return XRobot
