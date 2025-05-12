XGuildConfig = XGuildConfig or {}

local CLIENT_GUILD_WELFARE = "Client/Guild/GuildWelfare.tab"
local CLIENT_GUILD_CHALLENGE = "Client/Guild/GuildChallengeDetails.tab"
local CLIENT_GUILD_TALENTDETAIL = "Client/Guild/GuildTalentDetails.tab"
local CLIENT_GUILD_TALENTDETAILTEXT = "Client/Guild/GuildTalentDetailsText.tab"
local CLIENT_GUILD_WELCOME = "Client/Guild/GuildWelcome.tab"


local SHARE_GUILD_LEVEL = "Share/Guild/GuildLevel.tab"
local SHARE_GUILD_POSITION = "Share/Guild/GuildPosition.tab"
local SHARE_GUILD_HEADPORTRAIT = "Share/Guild/GuildHeadPortrait.tab"
local SHARE_GUILD_GIFT = "Share/Guild/GuildGift.tab"
local SHARE_GUILD_NEWS = "Share/Guild/GuildNews.tab"
local SHARE_GUILD_PRESENT = "Share/Guild/GuildPresent.tab"
local SHARE_GUILD_TALENT = "Share/Guild/GuildTalent.tab"
local SHARE_GUILD_CUSTOMNAME = "Share/Guild/GuildCustomName.tab"
local SHARE_GUILD_CREATE = "Share/Guild/GuildCreate.tab"
local SHARE_GUILD_GOODS = "Share/Guild/GuildGoods.tab"
local SHARE_GUILD_SIGN = "Share/GuildSign/GuildSign.tab"
local SHARE_GUILD_SIGN_EVENT = "Share/GuildSign/GuildSignEvent.tab"


-- 心愿发布
local SHARE_GUILD_TRUSTITEM = "Share/Trust/CharacterTrustItem.tab"

local GuildWelfare = {}
local GuildChallenge = {}
---@type XTableGuildTalentDetails[]
local GuildTalentDetails = {}
---@type XTableGuildTalentDetailsText[]
local GuildTalentDetailsText = {}

local GuildCreate = {}
local GuildLevel = {}
local GuildPosition = {}
local GuildHeadPortrait = {}
local GuildGift = {}
local GuildNews = {}
local SortedGuildGift = {}
local GuildTrustItems = {}
local GuildTrustItemsList = {}
local GuildTrustItemsCharacterId = {}
local GuildTrustCharacterIdsList = {}
local GuildPresentTemplate = {}
local GuildTalentTemplate = {}
local GuildWelcomeTemplate = {}
local GuildCustomNameTemplate = {}
local GuildSignTemplate = {}
local GuildSignEventTemplate = {}
local GuildGoods = {}
local SortedTalentPoint = {}

XGuildConfig.KEY_LAST_LEVEL = "KeyGuildLastLevel"
XGuildConfig.KEY_LAST_RANK = "KeyGuildLastRank"
XGuildConfig.KEY_CUR_RANK = "KeyGuildCurrentRank"

XGuildConfig.GuildLikeCoin = 37             -- 点赞道具
XGuildConfig.GuildContributeCoin = 38       -- 公会贡献
XGuildConfig.GuildCoin = 39                 -- 公会币
XGuildConfig.GuildTalent = 46               -- 天赋

XGuildConfig.GuildPersonalShop = 4001       -- 公会个人商店
XGuildConfig.GuildPurchaseShop = 9998       -- 公会采购商店
XGuildConfig.GuildDefaultDay = 7            -- 默认天数
XGuildConfig.GuildDefaultWelcomeWord = 4    -- 默认迎新语数量

XGuildConfig.RecommendLevel = CS.XGame.Config:GetInt("GuildPlayerRecommendLevel")           --推荐等级
XGuildConfig.RecommendCount = CS.XGame.Config:GetInt("GuildPlayerRecommendCountPage")           --推荐数量
XGuildConfig.RecommendPage = CS.XGame.Config:GetInt("GuildPlayerRecommendCountPage")        --推荐页数
XGuildConfig.RecommendRefresh = CS.XGame.Config:GetInt("GuildPlayerRecommendRefresh")       --推荐刷新间隔
XGuildConfig.GuildChatCacheCount = CS.XGame.ClientConfig:GetInt("GuildChatCacheCount")

XGuildConfig.LikeItemId = CS.XGame.Config:GetInt("GuildLikedItemId")                        --点赞道具
XGuildConfig.GloryPointsPerLevel = CS.XGame.Config:GetInt("GuildGloryPointsPerLevel")       --荣耀等级每一级所需天赋点数
XGuildConfig.GuildGloryMaxLevel = CS.XGame.Config:GetInt("GuildGloryMaxLevel")              --最高荣耀等级

