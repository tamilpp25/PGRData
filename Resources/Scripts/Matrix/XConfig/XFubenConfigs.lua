local CSXGameClientConfig = CS.XGame.ClientConfig
local CSXTextManagerGetText = CS.XTextManager.GetText

XFubenConfigs = XFubenConfigs or {}

local TABLE_STAGE = "Share/Fuben/Stage.tab"
local TABLE_MULTICHALLENGE_STAGE = "Share/Fuben/MultiChallengeStage.tab"
local TABLE_STAGE_TRANSFORM = "Share/Fuben/StageTransform.tab"
local TABLE_STAGE_LEVEL_CONTROL = "Share/Fuben/StageLevelControl.tab"
local TABLE_STAGE_MULTIPLAYER_LEVEL_CONTROL = "Share/Fuben/StageMultiplayerLevelControl.tab"
local TABLE_FLOP_REWARD = "Share/Fuben/FlopReward.tab"
local TABLE_STAGE_FIGHT_CONTROL = "Share/Fuben/StageFightControl.tab" --副本战力限制表
local TABLE_CHALLENGE_BANNER = "Share/Fuben/FubenChallengeBanner.tab"
local TABLE_ACTIVITY_SORTRULE = "Client/Fuben/ActivitySortRule/ActivitySortRule.tab"
local TABLE_FUBENFEATURES = "Client/Fuben/FubenFeatures.tab" -- 特性展示表
local TABLE_STAGE_CHARACTERLIMIT = "Share/Fuben/StageCharacterLimit.tab" -- 角色类型限制buff
local TABLE_BOSS_TEAMBUFF = "Share/Fuben/StageTeamBuff.tab"
local TABLE_STAGE_FIGHT_EVENT_DETAILS = "Client/Fuben/StageFightEventDetails.tab"
local TABLE_STAGE_FIGHT_EVENT = "Share/Fuben/StageFightEvent.tab"
local TABLE_SETTLE_LOST_TIP = "Client/Fuben/SettleLoseTip.tab"  -- 失败结算界面提示
local TABLE_STAGE_RECOMMEND_PATH = "Client/Fuben/StageRecommend.tab"  -- 关卡推荐表

local StageCfg = {}
local StageTransformCfg = {}
local StageLevelControlCfg = {}
local StageMultiplayerLevelControlCfg = {}
local FlopRewardTemplates = {}
local StageFightControlCfg = {}
local FubenChallengeBanners = {}
local ActivitySortRules = {}
local FubenFeatures = {}
local MultiChallengeConfigs = {}
local FubenNewChallenge
local StageCharacterLimitBuffConfig = {}
local TeamBuffCfg = {}
local TeamBuffMaxCountDic = {}
local StageFightEvent = {}
local StageFightEventDetails = {}
local SettleLoseTipCfg = {}
local StageRecommendConfigs = {}

XFubenConfigs.STAGETYPE_COMMON = 0
XFubenConfigs.STAGETYPE_FIGHT = 1
XFubenConfigs.STAGETYPE_STORY = 2
XFubenConfigs.STAGETYPE_STORYEGG = 3
XFubenConfigs.STAGETYPE_FIGHTEGG = 4

XFubenConfigs.FUBENTYPE_NORMAL = 0
XFubenConfigs.FUBENTYPE_PREQUEL = 1

XFubenConfigs.ROOM_MAX_WORLD = CSXGameClientConfig:GetInt("MultiplayerRoomRowMaxWorld")
XFubenConfigs.ROOM_WORLD_TIME = CSXGameClientConfig:GetInt("MultiplayerRoomWorldTime")

XFubenConfigs.CharacterLimitType = {
    All = 0, --构造体/感染体
    Normal = 1, --构造体
    Isomer = 2, --感染体
    IsomerDebuff = 3, --构造体/感染体(Debuff) [AKA:低浓度区]
    NormalDebuff = 4, --构造体(Debuff)/感染体 [AKA:重灾区]
}

