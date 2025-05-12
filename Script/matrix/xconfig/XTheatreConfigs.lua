XTheatreConfigs = XTheatreConfigs or {}

-- 配置表
local SHARE_TABLE_PATH = "Share/Theatre/"
local CLIENT_TABLE_PATH = "Client/Theatre/"

XTheatreConfigs.NodeType = {
    None = 0,  
    Event = 1,  -- 事件
    Shop = 2,  -- 商店
    Battle = 3, -- 战斗
    Random = 4, -- 随机
    MovieBattle = 5,    -- 剧情关
    Movie = 6,  -- 直接播放剧情
}

XTheatreConfigs.EventNodeType = {
    Talk = 1,   -- 对白
    Selectable = 2, -- 选项
    LocalReward = 3, -- 本局奖励
    GlobalReward = 4, -- 全局(永久)奖励
    Battle = 5, -- 战斗
    Movie = 6,  -- 剧情
}

XTheatreConfigs.AdventureRewardType = {
    None = 0,   -- 无
    SelectSkill = 1,    -- 选择技能
    LevelUp = 2,    -- 升级
    Decoration = 3, -- 装修
    PowerFavor = 4,   -- 势力好感
    RewardId = 99,  -- 奖励id
}

XTheatreConfigs.SelectableEventItemType = {
    ConsumeItem = 1,    -- 消耗道具
    CheckHasItem = 2,   -- 检查拥有道具
    IconTrigger = 3,    -- 图标触发
    IconSkip = 4,       -- 图标跳过
}

XTheatreConfigs.SkillType = {
    Core = 1,   -- 核心技能
    Additional = 2,   -- 附属技能
}

XTheatreConfigs.SkillOperationType = {
    AddBuff = 1,    -- 增幅
    LevelUp = 2,    -- 升级
    Replace = 3,    -- 替换
}

XTheatreConfigs.OperationQueueType = {
    NodeReward = 1, -- 奖励
    ChapterSettle = 2,  -- 章节结算
    AdventureSettle = 3,    -- 冒险结算
    BattleSettle = 4,   -- 战斗结算
}

--图鉴页签枚举
XTheatreConfigs.FieldGuideIds = {
    CurSkill = 1, --当前增益
    AllSkill = 2, --增益图鉴
    Item = 3, --其他道具
}

--道具类型
XTheatreConfigs.ItemType = {
    Token = 1,  --信物
    ThisGameItem = 2,   --本局道具
    LastItem = 3,   --永久道具
}

--势力好感度奖励类型
XTheatreConfigs.PowerFavorRewardType = {
    PowerFavorRewardType1 = 1,  --获得道具
    PowerFavorRewardType2 = 2,  --解锁指定势力技能, 该类型可叠加
    PowerFavorRewardType3 = 3,  --局内出现该势力核心技能时，改变初始品质。该效果只取最高
    PowerFavorRewardType4 = 4,  --局内出现该势力核心技能升级时，改变每次增加的品质数。该效果只取最高
    PowerFavorRewardType5 = 5,  --解锁信物
}

--功能解锁弹窗显示的布局枚举
XTheatreConfigs.UplockTipsPanel = {
    Prerogative = 1,    --解锁功能
    NewTalent = 2,      --解锁新装修项
    OwnRole = 3,        --可使用自己角色
}

-- PS:因服务器是代码写死，客户端后期可以考虑配置在总表里
-- 局内商店货币
XTheatreConfigs.TheatreCoin = 96101
-- 装修点
XTheatreConfigs.TheatreDecorationCoin = 96102
-- 好感度道具
XTheatreConfigs.TheatreFavorCoin = 96103
-- 局外活动道具
XTheatreConfigs.TheatreOutsideCoin = 96104
-- 局内商店最大显示数量
XTheatreConfigs.ShopMaxItemCount = 4
-- 绑定事件选项装修点的装修类型
XTheatreConfigs.DecorationEventOptionType = 8
XTheatreConfigs.DecorationReopenOptionType = 9
XTheatreConfigs.DecorationRecruitOptionType = 10
XTheatreConfigs.DecorationRecruitRefreshOptionType = 11 --每幕招募时，刷新次数+N，N=参数1

--"开始冒险"艺术字路径
XTheatreConfigs.TheatreTxtStartPath = CS.XGame.ClientConfig:GetString("TheatreTxtStartPath")
--"继续冒险"艺术字路径
XTheatreConfigs.TheatreTxtContinuePath = CS.XGame.ClientConfig:GetString("TheatreTxtContinuePath")

-- XTheatreConfigs.BattleType = {
--     Single = 1, -- 单队伍
--     Multiple = 2,   -- 多队伍
-- }