-- 公会宣言/内部通讯字数
XGuildConfig.AnnouncementWordMaxCount = CS.XGame.ClientConfig:GetInt("GuildAnnouncementMaxLen")
XGuildConfig.InterComWordMaxCount = CS.XGame.ClientConfig:GetInt("GuildInterComMaxLen")

-- 公会动态最大数量
XGuildConfig.GuildNewsMaxCount = CS.XGame.ClientConfig:GetInt("GuildNewsMaxCount")
-- 公会招募刷新cd
XGuildConfig.GUildRefreshCDTime = CS.XGame.ClientConfig:GetInt("GuildRefreshRecruitTime")
-- 公会动态刷新频率
XGuildConfig.GUildNewsRefreshFrequency = 3
-- 公会主界面刷新cd
XGuildConfig.GuildMainRefreshCD = CS.XGame.ClientConfig:GetInt("GuildMainInfoRefreshTime")

XGuildConfig.NewsType = {
    Guild = 1,
    Member = 2,
    All = 3,
}

XGuildConfig.NewsList = {
    "All","Guild","Member",
}

XGuildConfig.NewsName = {
    [XGuildConfig.NewsType.All] = CS.XTextManager.GetText("GuildNewsAll"),
    [XGuildConfig.NewsType.Guild] = CS.XTextManager.GetText("GuildNewsGuild"),
    [XGuildConfig.NewsType.Member] = CS.XTextManager.GetText("GuildNewsMember"),
}

-- 公会频道、本地缓存数量
XGuildConfig.CHANNEL_MAX_COUNT = CS.XGame.ClientConfig:GetInt("GuildChannelMaxCount")

XGuildConfig.EnlistType = {
    Recruit = 1,
    News = 2
}

-- 类型：申请设置、改变职位、公会改名
XGuildConfig.TipsType = {
    ApplySetting = 1,
    ChangePosition = 2,
    SetName = 3,
}

-- 文字编辑类型：公告、内部通讯
XGuildConfig.InformationType = {
    Announcement = 1,
    InternalCommunication = 2,
}

-- 申请设置
XGuildConfig.ApplySetting = {
    NoneApply = 1,
    NeedApply = 2,
    Forbidden = 3,
}

-- 维护状态
XGuildConfig.GuildMaintainState = {
    Normal = 0,
    Urgent = 1,
}

-- 公会任务
XGuildConfig.GuildTaskType = {
    Daily = 1,
    Mainly = 2,
}

-- 公会创建的ItemId
local GuildCreateCostItemType
-- 公会创建的Item的数量
local GuildCreateCostItemCount
--公会人员等级
XGuildConfig.GuildRankLevel = {
    Leader = 1, --会长
    CoLeader = 2, --副会长
    Elder = 3, --精英
    Member = 4, --会员
    Tourist = 5, --游客
    Nothing = 9, --啥也不是
}
XGuildConfig.GUildRankIcon = {
    [XGuildConfig.GuildRankLevel.Leader] = CS.XGame.ClientConfig:GetString("GuildRankIcon1"),
    [XGuildConfig.GuildRankLevel.CoLeader] = CS.XGame.ClientConfig:GetString("GuildRankIcon2"),
    [XGuildConfig.GuildRankLevel.Elder] = CS.XGame.ClientConfig:GetString("GuildRankIcon3"),
    [XGuildConfig.GuildRankLevel.Member] = CS.XGame.ClientConfig:GetString("GuildRankIcon4"),
    [XGuildConfig.GuildRankLevel.Tourist] = CS.XGame.ClientConfig:GetString("GuildRankIcon5"),
}

XGuildConfig.GuildRankName = {
    [XGuildConfig.GuildRankLevel.Leader] = CS.XGame.ClientConfig:GetString("GuildRankName1"),
    [XGuildConfig.GuildRankLevel.CoLeader] = CS.XGame.ClientConfig:GetString("GuildRankName2"),
    [XGuildConfig.GuildRankLevel.Elder] = CS.XGame.ClientConfig:GetString("GuildRankName3"),
    [XGuildConfig.GuildRankLevel.Member] = CS.XGame.ClientConfig:GetString("GuildRankName4"),
    [XGuildConfig.GuildRankLevel.Tourist] = CS.XGame.ClientConfig:GetString("GuildRankName5"),
}