function XFubenConfigs.Init()
    StageCfg = XTableManager.ReadByIntKey(TABLE_STAGE, XTable.XTableStage, "StageId")
    MultiChallengeConfigs = XTableManager.ReadByIntKey(TABLE_MULTICHALLENGE_STAGE, XTable.XTableMultiChallengeStage, "Id")
    StageLevelControlCfg = XTableManager.ReadByIntKey(TABLE_STAGE_LEVEL_CONTROL, XTable.XTableStageLevelControl, "Id")
    StageMultiplayerLevelControlCfg = XTableManager.ReadByIntKey(TABLE_STAGE_MULTIPLAYER_LEVEL_CONTROL, XTable.XTableStageMultiplayerLevelControl, "Id")
    StageTransformCfg = XTableManager.ReadByIntKey(TABLE_STAGE_TRANSFORM, XTable.XTableStageTransform, "Id")
    --TowerSectionCfg = XTableManager.ReadByIntKey(TABLE_TOWER_SECTION, XTable.XTableTowerSection, "Id")
    FlopRewardTemplates = XTableManager.ReadByIntKey(TABLE_FLOP_REWARD, XTable.XTableFlopReward, "Id")
    StageFightControlCfg = XTableManager.ReadByIntKey(TABLE_STAGE_FIGHT_CONTROL, XTable.XTableStageFightControl, "Id")
    ActivitySortRules = XTableManager.ReadByIntKey(TABLE_ACTIVITY_SORTRULE, XTable.XTableActivitySortRule, "Id")
    FubenFeatures = XTableManager.ReadByIntKey(TABLE_FUBENFEATURES, XTable.XTableFubenFeatures, "Id")
    StageCharacterLimitBuffConfig = XTableManager.ReadByIntKey(TABLE_STAGE_CHARACTERLIMIT, XTable.XTableFubenStageCharacterLimit, "Id")
    StageFightEvent = XTableManager.ReadByIntKey(TABLE_STAGE_FIGHT_EVENT, XTable.XTableStageFightEvent, "StageId")
    StageFightEventDetails = XTableManager.ReadByIntKey(TABLE_STAGE_FIGHT_EVENT_DETAILS, XTable.XTableStageFightEventDetails, "Id")
    SettleLoseTipCfg = XTableManager.ReadByIntKey(TABLE_SETTLE_LOST_TIP, XTable.XTableSettleLoseTip, "Id")
    StageRecommendConfigs = XTableManager.ReadByIntKey(TABLE_STAGE_RECOMMEND_PATH, XTable.XTableStageRecommend, "StageId")

    TeamBuffCfg = XTableManager.ReadByIntKey(TABLE_BOSS_TEAMBUFF, XTable.XTableStageTeamBuff, "Id")
    for id, v in pairs(TeamBuffCfg) do
        local maxCount = 0
        for _, buffId in ipairs(v.BuffId) do
            if buffId > 0 then
                maxCount = maxCount + 1
            end
        end
        TeamBuffMaxCountDic[id] = maxCount
    end

    local banners = XTableManager.ReadByIntKey(TABLE_CHALLENGE_BANNER, XTable.XTableFubenChallengeBanner, "Id")
    for _, v in pairs(banners) do
        FubenChallengeBanners[v.Type] = v
    end
end

local function GetStageCfg(stageId)
    local config = StageCfg[stageId]
    if not config then
        XLog.Error("XFubenConfigs.GetStageCfgs Error: StageId: " .. stageId)
        return
    end
    return config
end

local function GetTeamBuffCfg(teamBuffId)
    local config = TeamBuffCfg[teamBuffId]
    if not config then
        XLog.Error("XFubenConfigs.GetTeamBuffCfg Error: teamBuffId: " .. teamBuffId)
        return
    end
    return config
end

local function GetSettleLoseTipCfg(settleLoseTipId)
    local config = SettleLoseTipCfg[settleLoseTipId]
    if not config then
        XLog.ErrorTableDataNotFound(
        "XFubenConfigs.GetSettleLoseTipCfg",
        "失败提示",
        TABLE_SETTLE_LOST_TIP,
        "Id",
        tostring(settleLoseTipId))
        return {}
    end
    return config
