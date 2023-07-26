local TABLE_COLLECT_CARD_ITEM_CONFIG = "Share/FestivalActivity/CollectWords/CollectWords.tab"
local TABLE_COLLECT_CARD_REWARD = "Share/FestivalActivity/CollectWords/CollectWordsReward.tab"
local TABLE_SMASH_EGGS_BUFF_ITEM = "Share/FestivalActivity/SmashEggs/SmashEggsBuffItem.tab"
local TABLE_SMASH_EGGS_REWARD = "Share/FestivalActivity/SmashEggs/SmashEggsActivationReward.tab"
local TABLE_SMASH_EGGS_SCORE_CONFIG = "Share/FestivalActivity/SmashEggs/SmashEggsScoreConfig.tab"
local TABLE_SPRING_FESTIVAL_ACTIVITY = "Share/FestivalActivity/SpringFestivalActivity.tab"

local pairs = pairs
local tableInsert = table.insert
local tableSort = table.sort
XSpringFestivalActivityConfigs = XSpringFestivalActivityConfigs or {}
XSpringFestivalActivityConfigs.CollectCardType = {
    Up = 1, --上阕
    Down = 2, --下阕
    Universal = 3, --万能字
}
XSpringFestivalActivityConfigs.COLLECT_WORD_HELP_KEY = "COLLECT_WORD_HELP_KEY"
XSpringFestivalActivityConfigs.SMASH_EGGS_HELP_KEY = "SMASH_EGGS_HELP_KEY"
XSpringFestivalActivityConfigs.CollectWordsRewardType = {
    Up = 1, --上阕奖励
    Down = 2, --下阕奖励
    Final = 3, --终极大奖
}

XSpringFestivalActivityConfigs.ShowItem = {
    [XSpringFestivalActivityConfigs.CollectWordsRewardType.Up] = 62310,
    [XSpringFestivalActivityConfigs.CollectWordsRewardType.Down] = 62311,
    [XSpringFestivalActivityConfigs.CollectWordsRewardType.Final] = 62312
}

XSpringFestivalActivityConfigs.WordsGiftFromType = {
    None = 0,
    Friend = 1, --好友
    Guild = 2, --工会
}

XSpringFestivalActivityConfigs.BuffItem = {
    SilverHammer = 1,
    GoldHammer = 2,
    LuckyBag = 3,
    Amulet = 4,
    Money = 5,
}

XSpringFestivalActivityConfigs.BuffType = {
    Hammer = 1, --锤子
    Additive = 2, --加成道具
    Guaranteed = 3, --保底道具
}

XSpringFestivalActivityConfigs.SmashSoundId = {
    HammerFail = 844,
    EggFail = 845,
    HammerSuccess = 846,
    EggSuccess = 847,
    SuccessEffectSound = 848
}
local CollectWordsTemplate = {}
local CollectWordsActivityConfig = {}
local CollectWordsReward = {}
local SmashEggsBuffItem = {}
local SmashEggsActivityConfig = {}
local SmashEggsRewardTemplate = {}
local SmashEggsScoreConfig = {}
local CollectWordsDic = {}
local SpringFestivalActivity = {}

local InitCollectWordsTemplate = function()
    CollectWordsTemplate = XTableManager.ReadByIntKey(TABLE_COLLECT_CARD_ITEM_CONFIG, XTable.XTableCollectWords, "Id")
    for k, v in pairs(CollectWordsTemplate) do
        local type = v.Type
        if type and type > 0 then
            if CollectWordsDic[type] then
                tableInsert(CollectWordsDic[type], v)
            else
                CollectWordsDic[type] = { v }
            end
        end
    end
end