XGuildConfig.GuildChallengeEnter = {
    GuildTask = 1,
    GuildPet = 2,
    GuildBoss = 3
}

XGuildConfig.GuildEventType = {
    Contribute = 1,
    Build = 2,
    GiftContribute = 3,
    Level = 4,
    ApplyChanged = 5,
    KickOut = 6,
    ContributeReward = 7,
    WeeklyReset = 8,
    RankLevelChanged = 9,
    Talent = 10,--value = 天赋id, value2 = 天赋等级
    TalentPoint = 11,--value = 天赋值
    MemberChanged = 12,--value = 最新人数
    Recruit = 13,--是否有公会邀请
    FreeChangeName = 14, -- 公会被强制改名，获得免费改名机会（仅会长收到）
    GoodsCoin = 15, --工会货币改变
    GuildBossHpBox = 20, --有公会boss血量奖励可以领取
    GuildBossScoreBox = 21, --公会boss积分奖励可以领取
    GuildBossWeeklyTask = 22, --工会boss周长任务
}

XGuildConfig.GuildSortType = {
    SortByContribute = 1,
    SortByLevel = 2,
    SortByRankLevel = 3,
}

XGuildConfig.GuildSortName = {
    [XGuildConfig.GuildSortType.SortByContribute] = CS.XTextManager.GetText("GuildSortByContribute"),
    [XGuildConfig.GuildSortType.SortByLevel] = CS.XTextManager.GetText("GuildSortByLevel"),
    [XGuildConfig.GuildSortType.SortByRankLevel] = CS.XTextManager.GetText("GuildSortByRankLevel"),
}


XGuildConfig.GuildMemberSortType = {
    --默认排序
    SortByDefault = 1,
    --近期贡献
    SortByContributeAct = 2,
    --历史贡献
    SortByContributeHistory = 3,
    --上次登录
    SortByLastLoginTime = 4,
    --职级
    SortByRankLevel = 5,
}

XGuildConfig.GoodsType = {
    -- 场景
    Scene = 1,
    -- 背景音乐
    Bgm = 2
    -- 小游戏
}

--请求推荐数据时间间隔
XGuildConfig.GuildRequestRecommandTime = CS.XGame.ClientConfig:GetInt("GuildReqRecommandCdTime")
--请求收到的招募数据时间间隔
XGuildConfig.GuildRequestRecruitTime = 30
--请求排行列表的时间间隔
XGuildConfig.GuildRequestRankTime = 10
--请求游客数据时间间隔
XGuildConfig.GuildRequestVistorTime = 0
--公会内部排名页面人数
XGuildConfig.RankTopListCount = 5
XGuildConfig.RankBottomPageCount = 6

--公会专属货币
XGuildConfig.GoodsCoinId = 62723

function XGuildConfig.Init()
    GuildWelfare = XTableManager.ReadByIntKey(CLIENT_GUILD_WELFARE, XTable.XTableGuildWelfare, "Id")
    GuildChallenge = XTableManager.ReadByIntKey(CLIENT_GUILD_CHALLENGE, XTable.XTableGuildChallengeDetails, "Id")
    GuildTalentDetails = XTableManager.ReadByIntKey(CLIENT_GUILD_TALENTDETAIL, XTable.XTableGuildTalentDetails, "Id")
    GuildTalentDetailsText = XTableManager.ReadByIntKey(CLIENT_GUILD_TALENTDETAILTEXT, XTable.XTableGuildTalentDetailsText, "Id")

    GuildLevel = XTableManager.ReadByIntKey(SHARE_GUILD_LEVEL, XTable.XTableGuildLevel, "Level")
    GuildPosition = XTableManager.ReadByIntKey(SHARE_GUILD_POSITION, XTable.XTableGuildPosition, "Id")
    GuildHeadPortrait = XTableManager.ReadByIntKey(SHARE_GUILD_HEADPORTRAIT, XTable.XTableGuildHeadPortrait, "Id")
    GuildGift = XTableManager.ReadByIntKey(SHARE_GUILD_GIFT, XTable.XTableGuildGift, "Id")
    GuildNews = XTableManager.ReadByIntKey(SHARE_GUILD_NEWS, XTable.XTableGuildNews, "Id")
    GuildTrustItems = XTableManager.ReadByIntKey(SHARE_GUILD_TRUSTITEM, XTable.XTableCharacterTrustItem, "Id")
    GuildTalentTemplate = XTableManager.ReadByIntKey(SHARE_GUILD_TALENT, XTable.XTableGuildTalent, "Id")
    GuildPresentTemplate = XTableManager.ReadByIntKey(SHARE_GUILD_PRESENT, XTable.XTableGuildPresent, "Id")
    GuildCreate = XTableManager.ReadByIntKey(SHARE_GUILD_CREATE, XTable.XTableGuildCreate, "Id")
    GuildSignTemplate = XTableManager.ReadByIntKey(SHARE_GUILD_SIGN, XTable.XTableGuildSign, "Id")
    GuildSignEventTemplate = XTableManager.ReadByIntKey(SHARE_GUILD_SIGN_EVENT, XTable.XTableGuildSignEvent, "Id")
    
    GuildGoods = XTableManager.ReadByIntKey(SHARE_GUILD_GOODS, XTable.XTableGuildGoods, "Id")
    

    XGuildConfig.InitGuildGift()
    XGuildConfig.InitGuildTalent()
    XGuildConfig.InitMemberSortFunc()
