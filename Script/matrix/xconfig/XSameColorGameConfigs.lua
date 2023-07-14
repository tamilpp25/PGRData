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

-- client
local TABLE_CLIENT_CONFIG = CLIENT_TABLE_PATH .. "SameColorGameCfg.tab"
local TABLE_CLIENT_BATTLESHOW_ROLE = CLIENT_TABLE_PATH .. "BattleShowRole.tab"

-- 变量
local ActivityConfigDic
local ActivityValueConfig
local BossConfigDic
local BossGradeDicConfig
local RoleConfigDic
local BallConfigDic
local SkillConfigDic
local SkillGroupConfigDic
local BossSkillConfigDic
local BuffConfigDic
local PassiveSkillConfigDic
local BattleShowRoleDic

XSameColorGameConfigs.UiBossChildPanelType = {
    Main = 1, -- 主页面
    Boss = 2, -- Boss详情
    Role = 3, -- 角色详情
    Ready = 4, -- 角色技能
}

XSameColorGameConfigs.BattleCameraType = {
    Standby = 1, -- 待机
    Combat = 2, -- 战斗
}

XSameColorGameConfigs.BallState = {
    Stop = 1, -- 停止
    Moving = 2, -- 移动中
    Showing = 3, -- 表演中
}

XSameColorGameConfigs.TaskType = {
    Day = 1,    -- 日常任务
    Reward = 2, -- 奖励任务
}

XSameColorGameConfigs.ActionType = {
    ActionNone = 0,
    ActionMapInit = 1,--地图初始化
    ActionItemRemove = 2,--消除
    ActionItemDrop = 3,--下落
    ActionItemCreateNew = 4,--新增
    ActionShuffle = 5,--洗牌
    ActionGameInterrupt = 6,--游戏中断
    ActionSettleScore = 7,--分数结算
    ActionSwap = 8,--交换球
    ActionAddStep = 9,--增加步数
    ActionSubStep = 10,--减少步数
    ActionChangeColor = 11,--改变颜色
    ActionAddBuff = 12,--增加buff
    ActionRemoveBuff = 13,--删除buff
    ActionBossReleaseSkill = 14,--boss释放技能
    ActionBossSkipSkill = 15,--boss跳过技能
    ActionEnergyChange = 16,--能量改变
    ActionCdChange = 17,--技能cd改变
    ActionLeftTimeChange = 18,--关卡剩余时间改变
    ActionBuffLeftTimeChange = 19,--buff剩余时间改变
    ActionMapReset = 20,--棋盘重置
}

XSameColorGameConfigs.ScreenMaskType = {--技能准备时的黑幕类型
    None = 0, -- 直接释放
    Condition = 1, --指向条件栏（回合数，伤害，评分）
    Board = 2,--指向棋盘
    Buff = 3,--指向Buff栏
    Energy = 4,--指向能量栏
    Skill = 5,--指向技能栏
    Popup = 6,--指向弹窗
}

XSameColorGameConfigs.ControlType = {--技能准备时的触发方式
    None = 0,--无
    ClickBall = 1,--选择球触发
    ClickPopup = 2,--选择弹窗选定触发
    ClickTwoBall = 3,--选择两球触发
}

XSameColorGameConfigs.BallColor = {
    RedAttack = 1,
    YellowAttack = 2,
    BlueAttack = 3,
    NormalAttack = 4,
}

XSameColorGameConfigs.BuffType = {
    None = 0,
    AddStep = 1,
    SubStep = 2,
    AddDamage = 3,
    SubDamage = 4,
    NoDamage = 5,
}

XSameColorGameConfigs.EnergyChangeType = {
    Add = 1,
    Percent = 2,
}

XSameColorGameConfigs.EnergyChangeFrom = {
    UseSkill = 1,--使用充能技能
    Boss = 2,--被boss攻击
    Combo = 3,--连击
    Buff = 4,--buff/技能效果
    Round = 5,--每回合环境造成
}

-- v1.31 三期爆炸技能，消球Action中球类型
XSameColorGameConfigs.BallRemoveType = {
    None = 0, -- 默认
    BoomCenter = 1, -- 技能爆炸中心
}

-- 需要先开启再使用的技能，则第一次点击球是开启技能，后续的点击为使用技能
XSameColorGameConfigs.NeedOpenSkill = {
    [405] = true,
}

-- 动画不阻塞的技能
XSameColorGameConfigs.AnimNotMaskSkill = {
    [405] = true,
}

-- 常驻显示选中特效的球
XSameColorGameConfigs.ShowSelectEffectBall = {
    [1000] = true,
}

