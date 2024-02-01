XSameColorGameConfigs = XSameColorGameConfigs or {}

-- 配置表
local SHARE_TABLE_PATH = "Share/SameColorGame/"
local CLIENT_TABLE_PATH = "Client/SameColorGame/"
-- share
local TABLE_ACTIVITY = SHARE_TABLE_PATH .. "SameColorGameActivity.tab"
local TABLE_BALL = SHARE_TABLE_PATH .. "SameColorGameBall.tab"
local TABLE_BOSS = SHARE_TABLE_PATH .. "SameColorGameBoss.tab"
local TABLE_BOSS_GRADE = SHARE_TABLE_PATH .. "SameColorGameBossGrade.tab"
local TABLE_COMBO = SHARE_TABLE_PATH .. "SameColorGameCombo.tab"
local TABLE_ROLE = SHARE_TABLE_PATH .. "SameColorGameRole.tab"
local TABLE_SCORE = SHARE_TABLE_PATH .. "SameColorGameScore.tab"
local TABLE_SKILL = SHARE_TABLE_PATH .. "SameColorGameSkill.tab"
local TABLE_SKILL_GROUP = SHARE_TABLE_PATH .. "SameColorGameSkillGroup.tab"
local TABLE_BOSS_SKILL = SHARE_TABLE_PATH .. "SameColorGameBossSkill.tab"
local TABLE_BUFF = SHARE_TABLE_PATH .. "SameColorGameBuff.tab"
local TABLE_PASSIVE_SKILL = SHARE_TABLE_PATH .. "SameColorGamePassiveSkill.tab"

-- 变量
local ActivityConfigDic
local BossConfigDic
local BossGradeDicConfig
local RoleConfigDic
local BallConfigDic
local SkillConfigDic
local SkillGroupConfigDic
local BossSkillConfigDic
local BuffConfigDic

function XSameColorGameConfigs.Init()
    local xTableManager = XTableManager
    local xTable = XTable
    -- 活动
    ActivityConfigDic = xTableManager.ReadByIntKey(TABLE_ACTIVITY, xTable.XTableSameColorGameActivity, "Id")
    -- boss
    BossConfigDic = xTableManager.ReadByIntKey(TABLE_BOSS, xTable.XTableSameColorGameBoss, "Id")
    -- boss分数等级配置信息
    local bossGradeConfigDic = xTableManager.ReadByIntKey(TABLE_BOSS_GRADE, xTable.XTableSameColorGameBossGrade, "Id")
    
    BossGradeDicConfig = {}
    for id, config in pairs(bossGradeConfigDic) do
        BossGradeDicConfig[config.BossId] = BossGradeDicConfig[config.BossId] or {}
        table.insert(BossGradeDicConfig[config.BossId], config)
    end
    for id, configs in pairs(BossGradeDicConfig) do
        table.sort(configs, function(configA, configB)
                return configA.Damage < configB.Damage
            end)
    end
    -- 角色配置相关
    RoleConfigDic = xTableManager.ReadByIntKey(TABLE_ROLE, xTable.XTableSameColorGameRole, "Id")
    -- 球配置
    BallConfigDic = xTableManager.ReadByIntKey(TABLE_BALL, xTable.XTableSameColorGameBall, "Id")
    -- 技能
    SkillConfigDic = xTableManager.ReadByIntKey(TABLE_SKILL, xTable.XTableSameColorGameSkill, "Id")
    -- 技能组
    SkillGroupConfigDic = xTableManager.ReadByIntKey(TABLE_SKILL_GROUP, xTable.XTableSameColorGameSkillGroup, "Id")
    -- boss技能详情
    BossSkillConfigDic = xTableManager.ReadByIntKey(TABLE_BOSS_SKILL, xTable.XTableSameColorGameBossSkill, "Id")
    -- buff
    BuffConfigDic = xTableManager.ReadByIntKey(TABLE_BUFF, xTable.XTableSameColorGameBuff, "Id")
end

-- 获取当前活动配置表
---@return XTableSameColorGameActivity
function XSameColorGameConfigs.GetCurrentConfig()
    local defaultConfig
    for _, config in pairs(ActivityConfigDic) do
        defaultConfig = config
        if config.TimerId > 0 then
            return config
        end
    end
    return defaultConfig
end

-- 根据id获取对应的boss配置
---@return XTableSameColorGameBoss
function XSameColorGameConfigs.GetBossConfig(id)
    if not BossConfigDic[id] then
        XLog.ErrorTableDataNotFound(
            "SameColorGameConfigs.GetBossConfig",
            "Boss配置字段_Id",
            TABLE_BOSS,
            "Id",
            tostring(id))
    end
    return BossConfigDic[id]
end

-- 获取所有boss配置表
function XSameColorGameConfigs.GetBossConfigDic()
    return BossConfigDic
end

-- 根据bossId和分数获取对应的评价等级名称
function XSameColorGameConfigs.GetBossGradeName(bossId, score)
    local configs = BossGradeDicConfig[bossId]
    if not configs then
        XLog.ErrorTableDataNotFound(
            "SameColorGameConfigs.GetBossGradeName",
            "BossGrade配置字段_Id",
            TABLE_BOSS_GRADE,
            "Id",
            tostring(bossId))
    end
    local config
    for i = #configs, 1, -1 do
        config = configs[i]
        if score >= config.Damage then
            return config.GradeName
        end
    end
    return configs[1].GradeName