end

function XGuildConfig.InitGuildGift()
    for _, v in pairs(GuildGift or {}) do
        if not SortedGuildGift[v.GuildLevel] then
            SortedGuildGift[v.GuildLevel] = {}
        end

        if not SortedGuildGift[v.GuildLevel][v.GiftLevel] then
            SortedGuildGift[v.GuildLevel][v.GiftLevel] = {}
        end

        SortedGuildGift[v.GuildLevel][v.GiftLevel] = v
    end
end

function XGuildConfig.GetGuildCreate()
    return GuildCreate[1]
end

--v1.27-公会优化-获取创建道具所需资源Id
function XGuildConfig.GetCreateCostItemType()
    local config = XGuildConfig.GetGuildCreate()
    return config.ItemId
end

--v1.27-公会优化-获取创建道具所需资源数
function XGuildConfig.GetCreateCostItemCount()
    local config = XGuildConfig.GetGuildCreate()
    return config.ItemNum
end

--v1.27-公会优化-获取工会创建前置条件
function XGuildConfig.GetCreateConditionals()
    local config = XGuildConfig.GetGuildCreate()
    return config.ConditionIds
end

function XGuildConfig.GetGuildWelfares()
    return GuildWelfare
end

function XGuildConfig.GetGuildWelfareById(id)
    local welfareData = GuildWelfare[id]
    if not welfareData then
        XLog.ErrorTableDataNotFound("XGuildConfig.GetGuildWelfareById", "GuildWelfare", CLIENT_GUILD_WELFARE, "Id", tostring(id))
        return
    end
    return welfareData
end

function XGuildConfig.GetGuildChallenges()
    return GuildChallenge
end

function XGuildConfig.GetGuildChallengeById(id)
    local challengeData = GuildChallenge[id]
    if not challengeData then
        XLog.ErrorTableDataNotFound("XGuildConfig.GetGuildChallengeById", "GuildChallengeDetails", CLIENT_GUILD_CHALLENGE, "Id", tostring(id))
        return
    end
    return challengeData
end

function XGuildConfig.GetGuildLevelDataBylevel(level)
    local guildLevelData = GuildLevel[level]
    if not guildLevelData then
        return
    end
    return guildLevelData
end

function XGuildConfig.GetGuildLevelDatas()
    return GuildLevel
end

--公会容量
function XGuildConfig.GetGuildCapacityByLevel(level)
    local guildLevelData = XGuildConfig.GetGuildLevelDataBylevel(level)
    if not guildLevelData then
        return
    end
    return guildLevelData.Capacity
end

--每天可求助次数
function XGuildConfig.GetGuildWishMaxCountByLevel(level)
    local guildLevelData = XGuildConfig.GetGuildLevelDataBylevel(level)
    if not guildLevelData then
        return
    end
    return guildLevelData.WishMaxCount
end

-- 每天可捐献次数
function XGuildConfig.GetGuildWishContributeMaxCountByLevel(level)
    local guildLevelData = XGuildConfig.GetGuildLevelDataBylevel(level)
    if not guildLevelData then
        return
    end
    return guildLevelData.WishContributeMaxCount
end

function XGuildConfig.GetGuildPositionById(id)
    local guildPositionData = GuildPosition[id]
    if not guildPositionData then
        XLog.ErrorTableDataNotFound("XGuildConfig.GetGuildPositionById", "GuildPosition", SHARE_GUILD_POSITION, "Id", tostring(id))
        return
    end
    return guildPositionData
end

function XGuildConfig.GetAllGuildPositions()
    return GuildPosition
end

