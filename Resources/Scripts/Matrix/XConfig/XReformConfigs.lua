XReformConfigs = XReformConfigs or {}
-- 配置表路径
local SHARE_TABLE_ROOT_PATH = "Share/Fuben/Reform/"
local CLIENT_TABLE_ROOT_PATH = "Client/Fuben/Reform/"
-- 配置数据
-- 基础关卡配置信息
local StageConfig = nil
-- 改造关卡配置信息
local StageDiffConfig = nil
-- 敌人组配置信息
local EnemyGroupConfig = nil
-- 敌人源配置信息
local EnemySourceConfig = nil
-- 敌人替换目标配置信息
local EnemyTargetConfig = nil
-- 成员组配置信息
local MemberGroupConfig = nil
-- 成员源配置信息
local MemberSourceConfig = nil
-- 成员替换目标配置信息
local MemberTargetConfig = nil
-- 环境组配置信息
local EnvironmentGroupConfig = nil
-- 环境配置信息
local EnvironmentConfig = nil
-- 加成组配置信息
local BuffGroupConfig = nil
-- 加成配置信息
local BuffConfig = nil
-- 活动相关配置
local ActivityConfig = nil
local EnemyBuffDetailConfig = nil
local EvolvableGroupBtnSortConfig = nil

-- 枚举
XReformConfigs.EntityType = {
    Entity = 1,
    Add = 2,
}
-- 改造页签类型
XReformConfigs.EvolvableGroupType = {
    Enemy = 1,
    Environment = 2,
    Buff = 3,
    Member = 4,
}

-- 表现相关配置
XReformConfigs.ScrollTime = 0.3 -- 源面板滚动时间
XReformConfigs.MinDistance = 150 -- 滚动检测最小距离
XReformConfigs.MaxDistance = 500 -- 滚动检测最大距离
XReformConfigs.ScrollOffset = 50 -- 滚动偏移

function XReformConfigs.Init()
    local xTableManager = XTableManager
    local xTable = XTable
    StageConfig = xTableManager.ReadByIntKey(SHARE_TABLE_ROOT_PATH .. "ReformStage.tab", xTable.XTableReformStage, "Id")
    StageDiffConfig = xTableManager.ReadByIntKey(SHARE_TABLE_ROOT_PATH .. "ReformStageDiff.tab", xTable.XTableReformStageDifficulty, "Id")
    EnemyGroupConfig = xTableManager.ReadByIntKey(SHARE_TABLE_ROOT_PATH .. "ReformEnemyGroup.tab", xTable.XTableReformGroup, "Id")
    EnemySourceConfig = xTableManager.ReadByIntKey(SHARE_TABLE_ROOT_PATH .. "ReformEnemySource.tab", xTable.XTableReformEnemySource, "Id")
    EnemyTargetConfig = xTableManager.ReadByIntKey(SHARE_TABLE_ROOT_PATH .. "ReformEnemyTarget.tab", xTable.XTableReformEnemyTarget, "Id")
    MemberGroupConfig = xTableManager.ReadByIntKey(SHARE_TABLE_ROOT_PATH .. "ReformMemberGroup.tab", xTable.XTableReformGroup, "Id")
    MemberSourceConfig = xTableManager.ReadByIntKey(SHARE_TABLE_ROOT_PATH .. "ReformMemberSource.tab", xTable.XTableReformMemberSource, "Id")
    MemberTargetConfig = xTableManager.ReadByIntKey(SHARE_TABLE_ROOT_PATH .. "ReformMemberTarget.tab", xTable.XTableReformMemberTarget, "Id")
    EnvironmentGroupConfig = xTableManager.ReadByIntKey(SHARE_TABLE_ROOT_PATH .. "ReformEnvGroup.tab", xTable.XTableReformGroup, "Id")
    EnvironmentConfig = xTableManager.ReadByIntKey(SHARE_TABLE_ROOT_PATH .. "ReformEnv.tab", xTable.XTableReformEnv, "Id")
    BuffGroupConfig = xTableManager.ReadByIntKey(SHARE_TABLE_ROOT_PATH .. "ReformBuffGroup.tab", xTable.XTableReformGroup, "Id")
    BuffConfig = xTableManager.ReadByIntKey(SHARE_TABLE_ROOT_PATH .. "ReformBuff.tab", xTable.XTableReformBuff, "Id")
    ActivityConfig = xTableManager.ReadByIntKey(SHARE_TABLE_ROOT_PATH .. "ReformCfg.tab", xTable.XTableReformCfg, "Id")
    EnemyBuffDetailConfig = xTableManager.ReadByIntKey(CLIENT_TABLE_ROOT_PATH .. "ReformEnemyBuffDetail.tab", xTable.XTableReformEnemyBuffDetail, "Id")
    EvolvableGroupBtnSortConfig = xTableManager.ReadByIntKey(CLIENT_TABLE_ROOT_PATH .. "ReformEvolvableGroupBtnSort.tab", xTable.XTableReformEvolvableGroupBtnSort, "Id")
