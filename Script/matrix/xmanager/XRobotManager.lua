local XRobot = require("XEntity/XRobot/XRobot")

local pairs = pairs
local tableInsert = table.insert
local stringFormat = string.format
local mathFloor = math.floor
local CsXTextManagerGetText = CsXTextManagerGetText

local TABLE_ROBOT = "Share/Robot/Robot.tab"
local TABLE_ROBOT_PARTNER = "Share/Robot/RobotPartner.tab"

local RobotTemplates = {}
local RobotPartnerTemplates = {}
local Robots = {}

XRobotManager = XRobotManager or {}

function XRobotManager.Init()
    RobotTemplates = XTableManager.ReadByIntKey(TABLE_ROBOT, XTable.XTableRobot, "Id")
    RobotPartnerTemplates = XTableManager.ReadByIntKey(TABLE_ROBOT_PARTNER, XTable.XTableRobotPartner, "Id")
end

local function GetRobot(robotId)
    local robot = Robots[robotId]
    if not robot then
        if not XRobotManager.TryGetRobotTemplate(robotId) then
            return
        end
        robot = XRobot.New(robotId)
        Robots[robotId] = robot
    end
    return robot
end

---@return XRobot
function XRobotManager.GetRobotById(robotId)
    return GetRobot(robotId)
end

function XRobotManager.GetConfigPath()
    return TABLE_ROBOT
end

function XRobotManager.CheckRobotExist(robotId)
    if not XTool.IsNumberValid(robotId) then return false end
    return not XTool.IsTableEmpty(RobotTemplates[robotId])
end

function XRobotManager.GetCharacterId(robotId)
    if not XRobotManager.CheckIsRobotId(robotId) then return robotId end
    local charId = 0
    if RobotTemplates[robotId] then
        charId = RobotTemplates[robotId].CharacterId
    end
    return charId
end

function XRobotManager.GetRobotTemplate(robotId)
    if not XTool.IsNumberValid(robotId) then return end

    local config = RobotTemplates[robotId]
    if not config then
        XLog.Error("XRobotManager.GetRobotTemplate error: 配置不存在, robotId: " .. robotId .. ", path: " .. TABLE_ROBOT)
        return
    end
    return config
end

function XRobotManager.TryGetRobotTemplate(robotId)
    if not XTool.IsNumberValid(robotId) then return end
    local config = RobotTemplates[robotId]
    return config
end

function XRobotManager.GetRobotPartnerTemplate(robotPartnerId)
    if not XTool.IsNumberValid(robotPartnerId) then return end

    local config = RobotPartnerTemplates[robotPartnerId]
    if not config then
        XLog.Error("XRobotManager.GetRobotPartnerTemplate error: 配置不存在, robotPartnerId: " .. robotPartnerId .. ", path: " .. TABLE_ROBOT_PARTNER)
        return
    end
    return config
end

--==============================
 ---@desc 判断是否是试用辅助机
 ---@id 辅助机id 
 ---@return boolean
--==============================
function XRobotManager.CheckIsPartnerRobotId(id)
    return XTool.IsNumberValid(id) and id < 10000000
end

function XRobotManager.GetRobotSkillRemoveDic(robotId)
    local removeDic = {}
    local config = XRobotManager.GetRobotTemplate(robotId)
    for _, skillId in pairs(config.RemoveSkillId) do
        if XTool.IsNumberValid(skillId) then
            removeDic[skillId] = skillId
        end
    end
    return removeDic
end

function XRobotManager.GetRobotNpcTemplate(robotId)
    local RobotCfg = RobotTemplates[robotId]
    if not RobotCfg then return end
    local npcId = XCharacterConfigs.GetCharNpcId(RobotCfg.CharacterId, RobotCfg.CharacterQuality)
    local template = XCharacterConfigs.GetNpcTemplate(npcId)
    return template
end

function XRobotManager.GetRobotJobType(robotId)
    local template = XRobotManager.GetRobotNpcTemplate(robotId)
    return template and template.Type or 0
end

function XRobotManager.GetRobotCharacterQuality(robotId)
    local template = XRobotManager.GetRobotTemplate(robotId)
    return template and template.CharacterQuality or 0
end

function XRobotManager.CheckIsRobotId(id)
    return XTool.IsNumberValid(id) and id < 1000000
end

function XRobotManager.GetRobotCharacterType(robotId)
    local characterId = XRobotManager.GetCharacterId(robotId)
    if not XTool.IsNumberValid(characterId) then return end
    return XCharacterConfigs.GetCharacterType(characterId)
end

function XRobotManager.GetRobotCharacterLevel(robotId)
    local template = XRobotManager.GetRobotTemplate(robotId)
    return template and template.CharacterLevel or 0
end

function XRobotManager.CheckIdToCharacterId(id)
    if XRobotManager.CheckIsRobotId(id) then
        return XRobotManager.GetCharacterId(id)
    else
        return id
    end
end

--是否为授格者
function XRobotManager.IsIsomer(robotId)
    local characterId = XRobotManager.GetCharacterId(robotId)
    return XCharacterConfigs.IsIsomer(characterId)
end

function XRobotManager.GetRobotIdFilterListByCharacterType(robotIdList, characterType)
    local filterRobotIdList = {}
    if XTool.IsTableEmpty(robotIdList) then
        return filterRobotIdList
    end

    local robotCharacterType
    local characterId
    for _, robotId in ipairs(robotIdList) do
        characterId = XRobotManager.GetCharacterId(robotId)
        if characterId > 0 then
            robotCharacterType = XCharacterConfigs.GetCharacterType(characterId)
            if characterType then
                if robotCharacterType == characterType then
                    tableInsert(filterRobotIdList, robotId)
                end
            else
                tableInsert(filterRobotIdList, robotId)
            end
            
        end
    end
    return filterRobotIdList