XSameColorGameConfigs.SkillComboType =
{
    Default = 0, 
    Once = 1, -- 触发即释放一次技能，根据本次combo数确定动画
}

XSameColorGameConfigs.Sound = 
{
    BattleBg = 223,
    SwapBall = 2989,
    RemoveBall = 2990,
}

-- 角色最大装备技能数量
XSameColorGameConfigs.RoleMaxSkillCount = 3
-- 排行榜百分比显示限制阈值
XSameColorGameConfigs.PercRankLimit = 100
-- 上榜最大人数
XSameColorGameConfigs.MaxTopRankCount = 100
-- 特殊排名阈值
XSameColorGameConfigs.MaxSpecialRankIndex = 3
-- 消球表现的时间
XSameColorGameConfigs.BallRemoveTime = 0.3
-- 重置棋盘、使用技能扣除能量 的阻塞时间
XSameColorGameConfigs.UseSkillMaskTime = 0.5

function XSameColorGameConfigs.Init()
    local xTableManager = XTableManager
    local xTable = XTable
    -- 活动
    ActivityConfigDic = xTableManager.ReadByIntKey(TABLE_ACTIVITY, xTable.XTableSameColorGameActivity, "Id")
    ActivityValueConfig = xTableManager.ReadByStringKey(TABLE_CLIENT_CONFIG, xTable.XTableSameColorGameCfg, "Key")
    -- boss
    BossConfigDic = xTableManager.ReadByIntKey(TABLE_BOSS, xTable.XTableSameColorGameBoss, "Id")
    -- boss分数等级配置信息
    local bossGradeConfigDic = xTableManager.ReadByIntKey(TABLE_BOSS_GRADE, xTable.XTableSameColorGameBossGrade, "Id")
    local bossGradeConfig
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
    --buff
    BuffConfigDic = xTableManager.ReadByIntKey(TABLE_BUFF, xTable.XTableSameColorGameBuff, "Id")
    -- 被动技能
    PassiveSkillConfigDic = xTableManager.ReadByIntKey(TABLE_PASSIVE_SKILL, xTable.XTableSameColorGamePassiveSkill, "Id") 

    BattleShowRoleDic = xTableManager.ReadByStringKey(TABLE_CLIENT_BATTLESHOW_ROLE, xTable.XTableUiBattleShowRole, "ModelId")
end

-- 获取当前活动配置表
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

function XSameColorGameConfigs.GetActivityConfigValue(key)
    if not ActivityValueConfig[key] then
        XLog.ErrorTableDataNotFound(
            "SameColorGameConfigs.GetActivityConfigValue",
            "客户端配置字段_Key",
            TABLE_CLIENT_CONFIG,
            "Key",
            tostring(key))
    end
    return ActivityValueConfig[key].Values
end

-- 根据id获取对应的boss配置
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

function XSameColorGameConfigs.GetBattleShowRoleConfig(id)
    if not BattleShowRoleDic[id] then
        XLog.ErrorTableDataNotFound(
            "SameColorGameConfigs.GetBattleShowRoleConfig",
            "BattleShowRole配置字段_ModelId",
            TABLE_CLIENT_BATTLESHOW_ROLE,
            "ModelId",
            id)
    end
    return BattleShowRoleDic[id]
end

function XSameColorGameConfigs.CreatePosKey(x, y)
    if x and y then
        return string.format("%d_%d", x, y)
    else
        return nil
    end
end

function XSameColorGameConfigs.CheckPosIsAdjoin(posA, posB)
    local adjoinX = false
    local adjoinY = false
    local sameX = false
    local sameY = false
    if posA.PositionX == posB.PositionX + 1 or posA.PositionX == posB.PositionX - 1 then
        adjoinX = true
    end
    if posA.PositionY == posB.PositionY + 1 or posA.PositionY == posB.PositionY - 1 then
        adjoinY = true
    end
    if posA.PositionX == posB.PositionX then
        sameX = true
    end
    if posA.PositionY == posB.PositionY then
        sameY = true
    end
    return (adjoinX and sameY) or (adjoinY and sameX)
end

function XSameColorGameConfigs.GetPassiveSkillConfig(id)
    if not PassiveSkillConfigDic[id] then
        XLog.ErrorTableDataNotFound(
            "SameColorGameConfigs.GetPassiveSkillConfig",
            "PassiveSkill配置字段_Id",
            TABLE_PASSIVE_SKILL,
            "Id",
            tostring(id))
    end
    return PassiveSkillConfigDic[id]
end
