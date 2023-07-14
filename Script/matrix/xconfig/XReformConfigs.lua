XReformConfigs = XReformConfigs or {}
-- 配置表路径
local SHARE_TABLE_ROOT_PATH = "Share/Fuben/Reform/"
local CLIENT_TABLE_ROOT_PATH = "Client/Fuben/Reform/"

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
XReformConfigs.EndTimeCode = 20123001 -- 活动时间结束码

function XReformConfigs.Init()
    XConfigCenter.CreateGetProperties(XReformConfigs, {
        "StageConfig",
        "StageDiffConfig",
        "EnemyGroupConfig",
        "EnemySourceConfig",
        "EnemyTargetConfig",
        "MemberGroupConfig",
        "MemberSourceConfig",
        "MemberTargetConfig",
        "EnvironmentGroupConfig",
        "EnvironmentConfig",
        "BuffGroupConfig",
        "BuffConfig",
        "ActivityConfig",
        "EnemyBuffDetailConfig",
        "EvolvableGroupBtnSortConfig",  
    }, { 
        "ReadByIntKey", SHARE_TABLE_ROOT_PATH .. "ReformStage.tab", XTable.XTableReformStage, "Id",
        "ReadByIntKey", SHARE_TABLE_ROOT_PATH .. "ReformStageDiff.tab", XTable.XTableReformStageDifficulty, "Id",
        "ReadByIntKey", SHARE_TABLE_ROOT_PATH .. "ReformEnemyGroup.tab", XTable.XTableReformGroup, "Id",
        "ReadByIntKey", SHARE_TABLE_ROOT_PATH .. "ReformEnemySource.tab", XTable.XTableReformEnemySource, "Id",
        "ReadByIntKey", SHARE_TABLE_ROOT_PATH .. "ReformEnemyTarget.tab", XTable.XTableReformEnemyTarget, "Id",
        "ReadByIntKey", SHARE_TABLE_ROOT_PATH .. "ReformMemberGroup.tab", XTable.XTableReformGroup, "Id",
        "ReadByIntKey", SHARE_TABLE_ROOT_PATH .. "ReformMemberSource.tab", XTable.XTableReformMemberSource, "Id",
        "ReadByIntKey", SHARE_TABLE_ROOT_PATH .. "ReformMemberTarget.tab", XTable.XTableReformMemberTarget, "Id",
        "ReadByIntKey", SHARE_TABLE_ROOT_PATH .. "ReformEnvGroup.tab", XTable.XTableReformGroup, "Id",
        "ReadByIntKey", SHARE_TABLE_ROOT_PATH .. "ReformEnv.tab", XTable.XTableReformEnv, "Id",
        "ReadByIntKey", SHARE_TABLE_ROOT_PATH .. "ReformBuffGroup.tab", XTable.XTableReformGroup, "Id",
        "ReadByIntKey", SHARE_TABLE_ROOT_PATH .. "ReformBuff.tab", XTable.XTableReformBuff, "Id",
        "ReadByIntKey", SHARE_TABLE_ROOT_PATH .. "ReformCfg.tab", XTable.XTableReformCfg, "Id",
        "ReadByIntKey", CLIENT_TABLE_ROOT_PATH .. "ReformEnemyBuffDetail.tab", XTable.XTableReformEnemyBuffDetail, "Id",
        "ReadByIntKey", CLIENT_TABLE_ROOT_PATH .. "ReformEvolvableGroupBtnSort.tab", XTable.XTableReformEvolvableGroupBtnSort, "Id",
    })
end

function XReformConfigs.GetEnemyBuffDetail(id)
    return XReformConfigs.GetEnemyBuffDetailConfig()[id] 
end

function XReformConfigs.GetGroupTypeSortWeight(groupType)
    return XReformConfigs.GetEvolvableGroupBtnSortConfig()[groupType].Weight
end

function XReformConfigs.GetActivityConfigById(id)
    local result = XReformConfigs.GetActivityConfig()[id]
    if result == nil then
        for _, config in pairs(XReformConfigs.GetActivityConfig()) do
            if config.OpenTimeId > 0 then
                result = config
                break
            end
        end
    end
    -- 还是空的就拿默认的
    if result == nil then
        result = XReformConfigs.GetActivityConfig()[1]
    end
    return result
end

-- 获取所有基础关卡数据
function XReformConfigs.GetStageConfigDic()
    return XReformConfigs.GetStageConfig()
end

function XReformConfigs.GetStageConfigIds()
    if XReformConfigs.__StageConfigIds == nil then
        XReformConfigs.__StageConfigIds = {}
        for configId, _ in pairs(XReformConfigs.GetStageConfig()) do
            table.insert(XReformConfigs.__StageConfigIds, configId)
        end
        table.sort(XReformConfigs.__StageConfigIds, function(idA, idB)
            return idA < idB
        end)
    end
    return XReformConfigs.__StageConfigIds
end

function XReformConfigs.GetStageConfigById(id)
    return XReformConfigs.GetStageConfig()[id]
end

-- 获取基础关卡对应的改造关卡数据
function XReformConfigs.GetStageDiffConfigsByStageId(id)
    local result = {}
    local config = XReformConfigs.GetStageConfig()[id]
    if config == nil then return result end
    for _, stageDiffId in ipairs(config.StageDiff) do
        table.insert(result, XReformConfigs.GetStageDiffConfig()[stageDiffId])
    end
    return result
end

function XReformConfigs.GetStageDiffConfigById(id)
    return XReformConfigs.GetStageDiffConfig()[id]
end

function XReformConfigs.GetBaseStageMaxDiffCount(id)
    local stageConfig = XReformConfigs.GetStageConfigById(id)
    if stageConfig == nil then return 0 end
    local result = 0
    for _, v in ipairs(stageConfig.StageDiff) do
        if v ~= nil and v > 0 then
            result = result + 1
        end
    end
    return result
end