function XGuildConfig.GetGuildHeadPortraitById(id)
    local headPortraitData = GuildHeadPortrait[id]
    if not headPortraitData then
        XLog.ErrorTableDataNotFound("XGuildConfig.GetGuildHeadPortraitById", "GuildHeadPortrait", SHARE_GUILD_HEADPORTRAIT, "Id", tostring(id))
        return
    end
    return headPortraitData
end

function XGuildConfig.GetGuildHeadPortraitDatas()
    return GuildHeadPortrait
end

function XGuildConfig.GetGuildHeadPortraitIconById(id)
    local headPortraitData = GuildHeadPortrait[id]
    if not headPortraitData then
        XLog.ErrorTableDataNotFound("XGuildConfig.GetGuildHeadPortraitById", "GuildHeadPortrait", SHARE_GUILD_HEADPORTRAIT, "Id", tostring(id))
        return
    end
    return headPortraitData.Icon
end

function XGuildConfig.GetGuildGiftByGuildLevelAndGiftLevel(guildLv, giftLv)
    if not SortedGuildGift[guildLv] or not SortedGuildGift[guildLv][giftLv] then
        return
    end
    return SortedGuildGift[guildLv][giftLv]
end

function XGuildConfig.GetGuildGiftByGuildLevel(guildLv)
    if SortedGuildGift[guildLv] then
        table.sort(SortedGuildGift[guildLv], function(gift1, gift2)
            return gift1.GiftLevel < gift2.GiftLevel
        end)
        return SortedGuildGift[guildLv]
    end
end

function XGuildConfig.GetGuildGiftById(guildId)
    if not GuildGift[guildId] then
        XLog.ErrorTableDataNotFound("XGuildConfig.GetGuildGiftById", "GuildGift", SHARE_GUILD_GIFT, "guildId", tostring(guildId))
        return
    end
    return GuildGift[guildId]
end

function XGuildConfig.GetGuildNewsById(msgId)
    if not GuildNews[msgId] then
        XLog.ErrorTableDataNotFound("XGuildConfig.GetGuildNewsById", "GuildNews", SHARE_GUILD_NEWS, "Id", tostring(msgId))
        return
    end
    return GuildNews[msgId]
end

function XGuildConfig.InitCharacterTrustItems()
    for _, v in pairs(GuildTrustItems) do
        local favorCharacterIds = v.FavorCharacterId
        for _, id in pairs(favorCharacterIds) do
            if not GuildTrustItemsCharacterId[id] then
                GuildTrustItemsCharacterId[id] = {}
                table.insert(GuildTrustCharacterIdsList, { Id = id })
            end
            table.insert(GuildTrustItemsCharacterId[id], v.Id)
        end
    end
end

function XGuildConfig.GetTrustItemsByCharacterId(id)
    if not next(GuildTrustItemsCharacterId) then
        XGuildConfig.InitCharacterTrustItems()
    end
    return GuildTrustItemsCharacterId[id]
end

function XGuildConfig.GetGuildTrustItemsList()
    if not next(GuildTrustItemsList) then
        for _, v in pairs(GuildTrustItems) do
            if v.FavorCharacterId and #(v.FavorCharacterId) > 0 then
                table.insert(GuildTrustItemsList, { Id = v.Id })
            end
        end
    end
    return GuildTrustItemsList
end

function XGuildConfig.GetTrustCharacterIds()
    if not next(GuildTrustCharacterIdsList) then
        XGuildConfig.InitCharacterTrustItems()
    end
    return GuildTrustCharacterIdsList
end

function XGuildConfig.GetGuildSignById(id)
    if not GuildSignTemplate[id] then
        XLog.ErrorTableDataNotFound("XGuildConfig.GetGuildSignById", "GuildSign", SHARE_GUILD_SIGN, "Id", tostring(id))
        return
    end
    return GuildSignTemplate[id]
end

function XGuildConfig.GetGuildSignEventById(id)
    if not GuildSignEventTemplate[id] then
        XLog.ErrorTableDataNotFound("XGuildConfig.GetGuildSignEventById", "GuildSignEvent", SHARE_GUILD_SIGN_EVENT, "Id", tostring(id))
        return
    end
    return GuildSignEventTemplate[id]
end

-- 送礼
function XGuildConfig.GetGuildPresentById(id)
    if not GuildPresentTemplate[id] then
        XLog.ErrorTableDataNotFound("XGuildConfig.GetGuildPresentById", "GuildPresentTemplate", SHARE_GUILD_PRESENT, "Id", tostring(id))
        return
    end
    return GuildPresentTemplate[id]
end

function XGuildConfig.GetAllGuildPresent()
    return GuildPresentTemplate
end

