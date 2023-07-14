XChessPursuitConfig = XChessPursuitConfig or {}

local TABLE_CHESSPURSUITBOSS_PATH = "Share/ChessPursuit/ChessPursuitBoss.tab"
local TABLE_CHESSPURSUITCARD_PATH = "Share/ChessPursuit/ChessPursuitCard.tab"
local TABLE_CHESSPURSUITCARDEFFECT_PATH = "Share/ChessPursuit/ChessPursuitCardEffect.tab"
local TABLE_CHESSPURSUITMAP_PATH = "Share/ChessPursuit/ChessPursuitMap.tab"
local TABLE_CHESSPURSUITMAPCARDSHOP_PATH = "Share/ChessPursuit/ChessPursuitMapCardShop.tab"
local TABLE_CHESSPURSUITMAPGROUP_PATH = "Share/ChessPursuit/ChessPursuitMapGroup.tab"
local TABLE_CHESSPURSUITMAPINITFUNC_PATH = "Share/ChessPursuit/ChessPursuitMapInitFunc.tab"
local TABLE_CHESSPURSUITTESTROLE_PATH = "Share/ChessPursuit/ChessPursuitTestRole.tab"
local TABLE_CHESSPURSUITSTEP_PATH = "Client/ChessPursuit/ChessPursuitStep.tab"
local TABLE_CHESS_PURSUIT_MAP_GROUP_REWARD_PATH = "Share/ChessPursuit/ChessPursuitMapGroupReward.tab"

local ChessPursuitBossTemplate = {}
local ChessPursuitCardTemplate = {}
local ChessPursuitCardEffectTemplate = {}
local ChessPursuitMapTemplate = {}
local ChessPursuitMapCardShopTemplate = {}
local ChessPursuitMapGroupTemplate = {}
local ChessPursuitMapInitFuncTemplate = {}
local ChessPursuitTestRoleTemplate = {}
local ChessPursuitStepTemplate = {}
local ChessPursuitMapGroupRewardTemplate = {}

local MapGroupRewardByGroupIdToIdDic = {}

local CSXTextManagerGetText = CS.XTextManager.GetText

--追击玩法商币道具的id
XChessPursuitConfig.SHOP_COIN_ITEM_ID = nil

XChessPursuitConfig.Period = {
    Stable = 0, --安稳期
    Fight = 1, --斗争期
}

XChessPursuitConfig.MEMBER_POS_COLOR = {
    "FF1111FF", -- red
    "4F99FFFF", -- blue
    "F9CB35FF", -- yellow
}

XChessPursuitConfig.InitFuncType = {
    InitAddCoin = 1007,   --完成x地图则增加y的初始货币
}

local function InitMapGroupRewardByGroupIdToIdDic()
    for _, v in ipairs(ChessPursuitMapGroupRewardTemplate) do
        if not MapGroupRewardByGroupIdToIdDic[v.GroupId] then
            MapGroupRewardByGroupIdToIdDic[v.GroupId] = {}
        end
        table.insert(MapGroupRewardByGroupIdToIdDic[v.GroupId], v.Id)
    end
end