end

function XFubenConfigs.GetStageCfgs()
    return StageCfg
end

function XFubenConfigs.GetBuffDes(buffId)
    local fightEventCfg = buffId and buffId ~= 0 and CS.XNpcManager.GetFightEventTemplate(buffId)
    return fightEventCfg and fightEventCfg.Description or ""
end

function XFubenConfigs.GetStageLevelControlCfg()
    return StageLevelControlCfg
end

function XFubenConfigs.GetStageMultiplayerLevelControlCfg()
    return StageMultiplayerLevelControlCfg
end

function XFubenConfigs.GetStageMultiplayerLevelControlCfgById(id)
    return StageMultiplayerLevelControlCfg[id]
end

function XFubenConfigs.GetStageTransformCfg()
    return StageTransformCfg
end

function XFubenConfigs.GetFlopRewardTemplates()
    return FlopRewardTemplates
end

function XFubenConfigs.GetActivitySortRules()
    return ActivitySortRules
end

function XFubenConfigs.GetFeaturesById(id)
    local t = FubenFeatures[id]
    if not t then
        XLog.ErrorTableDataNotFound("XFubenConfigs.GetFeaturesById", "FubenFeatures", TABLE_FUBENFEATURES, "Id", tostring(id))
        return nil
    end
    return t
end

function XFubenConfigs.GetActivityPriorityByActivityIdAndType(activityId, type)
    for _, v in pairs(ActivitySortRules) do
        if v.ActivityId == activityId and v.Type == type then
            return v.Priority
        end
    end
    return 0
end

function XFubenConfigs.GetStageFightControl(id)
    for _, v in pairs(StageFightControlCfg) do
        if v.Id == id then
            return v
        end
    end
    return nil
end

function XFubenConfigs.IsKeepPlayingStory(stageId)
    local targetCfg = StageCfg[stageId]
    if not targetCfg or not targetCfg.KeepPlayingStory then
        return false
    end
    return targetCfg.KeepPlayingStory == 1
end

function XFubenConfigs.GetChapterBannerByType(bannerType)
    return FubenChallengeBanners[bannerType] or {}
end

function XFubenConfigs.InitNewChallengeConfigs()
    FubenNewChallenge = {}
    for _, v in pairs(FubenChallengeBanners) do
        if v.ShowNewStartTime and v.ShowNewEndTime then
            local timeNow = XTime.GetServerNowTimestamp()
            local startTime = XTime.ParseToTimestamp(v.ShowNewStartTime)
            local endTime = XTime.ParseToTimestamp(v.ShowNewEndTime)
            if endTime and timeNow <= endTime then
                table.insert(FubenNewChallenge, v)
            end
            if startTime > endTime then
                XLog.Error("新挑战活动配置有误，起始时间晚于结束时间，表路径：" .. TABLE_CHALLENGE_BANNER .. " 问题Id :" .. tostring(v.Id))
            end
        end
    end
    return FubenNewChallenge
end

function XFubenConfigs.GetNewChallengeConfigs() -- 获取新挑战玩法数据 
    return FubenNewChallenge or XFubenConfigs.InitNewChallengeConfigs()
end

function XFubenConfigs.GetNewChallengeConfigById(id) -- 根据Id取得FubenChallengeBanner配置
    for i in pairs(FubenChallengeBanners) do
        if FubenChallengeBanners[i].Id == id then
            return FubenChallengeBanners[i]
        end
    end
    return nil
end

function XFubenConfigs.GetNewChallengeConfigsLength() -- 获取新活动数量
    local config = XFubenConfigs.GetNewChallengeConfigs()
    return #config
end

function XFubenConfigs.GetNewChallengeFunctionId(index)
    local config = XFubenConfigs.GetNewChallengeConfigs()
    return config[index].FunctionId
end