function XTheatreConfigs.Init()
    XConfigCenter.CreateGetProperties(XTheatreConfigs, {
        "TheatreChapter",
        "TheatreConfig",
        "TheatreDecoration",
        "TheatreDifficulty",
        "TheatreFactor",
        "TheatreItem",
        "TheatreLv",
        "TheatreNode",
        "TheatrePowerCondition",
        "TheatrePowerFavor",
        "TheatreRole",
        "TheatreRoleAttr",
        "TheatreSkill",
        "TheatreStage",
        "TheatreEvent",
        "TheatreClientConfig",
        "TheatreEnding",
        "TheatreNodeShop",
        "TheatreAutoTeam",
        "TheatreFieldGuide",
        "TheatreKeepsake",
        "TheatreTask",
        "TheatreTaskGroup",
        "TheatreSkillPosDefine",
        "TheatreEventClientConfig",
    }, { 
        "ReadByIntKey", SHARE_TABLE_PATH .. "TheatreChapter.tab", XTable.XTableTheatreChapter, "Id",
        "ReadByStringKey", SHARE_TABLE_PATH .. "TheatreConfig.tab", XTable.XTableTheatreConfig, "Key",
        "ReadByIntKey", SHARE_TABLE_PATH .. "TheatreDecoration.tab", XTable.XTableTheatreDecoration, "Id",
        "ReadByIntKey", SHARE_TABLE_PATH .. "TheatreDifficulty.tab", XTable.XTableTheatreDifficulty, "Id",
        "ReadByIntKey", SHARE_TABLE_PATH .. "TheatreFactor.tab", XTable.XTableTheatreFactor, "Id",
        "ReadByIntKey", SHARE_TABLE_PATH .. "TheatreItem.tab", XTable.XTableTheatreItem, "Id",
        "ReadByIntKey", SHARE_TABLE_PATH .. "TheatreLv.tab", XTable.XTableTheatreLv, "Id",
        "ReadByIntKey", SHARE_TABLE_PATH .. "TheatreNode.tab", XTable.XTableTheatreNode, "Id",
        "ReadByIntKey", SHARE_TABLE_PATH .. "TheatrePowerCondition.tab", XTable.XTableTheatrePowerCondition, "Id",
        "ReadByIntKey", SHARE_TABLE_PATH .. "TheatrePowerFavor.tab", XTable.XTableTheatrePowerFavor, "Id",
        "ReadByIntKey", SHARE_TABLE_PATH .. "TheatreRole.tab", XTable.XTableTheatreRole, "Id",
        "ReadByIntKey", SHARE_TABLE_PATH .. "TheatreRoleAttr.tab", XTable.XTableTheatreRoleAttr, "Id",
        "ReadByIntKey", SHARE_TABLE_PATH .. "TheatreSkill.tab", XTable.XTableTheatreSkill, "Id",
        "ReadByIntKey", SHARE_TABLE_PATH .. "TheatreStage.tab", XTable.XTableTheatreStage, "Id",
        "ReadByIntKey", SHARE_TABLE_PATH .. "TheatreEvent.tab", XTable.XTableTheatreEvent, "Id",
        "ReadByStringKey", CLIENT_TABLE_PATH .. "TheatreClientConfig.tab", XTable.XTableTheatreClientConfig, "Key",
        "ReadByIntKey", SHARE_TABLE_PATH .. "TheatreEnding.tab", XTable.XTableTheatreEnding, "Id",
        "ReadByIntKey", SHARE_TABLE_PATH .. "TheatreNodeShop.tab", XTable.XTableTheatreNodeShop, "Id",
        "ReadByIntKey", CLIENT_TABLE_PATH .. "TheatreAutoTeam.tab", XTable.XTableTheatreAutoTeam, "StageId",
        "ReadByIntKey", CLIENT_TABLE_PATH .. "TheatreFieldGuide.tab", XTable.XTableTheatreFieldGuide, "Id",
        "ReadByIntKey", CLIENT_TABLE_PATH .. "TheatreKeepsake.tab", XTable.XTableTheatreKeepsake, "Id",
        "ReadByIntKey", CLIENT_TABLE_PATH .. "TheatreTask.tab", XTable.XTableTheatreTask, "Id",
        "ReadByIntKey", CLIENT_TABLE_PATH .. "TheatreTaskGroup.tab", XTable.XTableTheatreTaskGroup, "Id",
        "ReadByIntKey", SHARE_TABLE_PATH .. "TheatreSkillPosDefine.tab", XTable.XTableTheatreSkillPosDefine, "Id",
        "ReadByIntKey", CLIENT_TABLE_PATH .. "TheatreEventClientConfig.tab", XTable.XTableTheatreEventClientConfig, "Id",
    })

end