function XChessPursuitConfig.Init()
    ChessPursuitBossTemplate = XTableManager.ReadByIntKey(TABLE_CHESSPURSUITBOSS_PATH, XTable.XTableChessPursuitBoss, "Id")
    ChessPursuitCardTemplate = XTableManager.ReadByIntKey(TABLE_CHESSPURSUITCARD_PATH, XTable.XTableChessPursuitCard, "Id")
    ChessPursuitCardEffectTemplate = XTableManager.ReadByIntKey(TABLE_CHESSPURSUITCARDEFFECT_PATH, XTable.XTableChessPursuitCardEffect, "Id")
    ChessPursuitMapTemplate = XTableManager.ReadByIntKey(TABLE_CHESSPURSUITMAP_PATH, XTable.XTableChessPursuitMap, "Id")
    ChessPursuitMapCardShopTemplate = XTableManager.ReadByIntKey(TABLE_CHESSPURSUITMAPCARDSHOP_PATH, XTable.XTableChessPursuitMapCardShop, "Id")
    ChessPursuitMapGroupTemplate = XTableManager.ReadByIntKey(TABLE_CHESSPURSUITMAPGROUP_PATH, XTable.XTableChessPursuitMapGroup, "Id")
    ChessPursuitMapInitFuncTemplate = XTableManager.ReadByIntKey(TABLE_CHESSPURSUITMAPINITFUNC_PATH, XTable.XTableChessPursuitMapInitFunc, "Id")
    ChessPursuitTestRoleTemplate = XTableManager.ReadByIntKey(TABLE_CHESSPURSUITTESTROLE_PATH, XTable.XTableChessPursuitTestRole, "Id")
    ChessPursuitStepTemplate = XTableManager.ReadByIntKey(TABLE_CHESSPURSUITSTEP_PATH, XTable.XTableChessPursuitStep, "Id")
    ChessPursuitMapGroupRewardTemplate = XTableManager.ReadByIntKey(TABLE_CHESS_PURSUIT_MAP_GROUP_REWARD_PATH, XTable.XTableChessPursuitMapGroupReward, "Id")

    XChessPursuitConfig.SHOP_COIN_ITEM_ID = ChessPursuitMapTemplate[1].CoinId
    InitMapGroupRewardByGroupIdToIdDic()
end

--@region 各个表的主Get函数
function XChessPursuitConfig.GetChessPursuitBossTemplate(id)
    local data = ChessPursuitBossTemplate[id]
    if not data then
        XLog.ErrorTableDataNotFound("XChessPursuitConfig.GetChessPursuitBossTemplate", "data", TABLE_CHESSPURSUITBOSS_PATH, "id", tostring(id))
        return nil
    end

    return data
end

function XChessPursuitConfig.GetChessPursuitCardTemplate(id)
    local data = ChessPursuitCardTemplate[id]
    if not data then
        XLog.ErrorTableDataNotFound("XChessPursuitConfig.GetChessPursuitCardTemplate", "data", TABLE_CHESSPURSUITCARD_PATH, "id", tostring(id))
        return nil
    end

    return data
end

function XChessPursuitConfig.GetChessPursuitCardEffectTemplate(id)
    local data = ChessPursuitCardEffectTemplate[id]
    if not data then
        XLog.ErrorTableDataNotFound("XChessPursuitConfig.GetChessPursuitCardEffectTemplate", "data", TABLE_CHESSPURSUITCARDEFFECT_PATH, "id", tostring(id))
        return nil
    end

    return data
end

function XChessPursuitConfig.GetChessPursuitStepTemplate(id)
    local data = ChessPursuitStepTemplate[id]
    if not data then
        XLog.ErrorTableDataNotFound("XChessPursuitConfig.GetChessPursuitStepTemplate", "data", TABLE_CHESSPURSUITSTEP_PATH, "id", tostring(id))
        return nil
    end

    return data
end

function XChessPursuitConfig.GetChessPursuitMapTemplate(id)
    local data = ChessPursuitMapTemplate[id]
    if not data then
        XLog.ErrorTableDataNotFound("XChessPursuitConfig.GetChessPursuitMapTemplate", "data", TABLE_CHESSPURSUITMAP_PATH, "id", tostring(id))
        return nil
    end

    return data
end

function XChessPursuitConfig.GetChessPursuitMapCardShopTemplate(id)
    local data = ChessPursuitMapCardShopTemplate[id]
    if not data then
        XLog.ErrorTableDataNotFound("XChessPursuitConfig.GetChessPursuitMapCardShopTemplate", "data", TABLE_CHESSPURSUITMAPCARDSHOP_PATH, "id", tostring(id))
        return nil
    end

    return data
