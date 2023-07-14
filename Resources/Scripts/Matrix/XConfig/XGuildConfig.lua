XGuildConfig = XGuildConfig or {}

local CLIENT_GUILD_WELFARE = "Client/Guild/GuildWelfare.tab"
local CLIENT_GUILD_CHALLENGE = "Client/Guild/GuildChallengeDetails.tab"
local CLIENT_GUILD_TALENTDETAIL = "Client/Guild/GuildTalentDetails.tab"
local CLIENT_GUILD_WELCOME = "Client/Guild/GuildWelcome.tab"

local SHARE_GUILD_LEVEL = "Share/Guild/GuildLevel.tab"
local SHARE_GUILD_POSITION = "Share/Guild/GuildPosition.tab"
local SHARE_GUILD_HEADPORTRAIT = "Share/Guild/GuildHeadPortrait.tab"
local SHARE_GUILD_GIFT = "Share/Guild/GuildGift.tab"
local SHARE_GUILD_NEWS = "Share/Guild/GuildNews.tab"
local SHARE_GUILD_PRESENT = "Share/Guild/GuildPresent.tab"
local SHARE_GUILD_TALENT = "Share/Guild/GuildTalent.tab"
local SHARE_GUILD_CUSTOMNAME = "Share/Guild/GuildCustomName.tab"

-- 心愿发布
local SHARE_GUILD_TRUSTITEM = "Share/Trust/CharacterTrustItem.tab"

local GuildWelfare = {}
local GuildChallenge = {}
local GuildTalentDetails = {}

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
XGuildConfig.AddPopularity = CS.XGame.Config:GetInt("GuildAddPopularity")                   --点赞一次增加的人气数
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

function XGuildConfig.Init()
    GuildWelfare = XTableManager.ReadByIntKey(CLIENT_GUILD_WELFARE, XTable.XTableGuildWelfare, "Id")
    GuildChallenge = XTableManager.ReadByIntKey(CLIENT_GUILD_CHALLENGE, XTable.XTableGuildChallengeDetails, "Id")
    GuildTalentDetails = XTableManager.ReadByIntKey(CLIENT_GUILD_TALENTDETAIL, XTable.XTableGuildTalentDetails, "Id")

    GuildLevel = XTableManager.ReadByIntKey(SHARE_GUILD_LEVEL, XTable.XTableGuildLevel, "Level")
    GuildPosition = XTableManager.ReadByIntKey(SHARE_GUILD_POSITION, XTable.XTableGuildPosition, "Id")
    GuildHeadPortrait = XTableManager.ReadByIntKey(SHARE_GUILD_HEADPORTRAIT, XTable.XTableGuildHeadPortrait, "Id")
    GuildGift = XTableManager.ReadByIntKey(SHARE_GUILD_GIFT, XTable.XTableGuildGift, "Id")
    GuildNews = XTableManager.ReadByIntKey(SHARE_GUILD_NEWS, XTable.XTableGuildNews, "Id")
    GuildTrustItems = XTableManager.ReadByIntKey(SHARE_GUILD_TRUSTITEM, XTable.XTableCharacterTrustItem, "Id")
    GuildCreateCostItemType = CS.XGame.Config:GetInt("GuildCreateCostItemType")
    GuildCreateCostItemCount = CS.XGame.Config:GetInt("GuildCreateCostItemCount")
    GuildTalentTemplate = XTableManager.ReadByIntKey(SHARE_GUILD_TALENT, XTable.XTableGuildTalent, "Id")
    GuildPresentTemplate = XTableManager.ReadByIntKey(SHARE_GUILD_PRESENT, XTable.XTableGuildPresent, "Id")

    XGuildConfig.InitGuildGift()
    XGuildConfig.InitGuildTalent()
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

function XGuildConfig.GetCreateCostItemType()
    return GuildCreateCostItemType
end

function XGuildConfig.GetCreateCostItemCount()
    return GuildCreateCostItemCount
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

function XGuildConfig.GetGuildTalentConfigById(id)
    if not GuildTalentDetails[id] then
        XLog.ErrorTableDataNotFound("XGuildConfig.GetGuildTalentConfigById", "GuildTalentDetails", CLIENT_GUILD_TALENTDETAIL, "Id", tostring(id))
        return
    end
    return GuildTalentDetails[id]
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