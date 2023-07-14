XDoubleTowersConfigs = XDoubleTowersConfigs or {}

XDoubleTowersConfigs.StageState = {
    -- 通关
    Clear = 1,
    -- 未通关
    NotClear = 2,
    -- 未解锁
    Lock = 3
}
XDoubleTowersConfigs.ReasonOfLockGroup = {
    -- 已解锁
    None = 0,
    -- 前置关卡未通关
    PreconditionStageNotClear = 1,
    -- 未到开放时间
    TimeLimit = 2
}

--模块类型
XDoubleTowersConfigs.ModuleType = {
    Role = 1, --角色
    Guard = 2 --守卫
}

-- 每组最多关卡数量
XDoubleTowersConfigs.MaxStageAmountPerGroup = 3

-- teamId 一支队伍就一个人，没必要保存服务端
XDoubleTowersConfigs.TeamId = 19
XDoubleTowersConfigs.TeamTypeId = 130

-- 活动总控表
local ACTIVITY_TAB = "Share/Fuben/DoubleTower/DoubleTowerActivity.tab"
-- 关卡组表
local GROUP_TAB = "Share/Fuben/DoubleTower/DoubleTowerStageGroup.tab"
-- 关卡表
local STAGE_TAB = "Share/Fuben/DoubleTower/DoubleTowerStage.tab"
-- 情报表
local INFORMATION_TAB = "Client/Fuben/DoubleTower/DoubleTowerInformation.tab"
-- 角色（帮手）配置表
local ROLE_TAB = "Share/Fuben/DoubleTower/DoubleTowerRole.tab"
-- 守卫配置表
local GUARD_TAB = "Share/Fuben/DoubleTower/DoubleTowerGuard.tab"
-- 插件表
local PLUGIN_TAB = "Share/Fuben/DoubleTower/DoubleTowerPlugin.tab"
-- 插件详情表
local PLUGIN_LEVEL_TAB = "Share/Fuben/DoubleTower/DoubleTowerPluginLevel.tab"

--region 无脑get配置
local ActivityConfigs = nil
local GroupConfigs = nil
local StageConfigs = nil
local InformationConfigs = nil
local RoleConfigs = nil
local GuardConfigs = nil
local PluginConfigs = nil
local PluginLevelConfigs = nil

function XDoubleTowersConfigs.Init()
end

local function GetActivityConfigs()
    if not ActivityConfigs then
        ActivityConfigs = XTableManager.ReadByIntKey(ACTIVITY_TAB, XTable.XTableDoubleTowerActivity, "Id")
    end
    return ActivityConfigs
end

local function GetGroupConfigs()
    if not GroupConfigs then
        GroupConfigs = XTableManager.ReadByIntKey(GROUP_TAB, XTable.XTableDoubleTowerStageGroup, "Id")
    end
    return GroupConfigs
end

local function GetStageConfigs()
    if not StageConfigs then
        StageConfigs = XTableManager.ReadByIntKey(STAGE_TAB, XTable.XTableDoubleTowerStage, "Id")
    end
    return StageConfigs
end

local function GetInformationConfigs()
    if not InformationConfigs then
        InformationConfigs = XTableManager.ReadByIntKey(INFORMATION_TAB, XTable.XTableDoubleTowerInformation, "Id")
    end
    return InformationConfigs
end

local function GetRoleConfigs()
    if not RoleConfigs then
        RoleConfigs = XTableManager.ReadByIntKey(ROLE_TAB, XTable.XTableDoubleTowerRole, "Id")
    end
    return RoleConfigs
end

local function GetGuardConfigs()
    if not GuardConfigs then
        GuardConfigs = XTableManager.ReadByIntKey(GUARD_TAB, XTable.XTableDoubleTowerGuard, "Id")
    end
    return GuardConfigs
end

local function GetPluginConfigs()
    if not PluginConfigs then
        PluginConfigs = XTableManager.ReadByIntKey(PLUGIN_TAB, XTable.XTableDoubleTowerPlugin, "Id")
    end
    return PluginConfigs
end