end

function XChessPursuitConfig.GetChessPursuitMapGroupTemplate(id)
    local data = ChessPursuitMapGroupTemplate[id]
    if not data then
        XLog.ErrorTableDataNotFound("XChessPursuitConfig.GetChessPursuitMapGroupTemplate", "data", TABLE_CHESSPURSUITMAPGROUP_PATH, "id", tostring(id))
        return nil
    end

    return data
end

function XChessPursuitConfig.GetChessPursuitMapInitFuncTemplate(id)
    local data = ChessPursuitMapInitFuncTemplate[id]
    if not data then
        XLog.ErrorTableDataNotFound("XChessPursuitConfig.GetChessPursuitMapInitFuncTemplate", "data", TABLE_CHESSPURSUITMAPINITFUNC_PATH, "id", tostring(id))
        return nil
    end

    return data
end

function XChessPursuitConfig.GetChessPursuitTestRoleTemplate(id)
    local data = ChessPursuitTestRoleTemplate[id]
    if not data then
        XLog.ErrorTableDataNotFound("XChessPursuitConfig.GetChessPursuitTestRoleTemplate", "data", TABLE_CHESSPURSUITTESTROLE_PATH, "id", tostring(id))
        return nil
    end

    return data
end

function XChessPursuitConfig.GetChessPursuitMapGroupRewardTemplate(id)
    local data = ChessPursuitMapGroupRewardTemplate[id]
    if not data then
        XLog.ErrorTableDataNotFound("XChessPursuitConfig.GetChessPursuitMapGroupRewardTemplate", "data", TABLE_CHESS_PURSUIT_MAP_GROUP_REWARD_PATH, "id", tostring(id))
        return nil
    end

    return data
end
--@endregion

--@region 各表的衍生方法

function XChessPursuitConfig.GetChessPursuitTestRoleRoleIds(id)
    local data = XChessPursuitConfig.GetChessPursuitTestRoleTemplate(id)
    local roleIds = {}
    for i,v in ipairs(data.RoleId) do
        table.insert(roleIds, v)
    end

    return roleIds
end

function XChessPursuitConfig.GetAllChessPursuitBossTemplate()
    return ChessPursuitBossTemplate
end

function XChessPursuitConfig.GetChessPursuitMapsByGroupId(groupId)
    local tl = {}
    for i,v in ipairs(ChessPursuitMapTemplate) do
        if v.GroupId == groupId then
            table.insert(tl, v)
        end
    end
    
    return tl
end


function XChessPursuitConfig.GetChessPursuitMapByUiType(uiType)
    local groupId = XChessPursuitConfig.GetCurrentGroupId()
    local mapsCfg = XChessPursuitConfig.GetChessPursuitMapsByGroupId(groupId)
    
    for _,cfg in ipairs(mapsCfg) do
        if uiType == cfg.Stage then
            return cfg
        end
    end
end


function XChessPursuitConfig.CheckChessPursuitMapIsOpen(mapId)
    local cfg = ChessPursuitMapTemplate[mapId]
    for i,condition in ipairs(cfg.OpenCondition) do
        if condition > 0 then
            local isOpen, desc = XConditionManager.CheckCondition(condition)
            return isOpen
        end
    end

    return true
end

function XChessPursuitConfig.GetChessPursuitInTimeMapGroup()
    local nowTime = XTime.GetServerNowTimestamp()
    for i, config in pairs(ChessPursuitMapGroupTemplate) do
        local beginTime = XFunctionManager.GetStartTimeByTimeId(config.TimeId)
        local endTime = XFunctionManager.GetEndTimeByTimeId(config.TimeId)
        if nowTime >= beginTime and nowTime < endTime then
            return config
        end
    end
end

function XChessPursuitConfig.GetActivityBeginTime()
    local config = XChessPursuitConfig.GetChessPursuitInTimeMapGroup()
    if not config then
        return 0
    end
    return XFunctionManager.GetStartTimeByTimeId(config.TimeId)