function XFubenConfigs.GetNewChallengeId(index) -- 根据索引获取新挑战活动的Id
    local config = XFubenConfigs.GetNewChallengeConfigs()
    return config[index].Id
end

function XFubenConfigs.GetNewChallengeStartTimeStamp(index)
    local config = XFubenConfigs.GetNewChallengeConfigs()
    return XTime.ParseToTimestamp(config[index].ShowNewStartTime)
end

function XFubenConfigs.GetNewChallengeEndTimeStamp(index)
    local config = XFubenConfigs.GetNewChallengeConfigs()
    return XTime.ParseToTimestamp(config[index].ShowNewEndTime)
end

function XFubenConfigs.IsNewChallengeStartByIndex(index) -- 根据索引获取新挑战时段是否已经开始
    return XFubenConfigs.GetNewChallengeStartTimeStamp(index) <= XTime.GetServerNowTimestamp()
end

function XFubenConfigs.IsNewChallengeStartById(id) -- 根据挑战活动Id获取新挑战时段是否已经开始
    if not id then return false end
    local cfg = XFubenConfigs.GetNewChallengeConfigById(id)
    if not cfg or not cfg.ShowNewStartTime then return false end
    return XTime.ParseToTimestamp(cfg.ShowNewStartTime) <= XTime.GetServerNowTimestamp()
end

function XFubenConfigs.GetMultiChallengeStageConfigs()
    return MultiChallengeConfigs
end

function XFubenConfigs.GetTableStagePath()
    return TABLE_STAGE
end

--副本上阵角色类型限制相关:
local ROOM_CHARACTER_LIMIT_CONFIGS = {
    [XFubenConfigs.CharacterLimitType.Normal] = {
        Name = CSXTextManagerGetText("CharacterTypeLimitNameNormal"),
        ImageTeamEdit = CSXGameClientConfig:GetString("TeamCharacterTypeNormalLimitImage"),
        ImageSelectCharacter = CSXGameClientConfig:GetString("TeamRequireCharacterNormalImage"),
        TextTeamEdit = CSXTextManagerGetText("TeamCharacterTypeNormalLimitText"),
        TextSelectCharacter = CSXTextManagerGetText("TeamRequireCharacterNormalText"),
        TextChapterLimit = CSXTextManagerGetText("ChapterCharacterTypeLimitNormal"),
    },
    [XFubenConfigs.CharacterLimitType.Isomer] = {
        Name = CSXTextManagerGetText("CharacterTypeLimitNameIsomer"),
        ImageTeamEdit = CSXGameClientConfig:GetString("TeamCharacterTypeIsomerLimitImage"),
        ImageSelectCharacter = CSXGameClientConfig:GetString("TeamRequireCharacterIsomerImage"),
        TextTeamEdit = CSXTextManagerGetText("TeamCharacterTypeIsomerLimitText"),
        TextSelectCharacter = CSXTextManagerGetText("TeamRequireCharacterIsomerText"),
        TextChapterLimit = CSXTextManagerGetText("ChapterCharacterTypeLimitIsomer"),
    },
    [XFubenConfigs.CharacterLimitType.IsomerDebuff] = {
        Name = CSXTextManagerGetText("CharacterTypeLimitNameIsomerDebuff"),
        ImageTeamEdit = CSXGameClientConfig:GetString("TeamCharacterTypeIsomerDebuffLimitImage"),
        ImageSelectCharacter = CSXGameClientConfig:GetString("TeamRequireCharacterIsomerDebuffImage"),
        TextTeamEdit = function(buffDes) return CSXTextManagerGetText("TeamCharacterTypeIsomerDebuffLimitText", buffDes) end,
        TextTeamEditDefault = CSXTextManagerGetText("TeamCharacterTypeIsomerDebuffLimitDefaultText"),
        TextSelectCharacter = function(buffDes) return CSXTextManagerGetText("TeamRequireCharacterIsomerDebuffText", buffDes) end,
        TextSelectCharacterDefault = CSXTextManagerGetText("TeamRequireCharacterIsomerDebuffDefaultText"),
        TextChapterLimit = function(buffDes) return CSXTextManagerGetText("ChapterCharacterTypeLimitIsomerDebuff", buffDes) end,
    },
    [XFubenConfigs.CharacterLimitType.NormalDebuff] = {
        Name = CSXTextManagerGetText("CharacterTypeLimitNameNormalDebuff"),
        ImageTeamEdit = CSXGameClientConfig:GetString("TeamCharacterTypeNormalDebuffLimitImage"),
        ImageSelectCharacter = CSXGameClientConfig:GetString("TeamRequireCharacterNormalDebuffImage"),
        TextTeamEdit = function(buffDes) return CSXTextManagerGetText("TeamCharacterTypeNormalDebuffLimitText", buffDes) end,
        TextTeamEditDefault = CSXTextManagerGetText("TeamCharacterTypeNormalDebuffLimitDefaultText"),
        TextSelectCharacter = function(buffDes) return CSXTextManagerGetText("TeamRequireCharacterNormalDebuffText", buffDes) end,
        TextSelectCharacterDefault = CSXTextManagerGetText("TeamRequireCharacterNormalDebuffDefaultText"),
        TextChapterLimit = function(buffDes) return CSXTextManagerGetText("ChapterCharacterTypeLimitNormalDebuff", buffDes) end,
    },
}