local function GetPluginLevelConfigs()
    if not PluginLevelConfigs then
        PluginLevelConfigs = XTableManager.ReadByIntKey(PLUGIN_LEVEL_TAB, XTable.XTableDoubleTowerPluginLevel, "Id")
    end
    return PluginLevelConfigs
end

function XDoubleTowersConfigs.GetActivityCfg(activityId)
    local config = GetActivityConfigs()[activityId]
    if not config then
        XLog.Error(
            "XDoubleTowersConfigs GetActivityCfg error:配置不存在，Id:" .. (activityId or "nil") .. " ,Path:" .. ACTIVITY_TAB
        )
    end
    return config
end

function XDoubleTowersConfigs.GetDefaultActivityId()
    local cfg = GetActivityConfigs()
    for key, value in pairs(cfg) do
        return key
    end
    return false
end

function XDoubleTowersConfigs.GetGroupConfigs()
    return GetGroupConfigs()
end

function XDoubleTowersConfigs.GetStageGroupCfg(groupId)
    return GetGroupConfigs()[groupId] or {}
end

function XDoubleTowersConfigs.GetAllStageConfigs()
    return GetStageConfigs()
end

function XDoubleTowersConfigs.GetStageCfg(id)
    return GetStageConfigs()[id] or {}
end

function XDoubleTowersConfigs.GetInfoCfg(id)
    return GetInformationConfigs()[id]
end

local function GetRoleCfg(id)
    local config = GetRoleConfigs()[id]
    if not config then
        XLog.ErrorTableDataNotFound("XDoubleTowersConfigs.GetRoleCfg", "RoleConfigs", ROLE_TAB, "Id", id)
        return
    end
    return config
end

local function GetGuardCfg(id)
    local config = GetGuardConfigs()[id]
    if not config then
        XLog.ErrorTableDataNotFound("XDoubleTowersConfigs.GetGuardCfg", "GuardConfigs", GUARD_TAB, "Id", id)
        return
    end
    return config
end

local function GetPluginCfg(id)
    local config = GetPluginConfigs()[id]
    if not config then
        XLog.ErrorTableDataNotFound("XDoubleTowersConfigs.GetPluginCfg", "PluginCfgs", PLUGIN_TAB, "Id", id)
        return
    end
    return config
end

local function GetPluginLevelCfg(id)
    return GetPluginLevelConfigs()[id]
end
--endregion
-------------------------------------------------------------------------------------------

function XDoubleTowersConfigs.GetTimeLimitId(activityId)
    return XDoubleTowersConfigs.GetActivityCfg(activityId).OpenTimeId
end

function XDoubleTowersConfigs.GetActivityBackground(activityId)
    return XDoubleTowersConfigs.GetActivityCfg(activityId).BannerBg
end

---@return string@活动名/标题
function XDoubleTowersConfigs.GetTitleName(activityId)
    return XDoubleTowersConfigs.GetActivityCfg(activityId).Name
end

---@return number@收菜货币的id
function XDoubleTowersConfigs.GetCoinItemId(activityId)
    return XDoubleTowersConfigs.GetActivityCfg(activityId).RewardItemId
end

---@return number@收菜间隔
function XDoubleTowersConfigs.GetGatherInterval(activityId)
    return XDoubleTowersConfigs.GetActivityCfg(activityId).RewardTimer
end

---@return number@一次收菜多少代币
function XDoubleTowersConfigs.GetGatherCoins(activityId)
    return XDoubleTowersConfigs.GetActivityCfg(activityId).RewardItemCount
end

---@return number@图文教学界面，对应helpCourse.tab
function XDoubleTowersConfigs.GetHelpKey(activityId)
    return XDoubleTowersConfigs.GetActivityCfg(activityId).HelpKey
end

local _StageGroupAmount = nil
---@return number@关卡组数量，从一之门到n之门，不算特殊关卡
function XDoubleTowersConfigs.GetStageGroupAmount()
    if not _StageGroupAmount then
        _StageGroupAmount = 0
        local groupConfigs = GetGroupConfigs()
        for groupId, cfg in pairs(groupConfigs) do
            if not cfg.IsSpecial then
                _StageGroupAmount = _StageGroupAmount + 1
            end
        end
    end
    return _StageGroupAmount