end

function XChessPursuitConfig.GetActivityEndTime()
    local config = XChessPursuitConfig.GetChessPursuitInTimeMapGroup()
    if not config then
        return 0
    end
    return XFunctionManager.GetEndTimeByTimeId(config.TimeId)
end

function XChessPursuitConfig.GetActivityFullBeginTime()
    local config = ChessPursuitMapGroupTemplate[1]
    if not config then
        return 0
    end
    return XFunctionManager.GetStartTimeByTimeId(config.TimeId)
end

function XChessPursuitConfig.GetActivityFullEndTime()
    local endTime = 0
    local endTimeTemp = 0
    for _, v in pairs(ChessPursuitMapGroupTemplate) do
        endTimeTemp = XFunctionManager.GetEndTimeByTimeId(v.TimeId)
        if endTimeTemp > endTime then
            endTime = endTimeTemp
        end
    end
    return endTime
end

function XChessPursuitConfig.GetCurrentGroupId()
    local cfg = XChessPursuitConfig.GetChessPursuitInTimeMapGroup()
    if cfg then
        return cfg.Id
    end
end

function XChessPursuitConfig.GetChessPursuitMapTeamGridList(mapId)
    local cfg = XChessPursuitConfig.GetChessPursuitMapTemplate(mapId)
    return cfg.TeamGrid
end

function XChessPursuitConfig.GetTeamGridIndexByPos(id, pos)
    local cfg = XChessPursuitConfig.GetChessPursuitMapTemplate(id)
    for i,v in ipairs(cfg.TeamGrid) do
        if pos == v then
            return i
        end
    end
end

function XChessPursuitConfig.GetChessPursuitStepTemplateByStep(step)
    for i,v in ipairs(ChessPursuitStepTemplate) do
        if v.Step == step then
            return v
        end
    end
end

function XChessPursuitConfig.CheckIsHaveStepCfgByCardEffectId(id)
    local data = ChessPursuitStepTemplate[id]

    if data then
        return true
    else
        return false
    end
end

function XChessPursuitConfig.IsChessPursuitMapGroupOpen(mapGroupId)
    if not mapGroupId then
        return false
    end
    local nowTime = XTime.GetServerNowTimestamp()
    local config = XChessPursuitConfig.GetChessPursuitMapGroupTemplate(mapGroupId)
    local beginTime = XFunctionManager.GetStartTimeByTimeId(config.TimeId)
    local endTime = XFunctionManager.GetEndTimeByTimeId(config.TimeId)
    if nowTime >= beginTime and nowTime < endTime then
        return true
    end
    return false
end

--判断当前的地图是否已经关闭
function XChessPursuitConfig.IsTimeOutByMapId(mapId)
    local cfg = XChessPursuitConfig.GetChessPursuitMapTemplate(mapId)
    local groupCfg = XChessPursuitConfig.GetChessPursuitMapGroupTemplate(cfg.GroupId)
    local endTime = XFunctionManager.GetEndTimeByTimeId(groupCfg.TimeId)

    local nowTime = XTime.GetServerNowTimestamp()
    if nowTime >= endTime then
        return true
    else
        return false
    end
end

--获取group处于哪个时期
function XChessPursuitConfig.GetStageTypeByGroupId(groupId)
    local mapsCfg = XChessPursuitConfig.GetChessPursuitMapsByGroupId(groupId)
    
    local cfg = mapsCfg[1]
    if cfg.Stage == 1 then
        return XChessPursuitCtrl.MAIN_UI_TYPE.STABLE
    elseif cfg.Stage == 2 then
        return XChessPursuitCtrl.MAIN_UI_TYPE.FIGHT_DEFAULT
    elseif cfg.Stage == 3 then
        return XChessPursuitCtrl.MAIN_UI_TYPE.FIGHT_HARD
    end