function XSpringFestivalActivityConfigs.Init()
    InitCollectWordsTemplate()
    SmashEggsBuffItem = XTableManager.ReadByIntKey(TABLE_SMASH_EGGS_BUFF_ITEM, XTable.XTableSmashEggsBuffItem, "Id")
    SmashEggsRewardTemplate = XTableManager.ReadByIntKey(TABLE_SMASH_EGGS_REWARD, XTable.XTableSmashEggsActivation, "Id")
    SmashEggsScoreConfig = XTableManager.ReadByIntKey(TABLE_SMASH_EGGS_SCORE_CONFIG, XTable.XTableSmashEggsScoreConfig, "Id")
    CollectWordsReward = XTableManager.ReadByIntKey(TABLE_COLLECT_CARD_REWARD, XTable.XTableCollectWordsReward, "Id")
    SpringFestivalActivity = XTableManager.ReadByIntKey(TABLE_SPRING_FESTIVAL_ACTIVITY,XTable.XTableSpringFestivalActivity,"Id")
end



---------------------集字相关 begin----------------------
local GetCollectWordsActivity = function(id)
    local template = CollectWordsActivityConfig[id]
    if not template then
        XLog.Error("XSpringFestivalActivityConfigs GetCollectWordsActivity:配置不存在，活动id:" .. id)
        return
    end
    return template
end

function XSpringFestivalActivityConfigs.GetCollectWordsActivityTimeId()
    local config = GetCollectWordsActivity(1)
    return config.TimeId
end

function XSpringFestivalActivityConfigs.GetCollectWordsActivityName()
    local config = GetCollectWordsActivity(1)
    return config.Name
end

function XSpringFestivalActivityConfigs.GetCollectWordsActivityBg()
    local config = GetCollectWordsActivity(1)
    return config.Background
end

local GetCollectWordsRewardTemplate = function(id)
    local template = CollectWordsReward[id]
    if not template then
        XLog.Error("XSpringFestivalActivityConfigs GetCollectWordsRewardTemplate:配置不存在 id:" .. id)
        return
    end
    return template
end

function XSpringFestivalActivityConfigs.GetCollectWordsRewardMagnaItem(id)
    local config = GetCollectWordsRewardTemplate(id)
    return config.MagnaItem
end

function XSpringFestivalActivityConfigs.GetCollectWordsRewardsList(id)
    local config = GetCollectWordsRewardTemplate(id)
    return config.Reward
end

function XSpringFestivalActivityConfigs.GetCollectWordsRewardCostItemList(id)
    local config = GetCollectWordsRewardTemplate(id)
    return config.CostItem
end

function XSpringFestivalActivityConfigs.GetCollectWordsRewardCostCountList(id)
    local config = GetCollectWordsRewardTemplate(id)
    return config.CostCount
end

function XSpringFestivalActivityConfigs.GetCollectWordsRewardMaxCount(id)
    local itemList = XSpringFestivalActivityConfigs.GetCollectWordsRewardsList(id)
    return #itemList
end

function XSpringFestivalActivityConfigs.GetWordsItemListByType(type)
    if not CollectWordsDic[type] then
        XLog.Error("XSpringFestivalActivityConfigs.GetWordsItemByType 没有对应类型的字:type:" .. type)
        return {}
    end
    local temp = {}
    for _, wordTemplate in pairs(CollectWordsDic[type]) do
        tableInsert(temp, wordTemplate)
    end
    tableSort(temp, function(a, b)
        return a.Id < b.Id
    end)
    return temp
end

function XSpringFestivalActivityConfigs.GetCollectWordsTemplate()
    return CollectWordsTemplate
end
function XSpringFestivalActivityConfigs.GetCollectWordsTemplateOrderFunc(compareFunc)
    local list = {}
    for _,v in pairs(CollectWordsTemplate) do
        tableInsert(list,v)
    end
    tableSort(list,compareFunc)
    return list
end

function XSpringFestivalActivityConfigs.GetWordItemsEventId()
    local events = {}
    for id,_ in pairs(CollectWordsTemplate) do
        tableInsert(events,XEventId.EVENT_ITEM_COUNT_UPDATE_PREFIX..id)
    end
    return events