-- 天赋
function XGuildConfig.GetGuildTalentById(id)
    if not GuildTalentTemplate[id] then
        XLog.ErrorTableDataNotFound("XGuildConfig.GetGuildTalentById", "GuildTalentTemplate", SHARE_GUILD_TALENT, "Id", tostring(id))
        return
    end
    return GuildTalentTemplate[id]
end

function XGuildConfig.GetGuildTalentsByLevel(level)
    local tmp = {}
    for _, temp in pairs(GuildTalentTemplate or {}) do
        if temp.GuildLevel == level then
            table.insert(tmp, temp)
        end
    end
    return tmp
end

function XGuildConfig.GetGuildTalentConfigById(id)
    if not GuildTalentDetails[id] then
        XLog.ErrorTableDataNotFound("XGuildConfig.GetGuildTalentConfigById", "GuildTalentDetails", CLIENT_GUILD_TALENTDETAIL, "Id", tostring(id))
        return
    end
    return GuildTalentDetails[id]
end

function XGuildConfig.GetGuildTalentText(id)
    if not XTool.IsNumberValid(id) then
        return ""
    end
    if not GuildTalentDetailsText[id] then
        XLog.ErrorTableDataNotFound("XGuildConfig.GetGuildTalentText", "GuildTalentDetailsText", CLIENT_GUILD_TALENTDETAILTEXT, "Id", tostring(id))
        return ""
    end
    return GuildTalentDetailsText[id].Text or ""
end

function XGuildConfig.InitGuildTalent()
    for _, v in pairs(GuildTalentDetails) do
        SortedTalentPoint[v.IndexInMap] = {
            Id = v.Id,
            IndexInMap = v.IndexInMap
        }
    end
    for _, v in pairs(GuildTalentTemplate) do
        local childIndex = GuildTalentDetails[v.Id].IndexInMap
        for i = 1, #v.Parent do
            local curId = v.Parent[i]
            if curId > 0 then
                local curIndex = GuildTalentDetails[curId].IndexInMap
                if SortedTalentPoint[curIndex] then
                    if not SortedTalentPoint[curIndex].ChildNodes then
                        SortedTalentPoint[curIndex].ChildNodes = {}
                    end
                    SortedTalentPoint[curIndex].ChildNodes[v.Id] = childIndex
                end
            end
        end
    end
end

function XGuildConfig.GetSortedTalentPoints()
    return SortedTalentPoint
end

function XGuildConfig.GetDefaultWelcomeWords()
    if not next(GuildWelcomeTemplate) then
        GuildWelcomeTemplate = XTableManager.ReadByIntKey(CLIENT_GUILD_WELCOME, XTable.XTableGuildWelcome, "Id")
    end
    return GuildWelcomeTemplate
end

function XGuildConfig.GetCustomNameTemplate()
    if not next(GuildCustomNameTemplate) then
        GuildCustomNameTemplate = XTableManager.ReadByIntKey(SHARE_GUILD_CUSTOMNAME, XTable.XTableGuildCustomName, "Id")
    end
    return GuildCustomNameTemplate
end