end

function XReformConfigs.GetEnemyBuffDetail(id)
    return EnemyBuffDetailConfig[id] 
end

function XReformConfigs.GetGroupTypeSortWeight(groupType)
    return EvolvableGroupBtnSortConfig[groupType].Weight
end

function XReformConfigs.GetActivityConfig(id)
    local result = ActivityConfig[id]
    if result == nil then
        for _, config in pairs(ActivityConfig) do
            if XFunctionManager.CheckInTimeByTimeId(config.OpenTimeId) then
                result = config
                break
            end
        end
    end
    -- 还是空的就拿默认的
    if result == nil then
        result = ActivityConfig[1]
    end
    return result
end

-- 获取所有基础关卡数据
function XReformConfigs.GetStageConfigDic()
    return StageConfig
end

function XReformConfigs.GetStageConfigIds()
    if XReformConfigs.__StageConfigIds == nil then
        XReformConfigs.__StageConfigIds = {}
        for configId, _ in pairs(StageConfig) do
            table.insert(XReformConfigs.__StageConfigIds, configId)
        end
        table.sort(XReformConfigs.__StageConfigIds, function(idA, idB)
            return idA < idB
        end)
    end
    return XReformConfigs.__StageConfigIds
end

function XReformConfigs.GetStageConfigById(id)
    return StageConfig[id]
end

-- 获取基础关卡对应的改造关卡数据
function XReformConfigs.GetStageDiffConfigsByStageId(id)
    local result = {}
    local config = StageConfig[id]
    if config == nil then return result end
    for _, stageDiffId in ipairs(config.StageDiff) do
        table.insert(result, StageDiffConfig[stageDiffId])
    end
    return result
end

function XReformConfigs.GetStageDiffConfigById(id)
    return StageDiffConfig[id]
end

-- 获取敌人组配置数据
function XReformConfigs.GetEnemyGroupConfig(id)
    return EnemyGroupConfig[id]
end

-- 获取敌人源配置
function XReformConfigs.GetEnemySourceConfig(id)
    return EnemySourceConfig[id]
end

-- 获取敌人目标配置
function XReformConfigs.GetEnemyTargetConfig(id)
    return EnemyTargetConfig[id]
end

-- 获取成员组配置数据
function XReformConfigs.GetMemberGroupConfig(id)
    return MemberGroupConfig[id]
end

-- 获取成员源配置
function XReformConfigs.GetMemberSourceConfig(id)
    return MemberSourceConfig[id]
end

-- 获取成员目标配置
function XReformConfigs.GetMemberTargetConfig(id)
    return MemberTargetConfig[id]
end

-- 获取环境组配置数据
function XReformConfigs.GetEnvironmentGroupConfig(id)
    return EnvironmentGroupConfig[id]
end

-- 获取环境配置数据
function XReformConfigs.GetEnvironmentConfig(id)
    return EnvironmentConfig[id]
end

-- 获取加成组配置数据
function XReformConfigs.GetBuffGroupConfig(id)
    return BuffGroupConfig[id]
end

-- 获取加成配置数据
function XReformConfigs.GetBuffConfig(id)
    return BuffConfig[id]
end