local function GetStageCharacterLimitConfig(characterLimitType)
    return ROOM_CHARACTER_LIMIT_CONFIGS[characterLimitType]
end

function XFubenConfigs.GetStageCharacterLimitType(stageId)
    return GetStageCfg(stageId).CharacterLimitType
end

function XFubenConfigs.GetStageCharacterLimitBuffId(stageId)
    local limitBuffId = GetStageCfg(stageId).LimitBuffId
    return XFubenConfigs.GetLimitShowBuffId(limitBuffId)
end

function XFubenConfigs.GetLimitShowBuffId(limitBuffId)
    local config = StageCharacterLimitBuffConfig[limitBuffId]
    local buffIds = config and config.BuffId
    return buffIds and buffIds[1] or 0
end

function XFubenConfigs.IsStageCharacterLimitConfigExist(characterLimitType)
    return GetStageCharacterLimitConfig(characterLimitType) and true
end

-- 编队界面限制角色类型Icon
function XFubenConfigs.GetStageCharacterLimitImageTeamEdit(characterLimitType)
    local config = GetStageCharacterLimitConfig(characterLimitType)
    if not config then return "" end
    return config.ImageTeamEdit
end

-- 编队界面限制角色类型文本
function XFubenConfigs.GetStageCharacterLimitTextTeamEdit(characterLimitType, characterType, buffId)
    local config = GetStageCharacterLimitConfig(characterLimitType)
    if not config then return "" end

    local text = config.TextTeamEdit
    local defaultText = config.TextTeamEditDefault
    if not defaultText then
        return text
    end

    local defaultCharacterType = XDataCenter.FubenManager.GetDefaultCharacterTypeByCharacterLimitType(characterLimitType)
    if characterType and characterType ~= defaultCharacterType then
        if type(text) == "function" then
            local buffDes = XFubenConfigs.GetBuffDes(buffId)
            return text(buffDes)
        end
    else
        return defaultText
    end

    return text
end

-- 选人界面限制角色类型Icon
function XFubenConfigs.GetStageCharacterLimitImageSelectCharacter(characterLimitType)
    local config = GetStageCharacterLimitConfig(characterLimitType)
    if not config then return "" end
    return config.ImageSelectCharacter
end

-- 选人界面限制角色类型文本
function XFubenConfigs.GetStageCharacterLimitTextSelectCharacter(characterLimitType, characterType, buffId)
    local config = GetStageCharacterLimitConfig(characterLimitType)
    if not config then return "" end

    local text = config.TextSelectCharacter
    local defaultText = config.TextSelectCharacterDefault
    if not defaultText then
        return text
    end

    local defaultCharacterType = XDataCenter.FubenManager.GetDefaultCharacterTypeByCharacterLimitType(characterLimitType)
    if characterType ~= defaultCharacterType then
        if type(text) == "function" then
            if not XTool.IsNumberValid(buffId) then
                return defaultText
            end

            local buffDes = XFubenConfigs.GetBuffDes(buffId)
            return text(buffDes)
        end
    else
        return defaultText
    end

    return text