end

local function SortId(id1, id2)
    return id1 < id2
end
local _GroupIndex2Id = nil
local function InitGroupIndex2Id()
    if not _GroupIndex2Id then
        _GroupIndex2Id = {}
        local groupConfigs = GetGroupConfigs()
        for groupId, cfg in pairs(groupConfigs) do
            if not _GroupIndex2Id[cfg.ActivityId] then
                _GroupIndex2Id[cfg.ActivityId] = {}
            end
            local t = _GroupIndex2Id[cfg.ActivityId]
            t[#t + 1] = groupId
        end
        for activity, group2Id in pairs(_GroupIndex2Id) do
            table.sort(group2Id, SortId)
        end
    end
end

---@return number@ groupId
function XDoubleTowersConfigs.GetGroupId(activityId, groupIndex)
    InitGroupIndex2Id()
    return _GroupIndex2Id[activityId] and _GroupIndex2Id[activityId][groupIndex]
end

function XDoubleTowersConfigs.GetActivityIdByStageId(stageId)
    local groupId = XDoubleTowersConfigs.GetGroupIdByStageId(stageId)
    local groupCfg = XDoubleTowersConfigs.GetStageGroupCfg(groupId)
    return groupCfg and groupCfg.ActivityId
end

local _GroupId2Stage = nil
---@return table@ {stageId1,stageId2,stageId3}
local function GetGroup(activityId, groupId)
    if not _GroupId2Stage then
        local stageConfigs = GetStageConfigs()
        _GroupId2Stage = {}
        for id, cfg in pairs(stageConfigs) do
            local groupActivityId = XDoubleTowersConfigs.GetActivityIdByStageId(cfg.Id)
            if groupActivityId then
                if not _GroupId2Stage[groupActivityId] then
                    _GroupId2Stage[groupActivityId] = {}
                end
                local groupId2Stage = _GroupId2Stage[groupActivityId]
                groupId2Stage[cfg.GroupId] = groupId2Stage[cfg.GroupId] or {}
                local groupIdArray = groupId2Stage[cfg.GroupId]
                groupIdArray[#groupIdArray + 1] = cfg.Id
            end
        end
        for activity, groupId2Stage in pairs(_GroupId2Stage) do
            for groupId, group in pairs(groupId2Stage) do
                table.sort(group, SortId)
            end
        end
    end
    return _GroupId2Stage[activityId][groupId] or {}
end

function XDoubleTowersConfigs.GetGroup(activityId, groupId)
    return GetGroup(activityId, groupId)
end

local function GetGroupCfg(groupId)
    return GetGroupConfigs()[groupId] or {}
end

function XDoubleTowersConfigs.GetStageId(activityId, groupId, stageIndex)
    return GetGroup(activityId, groupId)[stageIndex]
end

function XDoubleTowersConfigs.GetStageName(stageId)
    return XDoubleTowersConfigs.GetStageCfg(stageId).Name
end

function XDoubleTowersConfigs.GetStageTip(stageId)
    return XDoubleTowersConfigs.GetStageCfg(stageId).BuffDesc
end

function XDoubleTowersConfigs.GetPreconditionStage(stageId)
    return XDoubleTowersConfigs.GetStageCfg(stageId).PreStageId
end

-- 关卡组 按时间开放
function XDoubleTowersConfigs.GetGroupTimeLimitId(groupId)
    return GetGroupCfg(groupId).OpenTimeId
end

function XDoubleTowersConfigs.GetGroupName(groupId)
    return GetGroupCfg(groupId).Name
end

local _StageAmount = {}
function XDoubleTowersConfigs.GetTotalNormalStageAmount(activityId)
    if _StageAmount[activityId] then
        return _StageAmount[activityId]
    end
    local stageAmount = 0
    local allGroup = GetGroupConfigs()
    for groupId, groupCfg in pairs(allGroup) do
        if groupCfg.ActivityId == activityId and not groupCfg.IsSpecial then
            local group = GetGroup(activityId, groupId)
            stageAmount = stageAmount + #group
        end
    end
    _StageAmount[activityId] = stageAmount
    return stageAmount
end

local _SpecialGroupId = {}
function XDoubleTowersConfigs.GetSpecialGroupId(activityId)
    if _SpecialGroupId[activityId] ~= nil then
        return _SpecialGroupId[activityId]
    end
    local groupConfigs = GetGroupConfigs()
    for groupId, cfg in pairs(groupConfigs) do
        if cfg.IsSpecial and activityId == cfg.ActivityId then
            _SpecialGroupId[activityId] = groupId
            return groupId
        end
    end
    _SpecialGroupId[activityId] = false
    return false
end

local _Stage2InfoGroup = nil
function XDoubleTowersConfigs.GetInfoIdGroup(stageId)
    if not _Stage2InfoGroup then
        _Stage2InfoGroup = {}
        for infoId, info in pairs(GetInformationConfigs()) do
            _Stage2InfoGroup[info.StageId] = _Stage2InfoGroup[info.StageId] or {}
            local group = _Stage2InfoGroup[info.StageId]
            group[#group + 1] = info.Id
        end
    end
    return _Stage2InfoGroup[stageId] or {}
end

function XDoubleTowersConfigs.GetGroupIdByStageId(stageId)
    return XDoubleTowersConfigs.GetStageCfg(stageId).GroupId
end

function XDoubleTowersConfigs.GetGroupPreconditionStage(groupId)
    return XDoubleTowersConfigs.GetStageGroupCfg(groupId).PreStageId
end

function XDoubleTowersConfigs.GetEnemyInfoImg(infoId)
    return XDoubleTowersConfigs.GetInfoCfg(infoId).BossImage
end

function XDoubleTowersConfigs.GetEnemyInfoRoundDesc(infoId)
    return XDoubleTowersConfigs.GetInfoCfg(infoId).RoundDesc
end

function XDoubleTowersConfigs.GetEnemyInfoTypeDesc(infoId)
    return XDoubleTowersConfigs.GetInfoCfg(infoId).TypeDesc
end

function XDoubleTowersConfigs.GetGroupIndexByStageId(stageId)
    local groupId = XDoubleTowersConfigs.GetGroupIdByStageId(stageId)
    InitGroupIndex2Id()
    local activityId = XDoubleTowersConfigs.GetActivityIdByStageId(stageId)
    local groupIndex2Id = _GroupIndex2Id[activityId]
    if not groupIndex2Id then
        return false
    end
    for groupIndex = 1, #groupIndex2Id do
        if groupIndex2Id[groupIndex] == groupId then
            return groupIndex
        end
    end
    return false
end

function XDoubleTowersConfigs.GetMaxCoins(activityId)
    return XDoubleTowersConfigs.GetActivityCfg(activityId).RewardMaxCount
end
function XDoubleTowersConfigs.GetRolePluginMaxCount()
    local activityId = XDataCenter.DoubleTowersManager.GetActivityId()
    local config = XDoubleTowersConfigs.GetActivityCfg(activityId)
    return config and config.RolePluginMaxCount
end

function XDoubleTowersConfigs.GetGuardPluginMaxCount()
    local activityId = XDataCenter.DoubleTowersManager.GetActivityId()
    local config = XDoubleTowersConfigs.GetActivityCfg(activityId)
    return config and config.GuardPluginMaxCount
end

function XDoubleTowersConfigs.GetActivityRewardItemId()
    local activityId = XDataCenter.DoubleTowersManager.GetActivityId()
    local config = XDoubleTowersConfigs.GetActivityCfg(activityId)
    return config and config.RewardItemId
end

---------------DoubleTowerRole being-----------------
local IsInitDoubleTowerRole = false
local ActivityIdToRoleId = 0
local InitDoubleTowerRoleDic = function(activityId)
    if IsInitDoubleTowerRole then
        return
    end

    -- local configs = GetRoleConfigs()
    -- for id, v in pairs(configs) do
    --     if not ActivityIdToRoleId[v.ActivityId] then
    --         ActivityIdToRoleId[v.ActivityId] = id
    --     end
    -- end
    ActivityIdToRoleId = activityId
    IsInitDoubleTowerRole = true
end

function XDoubleTowersConfigs.GetDoubleTowerRoleId()
    local activityId = XDataCenter.DoubleTowersManager.GetActivityId()
    InitDoubleTowerRoleDic(activityId)
    return ActivityIdToRoleId
end

function XDoubleTowersConfigs.GetRoleBasePluginIdList()
    local selectPluginType = XDoubleTowersConfigs.GetRoleSelectPluginType()
    if XTool.IsNumberValid(selectPluginType) then
        return XDoubleTowersConfigs.GetRolePluginLevelIdList()
    end
    return XDoubleTowersConfigs.GetDoubleTowerPluginIdList(selectPluginType)
end

function XDoubleTowersConfigs.GetRoleSelectPluginType()
    local id = XDoubleTowersConfigs.GetDoubleTowerRoleId()
    return GetRoleCfg(id).SlotPluginType
end

function XDoubleTowersConfigs.GetRolePluginLevelIdList()
    local id = XDoubleTowersConfigs.GetDoubleTowerRoleId()
    return GetRoleCfg(id).PluginLevelId
end

function XDoubleTowersConfigs.GetDefaultRoleBaseId()
    local idList = XDoubleTowersConfigs.GetRolePluginLevelIdList()
    for idx, id in ipairs(idList or {}) do
        local preStage = XDoubleTowersConfigs.GetRolePreStageId(idx)
        --默认为不需要前置关卡的pluginevelId
        if not XTool.IsNumberValid(preStage) then
            return id
        end
    end
    return idList[1]
end

function XDoubleTowersConfigs.GetRoleDefaultPluginId()
    local id = XDoubleTowersConfigs.GetDoubleTowerRoleId()
    return GetRoleCfg(id).DefaultPlugin
end

function XDoubleTowersConfigs.GetRolePluginLevelId(index)
    local idList = XDoubleTowersConfigs.GetRolePluginLevelIdList()
    return idList[index]
end

function XDoubleTowersConfigs.GetRolePreStageId(index)
    local id = XDoubleTowersConfigs.GetDoubleTowerRoleId()
    local preStageIdList = GetRoleCfg(id).PreStage
    return preStageIdList[index]
end

function XDoubleTowersConfigs.GetRoleIcon(index)
    local id = XDoubleTowersConfigs.GetDoubleTowerRoleId()
    local iconList = GetRoleCfg(id).Icon
    return iconList[index]
end

function XDoubleTowersConfigs.GetRoleIconByPluginLevelId(pluginLevelId)
    local idList = XDoubleTowersConfigs.GetRolePluginLevelIdList()
    for index, id in ipairs(idList) do
        if pluginLevelId == id then
            return XDoubleTowersConfigs.GetRoleIcon(index)
        end
    end
end

function XDoubleTowersConfigs.GetSlotPreStageId(index, type)
    local preStageIdList = {}
    if type == XDoubleTowersConfigs.ModuleType.Role then
        local id = XDoubleTowersConfigs.GetDoubleTowerRoleId()
        preStageIdList = GetRoleCfg(id).SlotPreStageId
    elseif type == XDoubleTowersConfigs.ModuleType.Guard then
        local id = XDoubleTowersConfigs.GetDoubleTowerGuardId()
        preStageIdList = GetGuardCfg(id).SlotPreStageId
    end
    return preStageIdList[index]
end

---------------DoubleTowerRole end-------------------

---------------DoubleTowerGuard being-------------------
local IsInitDoubleTowerGuard = false
local ActivityIdToGuardId = 0
local InitDoubleTowerGuardDic = function(activityId)
    if IsInitDoubleTowerGuard then
        return
    end

    -- local configs = GetGuardConfigs()
    -- for id, v in pairs(configs) do
    --     if not ActivityIdToGuardIdList[v.ActivityId] then
    --         ActivityIdToGuardIdList[v.ActivityId] = id
    --     end
    -- end
    ActivityIdToGuardId = activityId
    IsInitDoubleTowerGuard = true
end

function XDoubleTowersConfigs.GetDoubleTowerGuardId()
    local activityId = XDataCenter.DoubleTowersManager.GetActivityId()
    InitDoubleTowerGuardDic(activityId)
    return ActivityIdToGuardId
end

function XDoubleTowersConfigs.GetGuardBasePluginIdList()
    local selectPluginType = XDoubleTowersConfigs.GetGuardSelectPluginType()
    if XTool.IsNumberValid(selectPluginType) then
        return XDoubleTowersConfigs.GetGuardPluginLevelIdList()
    end
    return XDoubleTowersConfigs.GetDoubleTowerPluginIdList(selectPluginType)
end

function XDoubleTowersConfigs.GetDefaultGuardIndex()
    local idList = XDoubleTowersConfigs.GetGuardPluginLevelIdList()
    for idx, _ in ipairs(idList or {}) do
        local preStage = XDoubleTowersConfigs.GetGuardPreStageId(idx)
        --默认为不需要前置关卡的pluginevelId
        if not XTool.IsNumberValid(preStage) then
            return idx
        end
    end
    return 1
end

function XDoubleTowersConfigs.GetGuardPluginLevelId(index)
    local idList = XDoubleTowersConfigs.GetGuardPluginLevelIdList()
    return idList[index]
end

function XDoubleTowersConfigs.GetGuardSelectPluginType()
    local id = XDoubleTowersConfigs.GetDoubleTowerGuardId()
    return GetGuardCfg(id).SlotPluginType
end

function XDoubleTowersConfigs.GetGuardNpcIdList(index)
    local id = XDoubleTowersConfigs.GetDoubleTowerGuardId()
    local npcIdList = GetGuardCfg(id).NPCId
    return npcIdList[index]
end

function XDoubleTowersConfigs.GetGuardPluginLevelIdList()
    local id = XDoubleTowersConfigs.GetDoubleTowerGuardId()
    return GetGuardCfg(id).PluginLevelId
end

function XDoubleTowersConfigs.GetGuardPreStageId(index)
    local id = XDoubleTowersConfigs.GetDoubleTowerGuardId()
    local preStageIdList = GetGuardCfg(id).PreStageId
    return preStageIdList[index]
end

function XDoubleTowersConfigs.GetGuardIcon(index)
    local id = XDoubleTowersConfigs.GetDoubleTowerGuardId()
    local iconList = GetGuardCfg(id).Icon
    return iconList[index]
end

function XDoubleTowersConfigs.GetGuardSmallIcon(index)
    local id = XDoubleTowersConfigs.GetDoubleTowerGuardId()
    local iconList = GetGuardCfg(id).SmallIcon
    return iconList[index]
end

function XDoubleTowersConfigs.GetGuardIconByPluginLevelId(pluginLevelId, useSmallIcon)
    local idList = XDoubleTowersConfigs.GetGuardPluginLevelIdList()
    for index, id in ipairs(idList) do
        if pluginLevelId == id then
            return useSmallIcon and XDoubleTowersConfigs.GetGuardSmallIcon(index) or
                XDoubleTowersConfigs.GetGuardIcon(index)
        end
    end
end
---------------DoubleTowerGuard end---------------------

---------------DoubleTowerPlugin begin-------------------
local IsInitDoubleTowerPlugin = false
local ActivityIdToPluginIdList = {} --key:活动Id, value:插件组Id列表
local PluginIdToLevelIdDic = {} --key1:插件Id, key2:等级, value:插件等级Id
local PluginIdToMaxLevelDic = {} --key:插件Id, value:插件最高等级
local PluginIdToLevelIdList = {}
local InitDoubleTowerPluginDic = function()
    if IsInitDoubleTowerPlugin then
        return
    end

    local configs = GetPluginConfigs()
    for id, v in pairs(configs) do
        if not ActivityIdToPluginIdList[v.ActivityId] then
            ActivityIdToPluginIdList[v.ActivityId] = {}
        end
        table.insert(ActivityIdToPluginIdList[v.ActivityId], id)
    end

    configs = GetPluginLevelConfigs()
    for id, v in pairs(configs) do
        if not PluginIdToLevelIdDic[v.PluginId] then
            PluginIdToLevelIdDic[v.PluginId] = {}
        end
        PluginIdToLevelIdDic[v.PluginId][v.Level] = id

        if not PluginIdToLevelIdList[v.PluginId] then
            PluginIdToLevelIdList[v.PluginId] = {}
        end
        table.insert(PluginIdToLevelIdList[v.PluginId], v.Id)

        local curMaxLevel = PluginIdToMaxLevelDic[v.PluginId]
        if not curMaxLevel or curMaxLevel < v.Level then
            PluginIdToMaxLevelDic[v.PluginId] = v.Level
        end
    end

    for _, levelIdList in pairs(PluginIdToLevelIdList) do
        table.sort(
            levelIdList,
            function(levelIdA, levelIdB)
                local levelA = XDoubleTowersConfigs.GetPluginLevel(levelIdA)
                local levelB = XDoubleTowersConfigs.GetPluginLevel(levelIdB)
                if levelA ~= levelB then
                    return levelA < levelB
                end
                return levelIdA < levelIdB
            end
        )
    end

    IsInitDoubleTowerPlugin = true
end

function XDoubleTowersConfigs.GetDoubleTowerPluginIdList(type)
    InitDoubleTowerPluginDic()
    local activityId = XDataCenter.DoubleTowersManager.GetActivityId()
    local pluginIdList = ActivityIdToPluginIdList[activityId] or {}
    if not type then
        return pluginIdList
    end

    local sameTypePluginIdList = {}
    for _, pluginId in ipairs(pluginIdList) do
        if XDoubleTowersConfigs.GetPluginType(pluginId) == type then
            table.insert(sameTypePluginIdList, pluginId)
        end
    end
    return sameTypePluginIdList
end

function XDoubleTowersConfigs.GetPluginType(id)
    return GetPluginCfg(id).Type
end

function XDoubleTowersConfigs.GetPluginIcon(id)
    return GetPluginCfg(id).Icon
end

function XDoubleTowersConfigs.GetPluginDesc(id)
    return GetPluginCfg(id).Desc
end
---------------DoubleTowerPlugin end---------------------

---------------DoubleTowerPluginLevel begin-------------------
function XDoubleTowersConfigs.GetPluginLevelId(pluginId, level)
    InitDoubleTowerPluginDic()
    level = XTool.IsNumberValid(level) and level or 1
    return PluginIdToLevelIdDic[pluginId] and PluginIdToLevelIdDic[pluginId][level]
end

function XDoubleTowersConfigs.GetPluginLevelIdList(pluginId)
    InitDoubleTowerPluginDic()
    return PluginIdToLevelIdList[pluginId] or {}
end

function XDoubleTowersConfigs.GetPluginMaxLevel(pluginId)
    InitDoubleTowerPluginDic()
    return PluginIdToMaxLevelDic[pluginId] or 0
end

function XDoubleTowersConfigs.GetPluginLevelName(id)
    return GetPluginLevelCfg(id).Name
end

function XDoubleTowersConfigs.GetLevelPluginId(id)
    return GetPluginLevelCfg(id).PluginId
end

function XDoubleTowersConfigs.GetPluginLevel(id)
    return GetPluginLevelCfg(id).Level
end

function XDoubleTowersConfigs.GetPluginLevelFightEventId(id)
    return GetPluginLevelCfg(id).FightEventId
end

function XDoubleTowersConfigs.GetPluginLevelUpgradeSpend(id)
    return GetPluginLevelCfg(id).UpgradeSpend
end

function XDoubleTowersConfigs.GetPluginLevelDesc(id)
    return GetPluginLevelCfg(id).Desc
end
---------------DoubleTowerPluginLevel end---------------------