function XTheatreConfigs.GetRoleRobotConfig(roleId, level)
    local roleLevel2RobotDic = XTheatreConfigs.__RoleLevel2RobotDic
    if roleLevel2RobotDic == nil then
        roleLevel2RobotDic = {}
        local configs = XTheatreConfigs.GetTheatreRoleAttr()
        for _, config in ipairs(configs) do
            roleLevel2RobotDic[config.RoleId] = roleLevel2RobotDic[config.RoleId] or {}
            table.insert(roleLevel2RobotDic[config.RoleId], config)
        end
        XTheatreConfigs.__RoleLevel2RobotDic = roleLevel2RobotDic
    end
    local resultConfigs = roleLevel2RobotDic[roleId]
    if resultConfigs == nil then
        XLog.Error(string.format( "TheatreRoleAttr找不到id：%s的配置", roleId), level)
        return
    end
    if level == nil then
        return resultConfigs
    end
    for i = #resultConfigs, 1, -1 do
        if level >= resultConfigs[i].Lv then
            return resultConfigs[i]
        end
    end
    return resultConfigs[1]
end

function XTheatreConfigs.GetEventNodeConfig(eventId, stepId)
    for id, config in pairs(XTheatreConfigs.GetTheatreEvent()) do
        if config.EventId == eventId and config.StepId == stepId then
            return config
        end
    end
end

function XTheatreConfigs.GetInitLevel()
    return XTheatreConfigs.GetTheatreLv()[1].Lv
end

function XTheatreConfigs.GetLevel2Data(level)
    local configs = XTheatreConfigs.GetTheatreLv()
    local config
    for i = #configs, 1, -1 do
        config = configs[i]
        if level >= config.Lv then
            return config
        end
    end
    return configs[1]
end