end

---==========================================================
--- 根据‘robotId’获取机器人的头像，如果没有配置时装，则使用默认时装头像
--- 返回的是头像路径
---@param robotId number
---@return string
---==========================================================
function XRobotManager.GetRobotSmallHeadIcon(robotId)
    local robotTemplate = RobotTemplates[robotId]
    if robotTemplate == nil then
        XLog.ErrorTableDataNotFound("XRobotManager.GetRobotSmallHeadIcon", "机器人配置数据", TABLE_ROBOT, "id", tostring(robotId))
        return
    end

    local result
    local fashionId
    local isAchieveMaxLiberation = XDataCenter.ExhibitionManager.IsMaxLiberationLevel(robotTemplate.LiberateLv)

    if robotTemplate.FashionId then
        -- 配置了机器人的FashionId
        fashionId = robotTemplate.FashionId
    else
        -- 默认时装
        local characterId = XRobotManager.GetCharacterId(robotId)
        fashionId = XCharacterConfigs.GetCharacterTemplate(characterId).DefaultNpcFashtionId
    end

    result = isAchieveMaxLiberation and XDataCenter.FashionManager.GetFashionSmallHeadIconLiberation(fashionId) or
    XDataCenter.FashionManager.GetFashionSmallHeadIcon(fashionId)

    return result
end

--==============================--
--desc: 获取机器人队长技能描述
--@robotId: 机器人id
--@return 技能Data
--==============================--
function XRobotManager.GetRobotCaptainSkillInfo(robotId)
    local robotTemplate = XRobotManager.GetRobotTemplate(robotId)
    local captianSkillId = XCharacterConfigs.GetCharacterCaptainSkill(robotTemplate.CharacterId)
    local skillLevel = 1

    return XCharacterConfigs.GetCaptainSkillInfo(robotTemplate.CharacterId, skillLevel)
end

--==============================
 ---@desc 机器人能否使用角色涂装
 ---@robotId 机器人id
 ---@return boolean
--==============================
function XRobotManager.CheckUseFashion(robotId)
    local robotTemplate = RobotTemplates[robotId]
    if not robotTemplate then
        XLog.ErrorTableDataNotFound("XRobotManager.CheckUseFashion", "机器人配置数据", TABLE_ROBOT, "Id", tostring(robotId))
        return
    end
    return XTool.IsNumberValid(robotTemplate.UseFashionId)
end

--desc: 获取机器人队长技能描述
function XRobotManager.GetRobotCaptainSkillDesc(robotId)
    local captianSkillInfo = XRobotManager.GetRobotCaptainSkillInfo(robotId)
    return captianSkillInfo and captianSkillInfo.Level > 0 and captianSkillInfo.Intro or stringFormat("%s%s", captianSkillInfo.Intro, CsXTextManagerGetText("CaptainSkillLock"))
end

--desc: 获取机器人武器涂装
function XRobotManager.GetRobotWeaponFashionId(robotId)
    local config = XRobotManager.GetRobotTemplate(robotId)
    if not config then return end

    local weaponFashionId = config.WeaponFashion
    if not XTool.IsNumberValid(weaponFashionId) then return end

    return weaponFashionId
end

local function GetRobotShowAbility(robotId)
    local template = XRobotManager.GetRobotTemplate(robotId)
    return template and template.ShowAbility or 0
end

function XRobotManager.GetRobotShowAbility(robotId)
    return GetRobotShowAbility(robotId)
end

--获取机器人战力
function XRobotManager.GetRobotAbility(robotId)
    --当配置了展示用战力字段时，直接返回ShowAbility
    local ability = GetRobotShowAbility(robotId)
    if XTool.IsNumberValid(ability) then
        return ability
    end

    --否则获取公式计算值
    local robot = GetRobot(robotId)
    return robot:GetAbility()
end

--获取机器人技能等级字典
--@param forDisplay:是否用于展示
function XRobotManager.GetRobotSkillLevelDic(robotId, forDisplay)
    local robot = GetRobot(robotId)
    return robot:GetSkillLevelDic(forDisplay)
end

--获取机器人原始属性
function XRobotManager.GetRobotAttribs(robotId)
    local robot = GetRobot(robotId)
    return robot:GetAtrributes()
end

--获取机器人宠物
function XRobotManager.GetRobotPartner(robotId)
    local robot = GetRobot(robotId)
    return robot:GetPartner()
end

--获取机器人宠物战力
function XRobotManager.GetRobotPartnerAbility(robotId)
    local partner = XRobotManager.GetRobotPartner(robotId)
    return not XTool.IsTableEmpty(partner) and partner:GetAbility() or 0
end

--获取机器人装备共鸣增加额外属性列表
function XRobotManager.GetRobotResonanceAbilityList(robotId)
    local robot = GetRobot(robotId)
    return robot:ConstructResonanceAbilityList()
end

--获取机器人装备觉醒（超频）增加额外属性列表
function XRobotManager.GetRobotAwakenAbilityList(robotId)
    local robot = GetRobot(robotId)
    return robot:ConstructAwakenAbilityList()
end

--获取机器人属性 + 额外属性
function XRobotManager.GetRobotAttribWithExtraAttrib(robotId, extraAttribIds)
    local robot = GetRobot(robotId)
    local attrs = XTool.Clone(robot:GetAtrributes())
    for _, attribId in pairs(extraAttribIds or {}) do
        XAttribManager.DoAddAttribsByAttrAndAddId(attrs, attribId)
    end
    return attrs
end

--获取一个可以自由设置属性的机器人实体
function XRobotManager.GetRobotTemp(robotId)
    local robot = GetRobot(robotId)
    return XTool.Clone(robot)
end