--region   ------------------MemberSort start-------------------
local MemberSortFunc = {}
function XGuildConfig.InitMemberSortFunc()

    --是否在线排序
    local sortByOnlineFlag = function(memberA, memberB, isAscendOrder)
        local flagA = memberA.OnlineFlag
        local flagB = memberB.OnlineFlag
        if flagA ~= flagB then
            if isAscendOrder then
                return true, flagA < flagB
            end
            return true, flagA > flagB
        end
        return false
    end

    --职权等级排序
    local sortByRankLevel = function(memberA, memberB, isAscendOrder)
        local rankLevelA = memberA.RankLevel
        local rankLevelB = memberB.RankLevel
        if rankLevelA ~= rankLevelB then
            if isAscendOrder then
                return true, rankLevelA > rankLevelB
            end
            return true, rankLevelA < rankLevelB
        end
        return false
    end

    --近期贡献排序
    local sortByContributeAct = function(memberA, memberB, isAscendOrder)
        local contributeActA = memberA.ContributeAct
        local contributeActB = memberB.ContributeAct
        if contributeActA ~= contributeActB then
            if isAscendOrder then
                return true, contributeActA < contributeActB
            end
            return true, contributeActA > contributeActB
        end
        return false
    end

    --历史贡献排序
    local sortByContributeHistory = function(memberA, memberB, isAscendOrder)
        local contributeHistoryA = memberA.ContributeHistory
        local contributeHistoryB = memberB.ContributeHistory
        if contributeHistoryA ~= contributeHistoryB then
            if isAscendOrder then
                return true, contributeHistoryA < contributeHistoryB
            end
            return true, contributeHistoryA > contributeHistoryB
        end
        return false
    end

    --成员等级排序
    local sortByMemberLevel = function(memberA, memberB, isAscendOrder)
        local levelA = memberA.Level
        local levelB = memberB.Level
        if levelA ~= levelB then
            if isAscendOrder then
                return true, levelA < levelB
            end
            return true, levelA > levelB
        end
        return false
    end

    --上次登录时间排序
    local sortByLastLoginTime = function(memberA, memberB, isAscendOrder)
        local lastLoginTimeA = memberA.LastLoginTime
        local lastLoginTimeB = memberB.LastLoginTime
        if lastLoginTimeA ~= lastLoginTimeB then
            if isAscendOrder then
                return true, lastLoginTimeA < lastLoginTimeB
            end
            return true, lastLoginTimeA > lastLoginTimeB
        end
        return false
    end

    MemberSortFunc[XGuildConfig.GuildMemberSortType.SortByDefault] = function(memberA, memberB, isAscendOrder)
        local sorted, sortResult
        sorted, sortResult = sortByOnlineFlag(memberA, memberB, false)
        if sorted then
            return sortResult
        end

        sorted, sortResult = sortByRankLevel(memberA, memberB, true)
        if sorted then
            return sortResult
        end

        sorted, sortResult = sortByContributeAct(memberA, memberB, false)
        if sorted then
            return sortResult
        end

        sorted, sortResult = sortByMemberLevel(memberA, memberB, false)
        if sorted then
            return sortResult
        end

        return memberA.Id < memberB.Id
    end

    MemberSortFunc[XGuildConfig.GuildMemberSortType.SortByContributeAct] = function(memberA, memberB, isAscendOrder)
        local sorted, sortResult
        sorted, sortResult = sortByOnlineFlag(memberA, memberB, false)
        if sorted then
            return sortResult
        end

        sorted, sortResult = sortByContributeAct(memberA, memberB, isAscendOrder)
        if sorted then
            return sortResult
        end

        return memberA.Id < memberB.Id
    end

    MemberSortFunc[XGuildConfig.GuildMemberSortType.SortByContributeHistory] = function(memberA, memberB, isAscendOrder)
        local sorted, sortResult
        sorted, sortResult = sortByOnlineFlag(memberA, memberB, false)
        if sorted then
            return sortResult
        end

        sorted, sortResult = sortByContributeHistory(memberA, memberB, isAscendOrder)
        if sorted then
            return sortResult
        end

        return memberA.Id < memberB.Id
    end

    MemberSortFunc[XGuildConfig.GuildMemberSortType.SortByLastLoginTime] = function(memberA, memberB, isAscendOrder)
        local sorted, sortResult
        sorted, sortResult = sortByOnlineFlag(memberA, memberB, false)
        if sorted then
            return sortResult
        end

        sorted, sortResult = sortByLastLoginTime(memberA, memberB, isAscendOrder)
        if sorted then
            return sortResult
        end

        return memberA.Id < memberB.Id
    end
    
    MemberSortFunc[XGuildConfig.GuildMemberSortType.SortByRankLevel] = function(memberA, memberB, isAscendOrder)
        local sorted, sortResult
        sorted, sortResult = sortByOnlineFlag(memberA, memberB, false)
        if sorted then
            return sortResult
        end
        sorted, sortResult = sortByRankLevel(memberA, memberB, isAscendOrder)
        if sorted then
            return sortResult
        end
        return memberA.Id < memberB.Id
    end
end

function XGuildConfig.DoMemberSort(memberList, sortType, isAscendOrder)
    memberList = memberList or {}
    sortType = sortType or XGuildConfig.GuildMemberSortType.SortByDefault
    table.sort(memberList, function(memberA, memberB) 
        return MemberSortFunc[sortType](memberA, memberB, isAscendOrder)
    end)
    
    return memberList
end
--endregion------------------MemberSort finish------------------

--region   ------------------GuildGoods start-------------------

function XGuildConfig.GetGoodsConfig(templateId)
    if not XTool.IsNumberValid(templateId) then
        XLog.Error("XGuildConfig.GetGoodsConfig 获取公会物品错误, templateId = ", templateId)
        return {}
    end
    local cfg = GuildGoods[templateId]
    if not cfg then
        XLog.Error("XGuildConfig.GetGoodsConfig 获取公会物品错误, templateId = ", templateId)
        return {}
    end
    return cfg
end