function XTheatreConfigs.GetMaxLevel()
    local configs = XTheatreConfigs.GetTheatreLv()
    return configs[#configs].Lv
end

function XTheatreConfigs.GetNodeTypeName(nodeType)
    return XTheatreConfigs.GetTheatreClientConfig("NodeTypeName").Values[nodeType]
end

function XTheatreConfigs.GetNodeTypeIcon(nodeType)
    return XTheatreConfigs.GetTheatreClientConfig("NodeTypeIcon").Values[nodeType]
end

function XTheatreConfigs.GetNodeTypeDesc(nodeType)
    return XTheatreConfigs.GetTheatreClientConfig("NodeTypeDesc").Values[nodeType]
end

function XTheatreConfigs.GetClientConfig(key, valueIndex)
    if valueIndex == nil then valueIndex = 1 end
    return XTheatreConfigs.GetTheatreClientConfig(key).Values[valueIndex]
end

function XTheatreConfigs.GetRewardTypeIcon(rewardType, powerId)
    local result = XTheatreConfigs.GetTheatreClientConfig("SpecialRewardIcon").Values[rewardType]
    if rewardType == XTheatreConfigs.AdventureRewardType.SelectSkill then
        if powerId <= 0 then
            XLog.Error("XTheatreConfigs.GetRewardTypeIcon(rewardType, powerId) 错误PowerId", powerId)
        end
        result = string.format(result, XTheatreConfigs.GetClientConfig("SpecialRewardSkillIcon", powerId))
    end
    return result
end

function XTheatreConfigs.GetRewardTypeName(rewardType, powerId)
    local result = XTheatreConfigs.GetTheatreClientConfig("SpecialRewardName").Values[rewardType]
    if rewardType == XTheatreConfigs.AdventureRewardType.SelectSkill then
        result = string.format(result, XTheatreConfigs.GetClientConfig("SpecialRewardSkillName", powerId))
    end
    return result
end

function XTheatreConfigs.GetShopIds()
    local shopIds = {}
    local shopIdByNormal = XTheatreConfigs.GetTheatreConfig("ShopIdByNormal").Value
    local shopIdBySpeical = XTheatreConfigs.GetTheatreConfig("ShopIdBySpecial").Value
    table.insert(shopIds, shopIdByNormal)
    table.insert(shopIds, shopIdBySpeical)
    return shopIds
end

function XTheatreConfigs.GetRoleDetailLevelIcon()
    return XTheatreConfigs.GetTheatreClientConfig("RoleDetailLevelIcon").Values[1]
end

function XTheatreConfigs.GetRoleDetailLevelDesc()
    return XTheatreConfigs.GetTheatreClientConfig("RoleDetailLevelDesc").Values
end

function XTheatreConfigs.GetRoleDetailEquipIcon()
    return XTheatreConfigs.GetTheatreClientConfig("RoleDetailEquipIcon").Values[1]
end

function XTheatreConfigs.GetRoleDetailEquiupDesc()
    return XTheatreConfigs.GetTheatreClientConfig("RoleDetailEquiupDesc").Values
end

function XTheatreConfigs.GetRoleDetailSkillIcon()
    return XTheatreConfigs.GetTheatreClientConfig("RoleDetailSkillIcon").Values[1]
end

function XTheatreConfigs.GetRoleDetailSkillDesc()
    return XTheatreConfigs.GetTheatreClientConfig("RoleDetailSkillDesc").Values
end

function XTheatreConfigs.GetUnlockOwnRole()
    return XTheatreConfigs.GetTheatreClientConfig("UnlockOwnRole").Values
end

function XTheatreConfigs.GetUnlockFavor()
    return XTheatreConfigs.GetTheatreClientConfig("UnlockFavor").Values
end

function XTheatreConfigs.GetUnlockDecoration()
    return XTheatreConfigs.GetTheatreClientConfig("UnlockDecoration").Values
end

function XTheatreConfigs.GetUnlockNewDecoration()
    return XTheatreConfigs.GetTheatreClientConfig("UnlockNewDecoration").Values
end

function XTheatreConfigs.GetSkillPosIcon(index)
    return XTheatreConfigs.GetTheatreClientConfig("SkillPosIcon").Values[index]
end

function XTheatreConfigs.GetFirstStoryId()
    return XTheatreConfigs.GetTheatreClientConfig("FirstStoryId").Values[1]
end

function XTheatreConfigs.GetCheckDecorationGroupIndex()
    local groupIndex = XTheatreConfigs.GetTheatreClientConfig("CheckDecorationGroupIndex").Values[1]
    return groupIndex and tonumber(groupIndex)
end

--region 冒险模式
function XTheatreConfigs.GetSPModeConditionId()
    return XTheatreConfigs.GetTheatreConfig("SPModeConditionId").Value
end

function XTheatreConfigs.GetSPModeOpenTile()
    return XTheatreConfigs.GetTheatreClientConfig("SPModeOpenTile").Values[1]
end

function XTheatreConfigs.GetSPModeCloseTile()
    return XTheatreConfigs.GetTheatreClientConfig("SPModeCloseTile").Values[1]
end
--endregion

------------------TheatreAutoTeam 自动编队 begin----------------------
local _AutoTeamDefaultStageId = 0

local GetTheatreAutoTeamConfig = function(stageId)
    stageId = stageId or _AutoTeamDefaultStageId
    local config = XTheatreConfigs.GetTheatreAutoTeam(stageId)
    if not config then
        config = XTheatreConfigs.GetTheatreAutoTeam(_AutoTeamDefaultStageId)
    end
    return config
end

--获得自动编队的队伍属性优先级
function XTheatreConfigs.GetTheatreAutoTeamElementSortOrder(stageId, elementId, isomer)
    local config = GetTheatreAutoTeamConfig(stageId)
    if isomer then
        return config.IsomerSortOrder
    end
    return config.ElementSortOrder[elementId] or 0
end

--获得自动编队的职业优先级
function XTheatreConfigs.GetTheatreAutoTeamCareerSortOrder(stageId, careerType)
    local config = GetTheatreAutoTeamConfig(stageId)
    return config.CareerSortOrder[careerType] or 0
end

function XTheatreConfigs.GetTheatreAutoTeamIsOnlyOneElement(stageId, elementId)
    local config = GetTheatreAutoTeamConfig(stageId)
    return config.IsOnlyOneElement[elementId]
end
------------------TheatreAutoTeam 自动编队 end------------------------

------------------TheatreStage 关卡 begin----------------------
function XTheatreConfigs.GetTheatreStageCount(id)
    local config = XTheatreConfigs.GetTheatreStage(id)
    return config and config.StageCount or 0
end

function XTheatreConfigs.GetTheatreStageSuggestAbility(id)
    local config = XTheatreConfigs.GetTheatreStage(id)
    return config and config.SuggestAbility or 0
end

function XTheatreConfigs.GetTheatreStageIdList(id)
    local config = XTheatreConfigs.GetTheatreStage(id)
    return config.StageId
end
------------------TheatreStage 关卡 begin----------------------

------------------TheatreDecoration 装修改造 begin----------------------
local IsInitTheatreDecorationDic = false
local TheatreGroupIndexToDecorationIds = {} --组下标对应的装修项Id列表
local TheatreDecorationIdToGridIndex = {} --装修项Id对应的格子下标
local TheatreDecorationIdAndLvToId = {} --装修项Id和等级对应的Id
local TheatreDecorationMaxLv = {} --装修项最大等级
local TheatreCheckWindowsDecorationIdList = {}  --需要检查装修项解锁弹窗的Id列表
local TheatreDecorationIdToIds = {} --装修项Id对应的TheatreDecoration表的Id

local InitTheatreDecorationDic = function()
    if IsInitTheatreDecorationDic then
        return
    end

    local configs = XTheatreConfigs.GetTheatreDecoration()
    for id, config in pairs(configs) do
        if not TheatreGroupIndexToDecorationIds[config.GroupIndex] then
            TheatreGroupIndexToDecorationIds[config.GroupIndex] = {}
        end

        if not TheatreDecorationIdToGridIndex[config.DecorationId] then
            table.insert(TheatreGroupIndexToDecorationIds[config.GroupIndex], config.DecorationId)
            TheatreDecorationIdToGridIndex[config.DecorationId] = config.GridIndex
        end

        if not TheatreDecorationIdAndLvToId[config.DecorationId] then
            TheatreDecorationIdAndLvToId[config.DecorationId] = {}
        end
        TheatreDecorationIdAndLvToId[config.DecorationId][config.Lv] = id

        if not TheatreDecorationMaxLv[config.DecorationId] or TheatreDecorationMaxLv[config.DecorationId] < config.Lv then
            TheatreDecorationMaxLv[config.DecorationId] = config.Lv
        end

        if config.Lv == 0 and config.IsWindow then
            table.insert(TheatreCheckWindowsDecorationIdList, id)
        end

        if not TheatreDecorationIdToIds[config.DecorationId] then
            TheatreDecorationIdToIds[config.DecorationId] = {}
        end
        table.insert(TheatreDecorationIdToIds[config.DecorationId], id)
    end
    IsInitTheatreDecorationDic = true
end

function XTheatreConfigs.GetTheatreDecorationIdToIds(decorationId)
    InitTheatreDecorationDic()
    return TheatreDecorationIdToIds[decorationId] or {}
end

function XTheatreConfigs.GetTheatreGroupIndexToDecorationIds()
    InitTheatreDecorationDic()
    return TheatreGroupIndexToDecorationIds
end

function XTheatreConfigs.GetDecorationIdsByGroupIndex(groupIndex)
    InitTheatreDecorationDic()
    return TheatreGroupIndexToDecorationIds[groupIndex]
end

function XTheatreConfigs.GetTheatreDecorationIds()
    InitTheatreDecorationDic()
    return TheatreDecorationIdToGridIndex
end

function XTheatreConfigs.GetTheatreDecorationIdToGridIndex(decorationId)
    InitTheatreDecorationDic()
    return TheatreDecorationIdToGridIndex[decorationId] or {}
end

function XTheatreConfigs.GetTheatreDecorationIdAndLvToId(decorationId, lv)
    InitTheatreDecorationDic()
    return TheatreDecorationIdAndLvToId[decorationId] and TheatreDecorationIdAndLvToId[decorationId][lv]
end

function XTheatreConfigs.GetTheatreDecorationMaxLv(decorationId)
    InitTheatreDecorationDic()
    return TheatreDecorationMaxLv[decorationId] or 0
end

function XTheatreConfigs.GetDecorationId(id)
    local config = XTheatreConfigs.GetTheatreDecoration(id)
    return config.DecorationId
end

function XTheatreConfigs.GetDecorationLv(id)
    local config = XTheatreConfigs.GetTheatreDecoration(id)
    return config.Lv
end

function XTheatreConfigs.GetDecorationConditionId(id)
    local config = XTheatreConfigs.GetTheatreDecoration(id)
    return config.ConditionId
end

function XTheatreConfigs.GetDecorationUpgradeCost(id)
    local config = XTheatreConfigs.GetTheatreDecoration(id)
    return config.UpgradeCostCount
end

function XTheatreConfigs.GetDecorationGroupIndex(id)
    local config = XTheatreConfigs.GetTheatreDecoration(id)
    return config.GroupIndex
end

function XTheatreConfigs.GetDecorationGridIndex(id)
    local config = XTheatreConfigs.GetTheatreDecoration(id)
    return config.GridIndex
end

function XTheatreConfigs.GetDecorationIcon(id)
    local config = XTheatreConfigs.GetTheatreDecoration(id)
    return config.Icon
end

function XTheatreConfigs.GetDecorationName(id)
    local config = XTheatreConfigs.GetTheatreDecoration(id)
    return config.Name
end

function XTheatreConfigs.GetDecorationDesc(id)
    local config = XTheatreConfigs.GetTheatreDecoration(id)
    return config.Desc
end

function XTheatreConfigs.GetDecorationConditionDesc(id)
    local config = XTheatreConfigs.GetTheatreDecoration(id)
    return config.ConditionDesc
end

function XTheatreConfigs.GetDecorationIsWindow(id)
    local config = XTheatreConfigs.GetTheatreDecoration(id)
    return config.IsWindow
end

function XTheatreConfigs.GetDecorationUpgradeCostItemId(id)
    local config = XTheatreConfigs.GetTheatreDecoration(id)
    return config.UpgradeCostItemId
end

-- 获得需要检查装修项解锁弹窗的Id列表
function XTheatreConfigs.GetCheckWindowDecorationIdList()
    InitTheatreDecorationDic()
    return TheatreCheckWindowsDecorationIdList
end
------------------TheatreDecoration 装修改造 end------------------------

------------------TheatrePowerCondition 势力 begin--------------------
function XTheatreConfigs.GetPowerConditionIdList()
    local powerConditionIdList = {}
    local configs = XTheatreConfigs.GetTheatrePowerCondition()
    for id in pairs(configs) do
        table.insert(powerConditionIdList, id)
    end
    table.sort(powerConditionIdList, function(a, b)
        return a < b
    end)
    return powerConditionIdList
end

function XTheatreConfigs.GetPowerConditionId(id)
    local config = XTheatreConfigs.GetTheatrePowerCondition(id)
    return config.ConditionId
end

function XTheatreConfigs.GetPowerConditionName(id)
    local config = XTheatreConfigs.GetTheatrePowerCondition(id)
    return config.Name
end

function XTheatreConfigs.GetPowerConditionIcon(id)
    local config = XTheatreConfigs.GetTheatrePowerCondition(id)
    return config.Icon
end

function XTheatreConfigs.GetPowerConditionSmallIcon(id)
    local config = XTheatreConfigs.GetTheatrePowerCondition(id)
    return config.SmallIcon
end
------------------TheatrePowerCondition 势力 end----------------------

------------------TheatrePowerFavor 势力好感度 begin--------------------
local TheatrePowerIdAndLvToId = {} --装修项Id和等级对应的Id
local TheatrePowerMaxLv = {} --装修项最大等级
local TheatrePowerIdToPowerFavorIdList = {} --装修项Id对应的所有好感度Id列表
local InitTheatrePowerDic = function()
    local configs = XTheatreConfigs.GetTheatrePowerFavor()
    for id, config in pairs(configs) do
        if not TheatrePowerIdToPowerFavorIdList[config.PowerId] then
            TheatrePowerIdToPowerFavorIdList[config.PowerId] = {}
        end
        table.insert(TheatrePowerIdToPowerFavorIdList[config.PowerId], id)

        if not TheatrePowerIdAndLvToId[config.PowerId] then
            TheatrePowerIdAndLvToId[config.PowerId] = {}
        end
        TheatrePowerIdAndLvToId[config.PowerId][config.Lv] = id

        if not TheatrePowerMaxLv[config.PowerId] or TheatrePowerMaxLv[config.PowerId] < config.Lv then
            TheatrePowerMaxLv[config.PowerId] = config.Lv
        end
    end

    for _, idList in pairs(TheatrePowerIdToPowerFavorIdList) do
        table.sort(idList, function(a, b)
            local lvA = XTheatreConfigs.GetPowerFavorLv(a)
            local lvB = XTheatreConfigs.GetPowerFavorLv(b)
            if lvA ~= lvB then
                return lvA < lvB
            end
            return a < b
        end)
    end
end

function XTheatreConfigs.GetPowerFavorIdListByPowerId(powerId, isRemoveLvZero)
    if XTool.IsTableEmpty(TheatrePowerIdToPowerFavorIdList) then
        InitTheatrePowerDic()
    end

    local powerFavorIdList = XTool.Clone(TheatrePowerIdToPowerFavorIdList[powerId] or {})
    --移除等级0的装修Id
    if isRemoveLvZero then
        local powerFavorId = powerFavorIdList[1]
        local lv = XTheatreConfigs.GetPowerFavorLv(powerFavorId)
        if not XTool.IsNumberValid(lv) then
            table.remove(powerFavorIdList, 1)
        end
    end

    return powerFavorIdList
end

function XTheatreConfigs.GetTheatrePowerIdAndLvToId(powerId, lv)
    if XTool.IsTableEmpty(TheatrePowerIdAndLvToId) then
        InitTheatrePowerDic()
    end
    return TheatrePowerIdAndLvToId[powerId] and TheatrePowerIdAndLvToId[powerId][lv]
end

function XTheatreConfigs.GetTheatrePowerMaxLv(powerId)
    if XTool.IsTableEmpty(TheatrePowerMaxLv) then
        InitTheatrePowerDic()
    end
    return TheatrePowerMaxLv[powerId] or 0
end

function XTheatreConfigs.GetPowerFavorPowerId(id)
    local config = XTheatreConfigs.GetTheatrePowerFavor(id)
    return config.PowerId
end

function XTheatreConfigs.GetPowerFavorLv(id)
    local config = XTheatreConfigs.GetTheatrePowerFavor(id)
    return config.Lv
end

function XTheatreConfigs.GetPowerFavorUpgradeCost(id)
    local config = XTheatreConfigs.GetTheatrePowerFavor(id)
    return config.UpgradeCost
end

function XTheatreConfigs.GetPowerFavorRewardDesc(id)
    local config = XTheatreConfigs.GetTheatrePowerFavor(id)
    return config.RewardDesc
end

function XTheatreConfigs.GetPowerFavorRewardTypes(id)
    local config = XTheatreConfigs.GetTheatrePowerFavor(id)
    return config.RewardType
end

function XTheatreConfigs.GetPowerFavorRewardParams(id)
    local config = XTheatreConfigs.GetTheatrePowerFavor(id)
    return config.RewardParam
end
------------------TheatrePowerFavor 势力好感度 end----------------------

------------------TheatreTask 任务 begin--------------------
local IsInitTheatreTaskDic = false
local TheatreTaskGroupToIdList = {} --任务组下的Id列表
local TheatreTaskMainShowIdList = {} --参与主界面任务显示逻辑的Id列表
local TheatreTaskHaveStartTimeIdList = {} --有开启时间的任务Id列表
local InitTheatreTask = function()
    if IsInitTheatreTaskDic then
        return
    end

    local configs = XTheatreConfigs.GetTheatreTask()
    for id, config in pairs(configs) do
        local groupId = config.GroupId
        if not TheatreTaskGroupToIdList[groupId] then
            TheatreTaskGroupToIdList[groupId] = {}
        end
        table.insert(TheatreTaskGroupToIdList[groupId], id)

        local mainShowOrder = config.MainShowOrder
        if XTool.IsNumberValid(mainShowOrder) then
            table.insert(TheatreTaskMainShowIdList, id)
        end

        local taskIdList = config.TaskId
        for _, taskId in ipairs(taskIdList) do
            if XTaskConfig.GetTaskStartTime(taskId) then
                table.insert(TheatreTaskHaveStartTimeIdList, taskId)
            end
        end
    end

    for _, idList in pairs(TheatreTaskGroupToIdList) do
        table.sort(idList, function(a, b)
            return a < b
        end)
    end

    table.sort(TheatreTaskMainShowIdList, function(a, b)
        local orderA = XTheatreConfigs.GetTaskMainShowOrder(a)
        local orderB = XTheatreConfigs.GetTaskMainShowOrder(b)
        if orderA ~= orderB then
            return orderA < orderB
        end
        return a < b
    end)

    IsInitTheatreTaskDic = true
end

function XTheatreConfigs.GetTheatreTaskIdList(groupId)
    InitTheatreTask()
    return TheatreTaskGroupToIdList[groupId] or {}
end

function XTheatreConfigs.GetTheatreTaskMainShowIdList()
    InitTheatreTask()
    return TheatreTaskMainShowIdList
end

function XTheatreConfigs.GetTheatreTaskHaveStartTimeIdList()
    InitTheatreTask()
    return TheatreTaskMainShowIdList
end

function XTheatreConfigs.GetTaskIdList(id)
    local config = XTheatreConfigs.GetTheatreTask(id)
    return config.TaskId
end

function XTheatreConfigs.GetTaskName(id)
    local config = XTheatreConfigs.GetTheatreTask(id)
    return config.Name
end

function XTheatreConfigs.GetTaskMainShowOrder(id)
    local config = XTheatreConfigs.GetTheatreTask(id)
    return config.MainShowOrder
end

function XTheatreConfigs.GetTaskGroupId(id)
    local config = XTheatreConfigs.GetTheatreTask(id)
    return config.GroupId
end
------------------TheatreTask 任务 end----------------------

------------------TheatreChapter 章节 begin--------------------
local GetDefaultChapterConfig = function()
    local configs = XTheatreConfigs.GetTheatreChapter()
    for _, config in pairs(configs) do
        return config
    end
end

function XTheatreConfigs.GetDefaultChapterId()
    return GetDefaultChapterConfig().Id
end

function XTheatreConfigs.GetChapterIsRecruit(id)
    local config = XTheatreConfigs.GetTheatreChapter(id)
    return config.IsRecruit
end

function XTheatreConfigs.GetCurChapterRecruitMaxCount(id)
    local config = XTheatreConfigs.GetTheatreChapter(id)
    return config.RecruitRefreshCount
end

function XTheatreConfigs.GetChapterSceneUrl(id)
    if not id then
        return GetDefaultChapterConfig().SceneUrl
    end
    local config = XTheatreConfigs.GetTheatreChapter(id)
    return config.SceneUrl
end

function XTheatreConfigs.GetChapterBgA(id)
    if not id then
        return GetDefaultChapterConfig().BgA
    end
    local config = XTheatreConfigs.GetTheatreChapter(id)
    return config.BgA
end

function XTheatreConfigs.GetChapterBgB(id)
    if not id then
        return GetDefaultChapterConfig().BgB
    end
    local config = XTheatreConfigs.GetTheatreChapter(id)
    return config.BgB
end

function XTheatreConfigs.GetChapterModelUrl(id)
    if not id then
        return GetDefaultChapterConfig().ModelUrl
    end
    local config = XTheatreConfigs.GetTheatreChapter(id)
    return config.ModelUrl
end

function XTheatreConfigs.GetChapterRecruitGrid(id)
    local config = XTheatreConfigs.GetTheatreChapter(id)
    return config.RecruitGrid
end

function XTheatreConfigs.GetChapterMultiFightLoadingBg(id)
    local config = XTheatreConfigs.GetTheatreChapter(id)
    return config.MultiFightLoadingBg
end

function XTheatreConfigs.GetChapterTitle(id)
    local config = XTheatreConfigs.GetTheatreChapter(id)
    return config.Title
end
------------------TheatreChapter 章节 end----------------------

------------------TheatreRole 角色总表 begin--------------------
function XTheatreConfigs.GetRolePoolId(id)
    local config = XTheatreConfigs.GetTheatreRole(id)
    return config.PoolId
end
------------------TheatreRole 角色总表 end----------------------

------------------TheatreFieldGuide 图鉴表 begin---------------------
function XTheatreConfigs.GetTheatreFieldGuideIdList(showFieldGuideIds)
    local config = XTheatreConfigs.GetTheatreFieldGuide()
    local idList = {}
    if showFieldGuideIds then
        idList = XTool.Clone(showFieldGuideIds)
    else
        for id in ipairs(config) do
            table.insert(idList, id)
        end
    end

    table.sort(idList, function(a, b)
        local orderA = XTheatreConfigs.GetTheatreFieldGuide(a).Order
        local orderB = XTheatreConfigs.GetTheatreFieldGuide(b).Order
        if orderA ~= orderB then
            return orderA < orderB
        end
        return a < b
    end)
    return idList
end

function XTheatreConfigs.GetTheatreFieldGuideName(id)
    local config = XTheatreConfigs.GetTheatreFieldGuide(id)
    return config.Name
end
------------------TheatreFieldGuide 图鉴表 end-----------------------

------------------TheatreItem 道具表 begin---------------------------
local IsInitTheatreItemDic = false
local TheatreMinLvKeepsakeDic = {}  --等级最低的信物对应的TheatreItem表的Id
local InitTheatreTask = function()
    if IsInitTheatreItemDic then
        return
    end

    local configs = XTheatreConfigs.GetTheatreItem()
    for id, config in pairs(configs) do
        if XTool.IsNumberValid(config.KeepsakeId) then
            local minLvId = TheatreMinLvKeepsakeDic[config.KeepsakeId]
            local lv = minLvId and XTheatreConfigs.GetTheatreItemLv(minLvId)
            if not lv or config.Lv < lv then
                TheatreMinLvKeepsakeDic[config.KeepsakeId] = id
            end
        end
    end

    IsInitTheatreItemDic = true
end

function XTheatreConfigs.GetTheatreMinLvTheatreItemId(keepsakeId)
    InitTheatreTask()
    return TheatreMinLvKeepsakeDic[keepsakeId] or 0
end

function XTheatreConfigs.GetTheatreItemKeepsakeId(id)
    local config = XTheatreConfigs.GetTheatreItem(id)
    return config.KeepsakeId
end

function XTheatreConfigs.GetTheatreItemType(id)
    local config = XTheatreConfigs.GetTheatreItem(id)
    return config.Type
end

function XTheatreConfigs.GetTheatreItemId(id)
    local config = XTheatreConfigs.GetTheatreItem(id)
    return config.ItemId
end

function XTheatreConfigs.GetTheatreItemLv(id)
    local config = XTheatreConfigs.GetTheatreItem(id)
    return config.Lv
end

function XTheatreConfigs.GetTheatreItemExplain(id)
    local config = XTheatreConfigs.GetTheatreItem(id)
    return config.Explain
end

function XTheatreConfigs.GetTheatreItemFightCount(id)
    local config = XTheatreConfigs.GetTheatreItem(id)
    return config.FightCount
end

function XTheatreConfigs.GetTheatreItemQuality(id)
    local config = XTheatreConfigs.GetTheatreItem(id)
    return config.Quality
end
------------------TheatreItem 道具表 end-----------------------------

------------------TheatreKeepsake 信物表 begin-----------------------
function XTheatreConfigs.GetTheatreKeepsakeName(id)
    local config = XTheatreConfigs.GetTheatreKeepsake(id)
    return config.Name
end

function XTheatreConfigs.GetTheatreKeepsakeIcon(id)
    local config = XTheatreConfigs.GetTheatreKeepsake(id)
    return config.Icon
end

function XTheatreConfigs.GetTheatreKeepsakeDescription(id)
    local config = XTheatreConfigs.GetTheatreKeepsake(id)
    return config.Description
end
------------------TheatreKeepsake 信物表 end-------------------------

------------------TheatreLv 等级表 begin-----------------------------
function XTheatreConfigs.GetTheatreLvEquipmentShowLevel(id)
    local config = XTheatreConfigs.GetTheatreLv(id)
    return config.EquipmentShowLevel
end
------------------TheatreLv 等级表 end-------------------------------

------------------TheatreSkillPosDefine 技能位置表 begin-------------
function XTheatreConfigs.GetTheatreSkillPosDefineSkillType(id)
    local config = XTheatreConfigs.GetTheatreSkillPosDefine(id)
    return config and config.SkillType or {}
end
------------------TheatreSkillPosDefine 技能位置表 end---------------

------------------TheatreSkill 技能表 begin--------------------------
function XTheatreConfigs.GetTheatreSkillPowerId(id)
    local config = XTheatreConfigs.GetTheatreSkill(id)
    return config.PowerId
end

function XTheatreConfigs.GetTheatreSkillPos(id)
    local config = XTheatreConfigs.GetTheatreSkill(id)
    return config.Pos
end

function XTheatreConfigs.GetTheatreSkillLv(id)
    local config = XTheatreConfigs.GetTheatreSkill(id)
    return config.Lv
end
------------------TheatreSkill 技能表 end----------------------------