end

----------地图组 begin---------
function XChessPursuitConfig.GetChessPursuitMapGroupRank(id)
    local config = XChessPursuitConfig.GetChessPursuitMapGroupTemplate(id)
    return config.Rank
end

function XChessPursuitConfig.GetChessPursuitActivityNameByMapId(mapId)
    local mapGroupId = XChessPursuitConfig.GetChessPursuitMapGroupId(mapId)
    local config = XChessPursuitConfig.GetChessPursuitMapGroupTemplate(mapGroupId)
    return config.ActivityName
end

function XChessPursuitConfig.GetCurrentMapId()
    local currGroupId = XChessPursuitConfig.GetCurrentGroupId()
    local groupId, isOpen, mapId
    for i = #ChessPursuitMapTemplate, 1, -1 do
        groupId = ChessPursuitMapTemplate[i].GroupId
        mapId = ChessPursuitMapTemplate[i].Id
        isOpen = XChessPursuitConfig.CheckChessPursuitMapIsOpen(mapId)
        if currGroupId == groupId and isOpen then
            return mapId
        end
    end
end

function XChessPursuitConfig.GetMapIdListByGroupId(groupId)
    local mapIdList = {}
    for _, v in ipairs(ChessPursuitMapTemplate) do
        if v.GroupId == groupId then
            table.insert(mapIdList, v.Id)
        end
    end
    return mapIdList
end
----------地图组 end---------

----------地图 begin---------
function XChessPursuitConfig.GetChessPursuitMapShopCardId(id)
    local config = XChessPursuitConfig.GetChessPursuitMapTemplate(id)
    return config.ShopCardId
end

function XChessPursuitConfig.GetChessPursuitMapAddCoin(id)
    local config = XChessPursuitConfig.GetChessPursuitMapTemplate(id)
    return config.AddCoin
end

function XChessPursuitConfig.GetChessPursuitMapCardMaxCount(id)
    local config = XChessPursuitConfig.GetChessPursuitMapTemplate(id)
    return config.CardMaxCount
end

function XChessPursuitConfig.GetChessPursuitMapCoinId(id)
    local config = XChessPursuitConfig.GetChessPursuitMapTemplate(id)
    return config.CoinId
end

function XChessPursuitConfig.GetChessPursuitMapGroupId(id)
    local config = XChessPursuitConfig.GetChessPursuitMapTemplate(id)
    return config.GroupId
end

function XChessPursuitConfig.IsChessPursuitMapCanAutoClear(id)
    local config = XChessPursuitConfig.GetChessPursuitMapTemplate(id)
    return config.IsCanAutoClear == 1
end

function XChessPursuitConfig.GetChessPursuitMapBossId(id)
    local config = XChessPursuitConfig.GetChessPursuitMapTemplate(id)
    return config.BossId
end

function XChessPursuitConfig.GetChessPursuitMapInitFuncList(id)
    local config = XChessPursuitConfig.GetChessPursuitMapTemplate(id)
    return config.InitFunc
end

function XChessPursuitConfig.GetChessPursuitMapFinishAddCoin(id)
    local config = XChessPursuitConfig.GetChessPursuitMapTemplate(id)
    return config.FinishAddCoin
end
----------地图 end---------

-------商店 begin---------
function XChessPursuitConfig.GetShopCardIdList(id)
    local config = XChessPursuitConfig.GetChessPursuitMapCardShopTemplate(id)
    local cardIdList = {}
    for _, cardId in ipairs(config.CardId) do
        if cardId > 0 then
            table.insert(cardIdList, cardId)
        end
    end
    return cardIdList
end
-------商店 end-----------

-------卡牌 begin----------
function XChessPursuitConfig.GetCardName(id)
    local config = XChessPursuitConfig.GetChessPursuitCardTemplate(id)
    return config.Name
end