function XGuildConfig.GetGoodsName(templateId)
    local cfg = XGuildConfig.GetGoodsConfig(templateId)
    return cfg and cfg.Name or ""
end

function XGuildConfig.GetGoodsIcon(templateId)
    local cfg = XGuildConfig.GetGoodsConfig(templateId)
    if XTool.IsTableEmpty(cfg) then
        return
    end
    local goodsType = cfg.Type
    if goodsType == XGuildConfig.GoodsType.Scene then
        local tmp = XGuildDormConfig.GetThemeCfgById(cfg.TargetId)
        return tmp and tmp.Image
    elseif goodsType == XGuildConfig.GoodsType.Bgm then
        local tmp = XGuildDormConfig.GetBgmCfgById(cfg.TargetId)
        return tmp and tmp.Image
    end
end

function XGuildConfig.GetGoodsBigIcon(templateId)
    local cfg = XGuildConfig.GetGoodsConfig(templateId)
    if XTool.IsTableEmpty(cfg) then
        return
    end
    local goodsType = cfg.Type
    if goodsType == XGuildConfig.GoodsType.Scene then
        local tmp = XGuildDormConfig.GetThemeCfgById(cfg.TargetId)
        return tmp and (tmp.BigImage and tmp.BigImage or tmp.Image) or ""
    elseif goodsType == XGuildConfig.GoodsType.Bgm then
        local tmp = XGuildDormConfig.GetBgmCfgById(cfg.TargetId)
        return tmp and tmp.Image
    end
end

function XGuildConfig.GetGoodsType(templateId)
    local cfg = XGuildConfig.GetGoodsConfig(templateId)
    return cfg and cfg.Type
end

function XGuildConfig.GetThemeLabels(templateId)
    local cfg = XGuildConfig.GetGoodsConfig(templateId)
    if not cfg then
        return {}
    end
    local themeCfg = XGuildDormConfig.GetThemeCfgById(cfg.TargetId)
    return themeCfg and themeCfg.Labels or {}
end

function XGuildConfig.GetGoodsTargetId(templateId)
    local cfg = XGuildConfig.GetGoodsConfig(templateId)
    if not cfg then
        return 0
    end
    return cfg and cfg.TargetId or 0
end
--endregion------------------GuildGoods finish------------------

function XGuildConfig.RefreshSetView(btnQuit, btnJob, btnApply, btnRename, btnReport)
    local level = XDataCenter.GuildManager.GetCurRankLevel()
    local showBtnCount = 0

    --职责权限
    local AuthorityLevel = {
        TopLevel = 1,
        SecLevel = 2,
        NorLevel = 3
    }
    --职位对应权限
    local RankLevel2AuthorityLevel = {
        [XGuildConfig.GuildRankLevel.Leader] = AuthorityLevel.TopLevel,
        [XGuildConfig.GuildRankLevel.CoLeader] = AuthorityLevel.SecLevel,
        [XGuildConfig.GuildRankLevel.Elder] = AuthorityLevel.NorLevel,
        [XGuildConfig.GuildRankLevel.Member] = AuthorityLevel.NorLevel,
        [XGuildConfig.GuildRankLevel.Tourist] = AuthorityLevel.NorLevel,
        [XGuildConfig.GuildRankLevel.Nothing] = AuthorityLevel.NorLevel,
    }
    local authority = RankLevel2AuthorityLevel[level] or AuthorityLevel.NorLevel
    if not XTool.UObjIsNil(btnQuit) then
        local show = authority <= AuthorityLevel.NorLevel
        if show then
            showBtnCount = showBtnCount + 1
        end
        btnQuit.gameObject:SetActiveEx(show)
    end

    if not XTool.UObjIsNil(btnJob) then
        local show = authority <= AuthorityLevel.SecLevel
        if show then
            showBtnCount = showBtnCount + 1
        end
        btnJob.gameObject:SetActiveEx(show)
    end

    if not XTool.UObjIsNil(btnApply) then
        local show = authority <= AuthorityLevel.SecLevel
        if show then
            showBtnCount = showBtnCount + 1
        end
        btnApply.gameObject:SetActiveEx(show)
    end

    if not XTool.UObjIsNil(btnRename) then
        local show = authority == AuthorityLevel.TopLevel
        if show then
            showBtnCount = showBtnCount + 1
        end
        btnRename.gameObject:SetActiveEx(show)
    end

    if not XTool.UObjIsNil(btnReport) then
        local show = authority <= AuthorityLevel.NorLevel
        if show then
            showBtnCount = showBtnCount + 1
        end
        btnReport.gameObject:SetActiveEx(show)
    end
    return showBtnCount
end