end

-- 限制角色类型分区名称文本
function XFubenConfigs.GetStageCharacterLimitName(characterLimitType)
    local config = GetStageCharacterLimitConfig(characterLimitType)
    if not config then return "" end
    return config.Name
end

-- 章节选人界面限制角色类型文本
function XFubenConfigs.GetChapterCharacterLimitText(characterLimitType, buffId)
    local config = GetStageCharacterLimitConfig(characterLimitType)
    if not config then return "" end

    local text = config.TextChapterLimit
    if type(text) == "function" then
        local buffDes = XFubenConfigs.GetBuffDes(buffId)
        return text(buffDes)
    end
    return text
end

function XFubenConfigs.IsCharacterFitTeamBuff(teamBuffId, characterId)
    if not teamBuffId or teamBuffId <= 0 then return false end
    if not characterId or characterId <= 0 then return false end

    local config = GetTeamBuffCfg(teamBuffId)

    local initQuality = characterId and characterId > 0 and XCharacterConfigs.GetCharMinQuality(characterId)
    if not initQuality or initQuality <= 0 then return false end

    for _, quality in pairs(config.Quality) do
        if initQuality == quality then
            return true
        end
    end

    return false
end

function XFubenConfigs.GetTeamBuffFitCharacterCount(teamBuffId, characterIds)
    local config = GetTeamBuffCfg(teamBuffId)

    local fitCount = 0

    local checkDic = {}
    for _, quality in pairs(config.Quality) do
        checkDic[quality] = true
    end

    for _, characterId in pairs(characterIds) do
        local initQuality = characterId > 0 and XCharacterConfigs.GetCharMinQuality(characterId)
        fitCount = checkDic[initQuality] and fitCount + 1 or fitCount
    end

    return fitCount
end

function XFubenConfigs.GetTeamBuffMaxBuffCount(teamBuffId)
    return TeamBuffMaxCountDic[teamBuffId] or 0
end

function XFubenConfigs.GetTeamBuffOnIcon(teamBuffId)
    local config = GetTeamBuffCfg(teamBuffId)
    return config.OnIcon
end

function XFubenConfigs.GetTeamBuffOffIcon(teamBuffId)
    local config = GetTeamBuffCfg(teamBuffId)
    return config.OffIcon
end

function XFubenConfigs.GetTeamBuffTitle(teamBuffId)
    local config = GetTeamBuffCfg(teamBuffId)
    return config.Title
end

function XFubenConfigs.GetTeamBuffDesc(teamBuffId)
    local config = GetTeamBuffCfg(teamBuffId)
    return string.gsub(config.Desc, "\\n", "\n")
end

-- 根据符合初始品质要求的characterId列表获取对应的同调加成buffId
function XFubenConfigs.GetTeamBuffShowBuffId(teamBuffId, characterIds)
    local config = GetTeamBuffCfg(teamBuffId)
    local fitCount = XFubenConfigs.GetTeamBuffFitCharacterCount(teamBuffId, characterIds)
    return config.BuffId[fitCount]
end

-- 根据关卡ID查找关卡词缀列表
function XFubenConfigs.GetStageFightEventByStageId(stageId)
    if not StageFightEvent[stageId] then
        XLog.ErrorTableDataNotFound(
        "XFubenConfigs.GetStageFightEventByStageId",
        "通用关卡词缀数据",
        TABLE_STAGE_FIGHT_EVENT,
        "StageId",
        tostring(stageId)
        )
        return {}
    end
    return StageFightEvent[stageId]