function XChessPursuitConfig.GetCardDescribe(id)
    local config = XChessPursuitConfig.GetChessPursuitCardTemplate(id)
    return string.gsub(config.Describe, "\\n", "\n")
end

function XChessPursuitConfig.GetCardIcon(id)
    local config = XChessPursuitConfig.GetChessPursuitCardTemplate(id)
    return config.Icon
end

function XChessPursuitConfig.GetCardQualityIcon(id)
    local config = XChessPursuitConfig.GetChessPursuitCardTemplate(id)
    return config.QualityIcon
end

function XChessPursuitConfig.GetShopBgQualityIcon(id)
    local config = XChessPursuitConfig.GetChessPursuitCardTemplate(id)
    return config.ShopBgQualityIcon
end

function XChessPursuitConfig.GetCardSubCoin(id)
    local config = XChessPursuitConfig.GetChessPursuitCardTemplate(id)
    return config.SubCoin
end

function XChessPursuitConfig.GetCardQuality(id)
    local config = XChessPursuitConfig.GetChessPursuitCardTemplate(id)
    return config.Quality
end

function XChessPursuitConfig.GetCardEffect(id)
    local config = XChessPursuitConfig.GetChessPursuitCardTemplate(id)
    return config.Effect
end

function XChessPursuitConfig.GetCardTipsQualityIconBg(id)
    local config = XChessPursuitConfig.GetChessPursuitCardTemplate(id)
    return config.TipsQualityIconBg
end
-------卡牌 end----------

-------奖励 begin---------
function XChessPursuitConfig.GetMapGroupRewardByGroupIdToIdDic(groupId)
    return MapGroupRewardByGroupIdToIdDic[groupId]
end

function XChessPursuitConfig.GetMapGroupRewardStartRange(id)
    local config = XChessPursuitConfig.GetChessPursuitMapGroupRewardTemplate(id)
    return config.StartRange
end

function XChessPursuitConfig.GetMapGroupRewardEndRange(id)
    local config = XChessPursuitConfig.GetChessPursuitMapGroupRewardTemplate(id)
    return config.EndRange
end

function XChessPursuitConfig.GetMapGroupRewardRewardShowId(id)
    local config = XChessPursuitConfig.GetChessPursuitMapGroupRewardTemplate(id)
    return config.RewardShowId
end
-------奖励 end-----------

-------Boss begin---------
function XChessPursuitConfig.GetChessPursuitBossStageIdByMapId(mapId)
    local bossId = XChessPursuitConfig.GetChessPursuitMapBossId(mapId)
    local config = XChessPursuitConfig.GetChessPursuitBossTemplate(bossId)
    return config.StageId
end

function XChessPursuitConfig.GetChessPursuitBossHeadIconByMapId(mapId)
    local bossId = XChessPursuitConfig.GetChessPursuitMapBossId(mapId)
    local config = XChessPursuitConfig.GetChessPursuitBossTemplate(bossId)
    return config.HeadIcon
end
-------Boss end-----------

------ChessPursuitMapInitFunc begin-------
function XChessPursuitConfig.GetMapInitFuncMapId(id)
    local config = XChessPursuitConfig.GetChessPursuitMapInitFuncTemplate(id)
    return config.Param[1]
end

function XChessPursuitConfig.GetMapInitFuncType(id)
    local config = XChessPursuitConfig.GetChessPursuitMapInitFuncTemplate(id)
    return config.Type
end

function XChessPursuitConfig.IsMapInitFuncAddCoinType(id)
    local initFuncType = XChessPursuitConfig.GetMapInitFuncType(id)
    return initFuncType == XChessPursuitConfig.InitFuncType.InitAddCoin
end
------ChessPursuitMapInitFunc end-------

function XChessPursuitConfig.GetBabelRankIcon(num)
    return CS.XGame.ClientConfig:GetString("BabelTowerRankIcon" .. num)
end
--@endregion