end
---------------------集字相关 end------------------------
---------------------砸蛋相关 begin------------------------
local GetSmashEggsActivity = function(id)
    local template = SmashEggsActivityConfig[id]
    if not template then
        XLog.Error("XSpringFestivalActivityConfigs GetSmashEggsActivity:配置不存在，活动id:" .. id)
        return
    end
    return template
end

function XSpringFestivalActivityConfigs.GetSmashEggsActivityTimeId()
    local config = GetSmashEggsActivity(1)
    return config.TimeId
end

function XSpringFestivalActivityConfigs.GetSmashEggsActivityName()
    local config = GetSmashEggsActivity(1)
    return config.Name
end

function XSpringFestivalActivityConfigs.GetSmashEggsActivityBackground()
    local config = GetSmashEggsActivity(1)
    return config.Background
end

local GetSmashEggsBuffItem = function(id)
    local template = SmashEggsBuffItem[id]
    if not template then
        XLog.Error("XSpringFestivalActivityConfigs GetSmashEggsBuffItem:配置不存在，Id:" .. id)
        return
    end
    return template
end

function XSpringFestivalActivityConfigs.GetBuffItemDesc(id)
    local config = GetSmashEggsBuffItem(id)
    return config.Desc
end

function XSpringFestivalActivityConfigs.GetBuffItemItemId(id)
    local config = GetSmashEggsBuffItem(id)
    return config.ItemId
end

function XSpringFestivalActivityConfigs.GetBuffItemName(id)
    local config = GetSmashEggsBuffItem(id)
    return config.Name
end

function XSpringFestivalActivityConfigs.IsBuffItemFree(id)
    local config = GetSmashEggsBuffItem(id)
    return config.IsFree
end

function XSpringFestivalActivityConfigs.GetBuffItemInitCount(id)
    local config = GetSmashEggsBuffItem(id)
    return config.InitCount
end

function XSpringFestivalActivityConfigs.GetBuffItemBuffType(id)
    local config = GetSmashEggsBuffItem(id)
    return config.BuffType
end

function XSpringFestivalActivityConfigs.GetBuffItemBuffProb(id)
    local config = GetSmashEggsBuffItem(id)
    return config.BuffProb
end

function XSpringFestivalActivityConfigs.GetBuffItemReduction(id)
    local config = GetSmashEggsBuffItem(id)
    return config.Reduction
end

function XSpringFestivalActivityConfigs.GetBuffItemsByType(type)
    local list = {}
    for k, v in pairs(SmashEggsBuffItem) do
        if v.BuffType and v.BuffType == type then
            tableInsert(list,v)
        end
    end
    return list
end

local GetSmashEggsScoreConfig = function(id)
    local template = SmashEggsScoreConfig[id]
    if not template then
        XLog.Error("XSpringFestivalActivityConfigs GetSmashEggsScoreConfig 配置不存在，id：" .. id)
        return
    end
    return template
end

function XSpringFestivalActivityConfigs.GetInitScore()
    local config = GetSmashEggsScoreConfig(1)
    return config.InitScore
end

function XSpringFestivalActivityConfigs.GetAddScore()
    local config = GetSmashEggsScoreConfig(1)
    return config.AddScore
end

function XSpringFestivalActivityConfigs.GetFailureScore()
    local config = GetSmashEggsScoreConfig(1)
    return config.FailureScore
end

function XSpringFestivalActivityConfigs.GetMaxScore()
    local config = GetSmashEggsScoreConfig(1)
    return config.MaxScore
end

function XSpringFestivalActivityConfigs.GetSucceedDropId()
    local config = GetSmashEggsScoreConfig(1)
    return config.SucceedDropId
end

function XSpringFestivalActivityConfigs.GetFailureDropId()
    local config = GetSmashEggsScoreConfig(1)
    return config.FailureDropId
end

function XSpringFestivalActivityConfigs.GetScoreConvertItemId()
    local config = GetSmashEggsScoreConfig(1)
    return config.ScoreConvertItemId
end

function XSpringFestivalActivityConfigs.GetNeedTipCount()
    local config = GetSmashEggsScoreConfig(1)
    return config.NeedTipCount
end