end
-- 根据ID查找词缀详细
function XFubenConfigs.GetStageFightEventDetailsByStageFightEventId(eventId)
    if not StageFightEventDetails[eventId] then
        XLog.ErrorTableDataNotFound(
        "XFubenConfigs.GetStageFightEventDetailsByStageFightEventId",
        "通用关卡词缀数据",
        TABLE_STAGE_FIGHT_EVENT_DETAILS,
        "Id",
        tostring(eventId)
        )
        return nil
    end
    return StageFightEventDetails[eventId]
end

---
--- 获取 失败提示描述 数组
function XFubenConfigs.GetTipDescList(settleLoseTipId)
    local cfg = GetSettleLoseTipCfg(settleLoseTipId)
    return cfg.TipDesc
end

---
--- 获取 失败提示跳转Id 数组
function XFubenConfigs.GetSkipIdList(settleLoseTipId)
    local cfg = GetSettleLoseTipCfg(settleLoseTipId)
    return cfg.SkipId
end

--获取关卡推荐角色类型（构造体/感染体）
function XFubenConfigs.GetStageRecommendCharacterType(stageId)
    local config = StageRecommendConfigs[stageId]
    if not config then return end

    local value = config.CharacterType
    return value ~= 0 and value or nil
end

--获取关卡推荐角色元素属性（物理/火/雷/冰/暗）
function XFubenConfigs.GetStageRecommendCharacterElement(stageId)
    local config = StageRecommendConfigs[stageId]
    if not config then return end

    local value = config.CharacterElement
    return value ~= 0 and value or nil
end

--是否为关卡推荐角色
function XFubenConfigs.IsStageRecommendCharacterType(stageId, Id)
    local characterId = XRobotManager.GetCharacterId(Id)
    local characterType = XCharacterConfigs.GetCharacterType(characterId)
    local recommendType = XFubenConfigs.GetStageRecommendCharacterType(stageId)
    local element = XCharacterConfigs.GetCharacterElement(characterId)
    local recommendElement = XFubenConfigs.GetStageRecommendCharacterElement(stageId) or 0
    --(废弃)特殊逻辑：如果为授格者，一定是推荐(废弃)
    --if characterType == XCharacterConfigs.CharacterType.Isomer and recommendType == characterType then
    --    return true
    --end

    --特殊逻辑：当关卡推荐元素为0时推荐所有该角色类型（构造体/授格者）的构造体
    --（此处兼容之前废弃的《授格者一定推荐的特殊逻辑》，StageRecommend配置中的授格者类型下推荐属性都是0，故兼容）

    return XTool.IsNumberValid(recommendType) and 
    recommendType == characterType and 
    (element == recommendElement or recommendElement == 0)
end

function XFubenConfigs.GetStageName(stageId)
    local config = GetStageCfg(stageId)
    return config and config.Name or ""
end

function XFubenConfigs.GetStageType(stageId)
    local config = GetStageCfg(stageId)
    return config and config.StageType or ""
end

---
--- 关卡图标
function XFubenConfigs.GetStageIcon(stageId)
    local config = GetStageCfg(stageId)
    return (config or {}).Icon
end

---
--- 三星条件描述数组
function XFubenConfigs.GetStarDesc(stageId)
    local config = GetStageCfg(stageId)
    return (config or {}).StarDesc
end

---
--- 关卡需要消耗的体力
function XFubenConfigs.GetRequireActionPoint(stageId)
    local config = GetStageCfg(stageId)
    return (config or {}).RequireActionPoint
end

---
--- 关卡首通奖励
function XFubenConfigs.GetFirstRewardShow(stageId)
    local config = GetStageCfg(stageId)
    return (config or {}).FirstRewardShow
end

---
--- 关卡非首通奖励
function XFubenConfigs.GetFinishRewardShow(stageId)
    local config = GetStageCfg(stageId)
    return (config or {}).FinishRewardShow
end

---
--- 获得战前剧情ID
function XFubenConfigs.GetBeginStoryId(stageId)
    local config = GetStageCfg(stageId)
    return (config or {}).BeginStoryId
end