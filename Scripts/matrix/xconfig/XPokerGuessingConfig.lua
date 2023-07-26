XPokerGuessingConfig = XPokerGuessingConfig or  {}
local pairs = pairs
XPokerGuessingConfig.GameStatus = {
    Initialize = 0,             --初始化（未点开始时）
    Process = 1,                --进行中（猜牌前）
    Failed = 2,                 --失败(猜错)
    Victory = 3,                --普通胜利(猜对可以继续)
    LibraryEmpty = 4,           --牌库空(决定是否继续)
    Drawn = 5,                  --平局
}

XPokerGuessingConfig.GuessType = {
    Less = 0,       --小于
    Greater = 1,    --大于
    Equal = 2,      --等于
}

XPokerGuessingConfig.Type2DescKey = {
    [XPokerGuessingConfig.GuessType.Less] = "SmallerDesc",
    [XPokerGuessingConfig.GuessType.Greater] = "BiggerDesc",
    [XPokerGuessingConfig.GuessType.Equal] = "EqualDesc",
}

local TABLE_POKER_GUESSING_ACTIVITY_PATH = "Share/MiniActivity/PokerGuessing/PokerGuessingActivity.tab"
local TABLE_POKER_GUESSING_GROUP_PATH = "Share/MiniActivity/PokerGuessing/PokerGroup.tab"
local TABLE_POKER_GUESSInG_BUTTON_GROUP_PATH = "Client/MiniActivity/PokerGuessing/PokerGuessingButtonGroup.tab"

local _PokerGuessingActivityTemplate = {}
local _PokerGuessingGroupTemplate = {}
local _PokerGuessingButtonGroupTemplate = {}
local _DefaultActivityId = 1

function XPokerGuessingConfig.Init()
    _PokerGuessingActivityTemplate = XTableManager.ReadByIntKey(TABLE_POKER_GUESSING_ACTIVITY_PATH,XTable.XTablePokerGuessingActivity,"Id")
    for id,config in pairs(_PokerGuessingActivityTemplate) do
        if XTool.IsNumberValid(config.TaskTimeLimitId) then
            _DefaultActivityId = id
            break
        end
        _DefaultActivityId = id
    end
    _PokerGuessingGroupTemplate = XTableManager.ReadByIntKey(TABLE_POKER_GUESSING_GROUP_PATH,XTable.XTablePokerGroup,"Id")
    _PokerGuessingButtonGroupTemplate = XTableManager.ReadByIntKey(TABLE_POKER_GUESSInG_BUTTON_GROUP_PATH,XTable.XTablePokerButtonGroup,"Id")

    XPokerGuessingConfig.PokerRoleConfig = XConfig.New("Client/MiniActivity/PokerGuessing/PokerGuessingRole.tab", XTable.XTablePokerGuessingRole)
    XPokerGuessingConfig.PokerStoryConfig = XConfig.New("Share/MiniActivity/PokerGuessing/PokerGuessingStory.tab", XTable.XTablePokerGuessingStory)
end

local GetActivityConfig = function(id)
    local config = _PokerGuessingActivityTemplate[id]
    if not config then
        XLog.Error("XPokerGuessingConfig.GetActivityConfig 配置不存在,id:",id)
        return
    end
    return config
end

function XPokerGuessingConfig.GetActivityName(id)
    local config = GetActivityConfig(id)
    return config.Name
end

function XPokerGuessingConfig.GetActivityTimeId(id)
    local config = GetActivityConfig(id)
    return config.TaskTimeLimitId
end

function XPokerGuessingConfig.GetBackAssetPath(id)
    local config = GetActivityConfig(id)
    return config.BackAssetPath
end

function XPokerGuessingConfig.GetActivityStoryId(id)
    local config = GetActivityConfig(id)
    return config.StoryId
end

function XPokerGuessingConfig.GetCostItemName(id)
    local config = GetActivityConfig(id)
    return XDataCenter.ItemManager.GetItemName(config.CostItemID)
end

function XPokerGuessingConfig.GetCostItemIcon(id)
    local config = GetActivityConfig(id)
    return XDataCenter.ItemManager.GetItemIcon(config.CostItemID)
end

function XPokerGuessingConfig.GetCostItemCount(id)
    local config = GetActivityConfig(id)
    return config.CostItemCount
end

function XPokerGuessingConfig.GetTaskType(id)
    local config = GetActivityConfig(id)
    return config.TaskType
end

function XPokerGuessingConfig.GetPokerGroup(id)
    local config = GetActivityConfig(id)
    return config.PokerGroupId
end

function XPokerGuessingConfig.GetBannerBg(id)
    local config = GetActivityConfig(id)
    return config.BannerBg
end

function XPokerGuessingConfig.GetShopSkipId(id)
    local config = GetActivityConfig(id)
    return config.ShopSkipId
end

function XPokerGuessingConfig.GetMaxProgress(id)
    local config = GetActivityConfig(id)
    return config.MaxProgress
end

function XPokerGuessingConfig.GetMaxTipCount(id)
    local config = GetActivityConfig(id)
    return config.MaxTipsCount
end

function XPokerGuessingConfig.GetDefaultActivityId()
    return _DefaultActivityId
end

function XPokerGuessingConfig.GetButtonGroupConfig()
    return _PokerGuessingButtonGroupTemplate
end

local GetCardConfigById = function(id)
    local config = _PokerGuessingGroupTemplate[id]
    if not config then
        XLog.Error("XPokerGuessingConfig.GetCardConfigById 配置不存在，id:",id)
        return
    end
    return config
end

function XPokerGuessingConfig.GetCardFrontAssetPath(id)
    local config = GetCardConfigById(id)
    return config.FrontAssetPath
end

function XPokerGuessingConfig.GetCardListByGroupId(groupId)
    local tempList = {}
    for id, card in pairs(_PokerGuessingGroupTemplate) do
        if card.PokerGroup == groupId then
            table.insert(tempList, { Id = id, FrontImg = card.FrontAssetPath })
        end
    end
    return tempList
end

function XPokerGuessingConfig.GetCardListByType(suitType,groupId)
    local tempList = {}
    for id, card in pairs(_PokerGuessingGroupTemplate) do
        if card.PokerSuitType == suitType and card.PokerGroup == groupId then
            table.insert(tempList, { Id = id, FrontImg = card.FrontAssetPath })
        end
    end
    return tempList
end

function XPokerGuessingConfig.GetCardNumber(id)
    local config = GetCardConfigById(id)
    return config.PokerNum
end

function XPokerGuessingConfig.GetDefaultSelectRoleId()
    local list = XPokerGuessingConfig.PokerRoleConfig:GetConfigs()
    for _, cfg in pairs(list) do
        return cfg.Id
    end
end 

function XPokerGuessingConfig.GetUnlockCostCount(characterId)
    local configs = XPokerGuessingConfig.PokerStoryConfig:GetConfigs()
    for _, cfg in ipairs(configs) do
        if characterId == cfg.CharacterId then
            return cfg.Cost
        end
    end
    return 1
end 