local GetSmashEggsRewardTemplate = function(day, index)
    for k, v in pairs(SmashEggsRewardTemplate) do
        if v.Day == day and v.Index == index then
            return v
        end
    end
    XLog.Error("XSpringFestivalActivityConfig GetSmashEggsRewardTemplate:配置不存在 day:{0},index:{1}", day, index)
    return {}
end

local GetSmashEggsRewardTemplateByDay = function(day)
    local temp = {}
    for k, v in pairs(SmashEggsRewardTemplate) do
        if v.Day == day then
            tableInsert(temp, v)
        end
    end
    return temp
end

function XSpringFestivalActivityConfigs.GetSmashRewardTemplateByNowDay(day)
    return GetSmashEggsRewardTemplateByDay(day)
end

function XSpringFestivalActivityConfigs.GetSmashRewardMaxScoreByDay(day)
    local template = GetSmashEggsRewardTemplateByDay(day)
    local max = 0
    for _,info in pairs(template) do
        if info.TargetScore > max then
            max = info.TargetScore
        end
    end
    return max
end

function XSpringFestivalActivityConfigs.GetSmashEggsRewardTargetScore(day, index)
    local config = GetSmashEggsRewardTemplate(day, index)
    return config.TargetScore or 0
end

function XSpringFestivalActivityConfigs.GetSmashEggsRewardRewardId(day, index)
    local config = GetSmashEggsRewardTemplate(day, index)
    return config.RewardId
end

function XSpringFestivalActivityConfigs.GetSmashEggsRewardDropid(day, index)
    local config = GetSmashEggsRewardTemplate(day, index)
    return config.DropId or 0
end

---------------------砸蛋相关 end------------------------

local GetSpringFestivalActivityConfig = function()
    local config = SpringFestivalActivity[1]
    if not config then
        XLog.Error("XSpringFestivalActivityConfigs.GetSpringFestivalActivityConfig:配置不存在")
        return
    end
    return config
end

function XSpringFestivalActivityConfigs.GetSpringFestivalActivityId()
    local config = GetSpringFestivalActivityConfig()
    return config.Id
end

function XSpringFestivalActivityConfigs.GetSpringFestivalActivityBg()
    local config = GetSpringFestivalActivityConfig()
    return config.Background
end

function XSpringFestivalActivityConfigs.GetSpringFestivalActivityTimeId()
    local config = GetSpringFestivalActivityConfig()
    return config.TimeId
end

function XSpringFestivalActivityConfigs.GetSpringFestivalActivityName()
    local config = GetSpringFestivalActivityConfig()
    return config.Name
end

function XSpringFestivalActivityConfigs.GetSpringFestivalActivityChapterId()
    local config = GetSpringFestivalActivityConfig()
    return config.ChapterId
end

function XSpringFestivalActivityConfigs.GetSpringFestivalActivitySkipId()
    local config = GetSpringFestivalActivityConfig()
    return config.ActivitySkipId
end 

function XSpringFestivalActivityConfigs.GetSpringFestivalActivityShopSkipId()
    local config = GetSpringFestivalActivityConfig()
    return config.ShopSkipId
end

function XSpringFestivalActivityConfigs.GetSpringFestivalActivityTaskActivityId()
    local config = GetSpringFestivalActivityConfig()
    return config.TaskActivityId
end

function XSpringFestivalActivityConfigs.GetSpringFestivalActivityCollectSkipId()
    local config = GetSpringFestivalActivityConfig()
    return config.CollectSkipId
end

function XSpringFestivalActivityConfigs.GetSpringFestivalCollectActivityId()
    local config = GetSpringFestivalActivityConfig()
    return config.CollectActivityId
end

function XSpringFestivalActivityConfigs.GetCollectHelpId()
    local config = GetSpringFestivalActivityConfig()
    return config.CollectHelpId
end

function XSpringFestivalActivityConfigs.GetSmashEggsHelpId()
    local config = GetSpringFestivalActivityConfig()
    return config.SmashEggsHelpId
end 