end

-- 根据bossId和分数获取对应的评价等级名称
function XSameColorGameConfigs.GetBossGradeIndex(bossId, score)
    local configs = BossGradeDicConfig[bossId]
    if not configs then
        XLog.ErrorTableDataNotFound(
            "SameColorGameConfigs.GetBossGradeIndex",
            "BossGrade配置字段_Id",
            TABLE_BOSS_GRADE,
            "Id",
            tostring(bossId))
    end
    local config
    for i = #configs, 1, -1 do
        config = configs[i]
        if score >= config.Damage then
            return config.Grade
        end
    end
    return configs[1].Grade
end

function XSameColorGameConfigs.GetBossGradeDic(bossId)
    local configs = BossGradeDicConfig[bossId]
    if not configs then
        XLog.ErrorTableDataNotFound(
            "SameColorGameConfigs.GetBossGradeName",
            "BossGrade配置字段_Id",
            TABLE_BOSS_GRADE,
            "Id",
            tostring(bossId))
    end
    return configs
end

-- 根据bossId和分数获取对应的下一级评价等级名称以及分差
function XSameColorGameConfigs.GetScoreNextGradeNameAndDamageGap(bossId, score)
    local configs = BossGradeDicConfig[bossId]
    if not configs then
        XLog.ErrorTableDataNotFound(
            "SameColorGameConfigs.GetBossNextGradeName",
            "BossGrade配置字段_Id",
            TABLE_BOSS_GRADE,
            "Id",
            tostring(bossId))
    end
    local config
    local nextConfig
    for i = #configs, 1, -1 do
        config = configs[i]
        nextConfig = configs[i + 1]
        if score >= config.Damage then
            if nextConfig then
                return nextConfig.GradeName, nextConfig.Damage - score
            else
                return config.GradeName, 0
            end
        end
    end
    
    local index = 1
    if configs[2] then
        index = 2
    end
    return configs[index].GradeName, configs[index].Damage - score
end

-- 获取所有角色配置表
function XSameColorGameConfigs.GetRoleConfigDic()
    return RoleConfigDic
end

-- 获取角色配置
function XSameColorGameConfigs.GetRoleConfig(id)
    if not RoleConfigDic[id] then
        XLog.ErrorTableDataNotFound(
            "SameColorGameConfigs.GetRoleConfig",
            "Role配置字段_Id",
            TABLE_ROLE,
            "Id",
            tostring(id))
    end
    return RoleConfigDic[id]
end

-- 获取球的所有配置
function XSameColorGameConfigs.GetBallConfigDic()
    return BallConfigDic
end

-- 根据id获取球的配置
function XSameColorGameConfigs.GetBallConfig(id)
    if not BallConfigDic[id] then
        XLog.ErrorTableDataNotFound(
            "SameColorGameConfigs.GetBallConfig",
            "Ball配置字段_Id",
            TABLE_BALL,
            "Id",
            tostring(id))
    end
    return BallConfigDic[id]
end

function XSameColorGameConfigs.GetSkillConfigDic()
    return SkillConfigDic
end

-- 根据id获取技能的配置
---@return XTableSameColorGameSkill
function XSameColorGameConfigs.GetSkillConfig(id)
    if not SkillConfigDic[id] then
        XLog.ErrorTableDataNotFound(
            "SameColorGameConfigs.GetSkillConfig",
            "Skill配置字段_Id",
            TABLE_SKILL,
            "Id",
            tostring(id))
    end
    return SkillConfigDic[id]
end

function XSameColorGameConfigs.GetSkillType(skillId)
    local cfg = XSameColorGameConfigs.GetSkillConfig(skillId)
    return cfg and cfg.Type
end

function XSameColorGameConfigs.GetSkillGroupConfigDic()
    return SkillGroupConfigDic
end

-- 根据id获取技能的配置
function XSameColorGameConfigs.GetSkillGroupConfig(id)
    if not SkillGroupConfigDic[id] then
        XLog.ErrorTableDataNotFound(
            "SameColorGameConfigs.GetSkillGroupConfig",
            "SkillGroup配置字段_Id",
            TABLE_SKILL_GROUP,
            "Id",
            tostring(id))
    end
    return SkillGroupConfigDic[id]
end

function XSameColorGameConfigs.GetBossSkillConfig(id)
    if not BossSkillConfigDic[id] then
        XLog.ErrorTableDataNotFound(
            "SameColorGameConfigs.GetBossSkillConfig",
            "BossSkill配置字段_Id",
            TABLE_BOSS_SKILL,
            "Id",
            tostring(id))
    end
    return BossSkillConfigDic[id]
end

function XSameColorGameConfigs.GetBuffConfig(id)
    if not BuffConfigDic[id] then
        XLog.ErrorTableDataNotFound(
            "SameColorGameConfigs.GetBuffConfig",
            "Buff配置字段_Id",
            TABLE_BUFF,
            "Id",
            tostring(id))
    end
    return BuffConfigDic[id]
end

function XSameColorGameConfigs.GetBossSkillConfigDic()
    return BossSkillConfigDic
end

function XSameColorGameConfigs.CreatePosKey(x, y)
    if x and y then
        return string.format("%d_%d", x, y)
    else
        return nil
    end
end