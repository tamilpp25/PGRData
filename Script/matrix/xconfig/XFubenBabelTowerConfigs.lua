local tableInsert = table.insert

XFubenBabelTowerConfigs = {}

local SHARE_BABEL_ACTIVITY = "Share/Fuben/BabelTower/BabelTowerActivity.tab"
local SHARE_BABEL_BUFF = "Share/Fuben/BabelTower/BabelTowerBuff.tab"
local SHARE_BABEL_BUFFGROUP = "Share/Fuben/BabelTower/BabelTowerBuffGroup.tab"
local SHARE_BABEL_RANKLEVEL = "Share/Fuben/BabelTower/BabelTowerRankLevel.tab"
local SHARE_BABEL_STAGE = "Share/Fuben/BabelTower/BabelTowerStage.tab"
local SHARE_BABEL_STAGEGUIDE = "Share/Fuben/BabelTower/BabelTowerStageGuide.tab"
local SHARE_BABEL_SUPPORTCONDITION = "Share/Fuben/BabelTower/BabelTowerSupportCondition.tab"
local SHARE_BABEL_RANKREWARD = "Share/Fuben/BabelTower/BabelTowerRankReward.tab"
local SHARE_BABEL_STAGELEVEL = "Share/Fuben/BabelTower/BabelTowerStageLevel.tab"
local SHARE_BABEL_STAGELEVELGLOBALUNLOCK = "Share/Fuben/BabelTower/BabelTowerStageLevelGlobalUnlock.tab"

local CLIENT_BABEL_STAGEGUIDEDETAIL = "Client/Fuben/BabelTower/BabelTowerStageGuideDetails.tab"
local CLIENT_BABEL_BUFFDETAIL = "Client/Fuben/BabelTower/BabelTowerBuffDetails.tab"
local CLIENT_BABEL_BUFFGROUPDETAIL = "Client/Fuben/BabelTower/BabelTowerBuffGroupDetails.tab"
local CLIENT_BABEL_BUFFGROUPDETAILTEXT = "Client/Fuben/BabelTower/BabelTowerBuffGroupDetailsText.tab"
local CLIENT_BABEL_STAGEDETAIL = "Client/Fuben/BabelTower/BabelTowerStageDetails.tab"
local CLIENT_BABEL_ACTIVITYDETAIL = "Client/Fuben/BabelTower/BabelTowerActivityDetails.tab"
local CLIENT_BABEL_CONDITIONDETAIL = "Client/Fuben/BabelTower/BabelTowerConditionDetails.tab"
local CLIENT_BABEL_CLIENT_CONFIG = "Client/Fuben/BabelTower/BabelTowerClientConfig.tab"

local BabelActivityTemplate = {}
local BabelBuffTemplate = {}
local BabelBuffGroupTemplate = {}
local BabelRankLevelTemplate = {}
local BabelStageTemplate = {}
local BabelStageGuideTemplate = {}
local BabelSupportConditionTemplate = {}
local BabelRankRewardTemplate = {}
local BabelStageLevelDic = {}
local BabelStageLevelLockBuffIdDic = {}
local BabeGlobalUnlockTemplate = {}

local BabelStageGuideDetailsConfigs = {}
local BabelBuffDetailsConfigs = {}
---@type XTableBabelTowerBuffGroupDetails[]
local BabelBuffGroupDetailsConfigs = {}
---@type XTableBabelTowerBuffGroupDetailsText[]
local BabelBuffGroupDetailsTextConfigs = {}
local BabelStageConfigs = {}
local BabelActivityDetailsConfigs = {}
local BabelConditionDetailsConfigs = {}
local BabelGlobalUnlockDetailsConfigs = {}

XFubenBabelTowerConfigs.MAX_TEAM_MEMBER = 3         -- 最多出站人数
XFubenBabelTowerConfigs.LEADER_POSITION = 1         -- 队长位置
XFubenBabelTowerConfigs.FIRST_FIGHT_POSITION = 1    -- 首发位置
XFubenBabelTowerConfigs.BabelTowerStatus = {
    Close = 0,
    Open = 1,
    FightEnd = 2,
    End = 3
}

XFubenBabelTowerConfigs.RankPlaform = {
    Win = 0,
    Android = 1,
    IOS = 2,
}

XFubenBabelTowerConfigs.RankType = {
    NoRank = 0,
    OnlyRank = 1,
    RankAndReward = 2,
}

XFubenBabelTowerConfigs.ActivityType = {
    -- 正常
    Normal = 1,
    -- 复刻，扩展
    Extra = 2,
}

XFubenBabelTowerConfigs.Difficult = {
    Default = 0,
    Easy = 1,
    Normal = 2,
    Middle = 3,
    Hard = 4,
    Count = 4,
}

XFubenBabelTowerConfigs.RankIcon = {
    [1] = CS.XGame.ClientConfig:GetString("BabelTowerRankIcon1"),
    [2] = CS.XGame.ClientConfig:GetString("BabelTowerRankIcon2"),
    [3] = CS.XGame.ClientConfig:GetString("BabelTowerRankIcon3"),
}

XFubenBabelTowerConfigs.ChallengePhase = 1          -- 选择挑战阶段
XFubenBabelTowerConfigs.SupportPhase = 2            -- 选择支援阶段
XFubenBabelTowerConfigs.CHALLENGE_CHILD_UI = "UiBabelTowerChildChallenge"       -- 挑战界面
XFubenBabelTowerConfigs.SUPPORT_CHILD_UI = "UiBabelTowerChildSupport"           -- 支援界面

XFubenBabelTowerConfigs.TIPSTYPE_ENVIRONMENT = 1    -- 环境情报
XFubenBabelTowerConfigs.TIPSTYPE_CHALLENGE = 2      -- 挑战详情
XFubenBabelTowerConfigs.TIPSTYPE_SUPPORT = 3        -- 支援详情

XFubenBabelTowerConfigs.TYPE_CHALLENGE = 1          --挑战类型
XFubenBabelTowerConfigs.TYPE_SUPPORT = 2            --支援类型

-- 准备结束界面tips
XFubenBabelTowerConfigs.BattleReady = 1
XFubenBabelTowerConfigs.BattleEnd = 2
XFubenBabelTowerConfigs.MAX_BUFF_COUNT = 10
XFubenBabelTowerConfigs.MAX_CHALLENGE_BUFF_COUNT = CS.XGame.ClientConfig:GetInt("BabelTowerMaxChallengeBuff")
XFubenBabelTowerConfigs.MAX_SUPPORT_BUFF_COUNT = CS.XGame.ClientConfig:GetInt("BabelTowerMaxSupportBuff")
XFubenBabelTowerConfigs.START_INDEX = 0

-- 事态类型
XFubenBabelTowerConfigs.DIFFICULTY_NONE = 0
XFubenBabelTowerConfigs.DIFFICULTY_NORMAL = 1       -- 普通
XFubenBabelTowerConfigs.DIFFICULTY_URGENCY = 2      -- 紧急
XFubenBabelTowerConfigs.DIFFICULTY_CRITICAL = 3     -- 高危

-- 上次选中的StageId key
XFubenBabelTowerConfigs.LAST_SELECT_KEY = "BabelTowerLastSelectedStageId"
-- 第一次查看环境
XFubenBabelTowerConfigs.ENVIROMENT_DOT_KEY = "babelenvironment_%s_%s_%s"
-- 第一次播放剧情
XFubenBabelTowerConfigs.HAS_PLAY_BEGINSTORY = "BabelTowerPlayBeginStory"
-- 作战等级无法提升时的提示
XFubenBabelTowerConfigs.AFFIX_LEVEL_INADEQUATE_KEY = "BabelTowerAffixLevelInadequate"
-- 挑战过高难度时的提示
XFubenBabelTowerConfigs.ABILITY_WARNING_KEY = "BabelTowerAbilityWarning_%s_%s_%s"
-- 巴别塔收藏品品质等级检测
XFubenBabelTowerConfigs.COLLECTION_ITEM_QUALITY = "BabelTowerCollectionItemQuality"
-- 巴别塔开放期间首次进入巴别塔检测
XFubenBabelTowerConfigs.OPEN_FIRST_ENTER = "BabelTowerOpenFirstEnter"

local function InitStageLevelConfig()
    local template = XTableManager.ReadByIntKey(SHARE_BABEL_STAGELEVEL, XTable.XTableBabelTowerStageLevel, "Id")

    for _, config in pairs(template) do
        local stageId = config.StageId

        local stageConfig = BabelStageLevelDic[stageId]
        if not stageConfig then
            stageConfig = {}
            BabelStageLevelDic[stageId] = stageConfig
        end

        local level = config.Level
        stageConfig[level] = config

        local stageLockBuffIdDic = BabelStageLevelLockBuffIdDic[stageId]
        if not stageLockBuffIdDic then
            stageLockBuffIdDic = {}
            BabelStageLevelLockBuffIdDic[stageId] = stageLockBuffIdDic
        end

        local lockBuffIds = config.LockBuffId
        for _, buffId in pairs(lockBuffIds) do
            if buffId ~= 0 then
                local oldLevel = stageLockBuffIdDic[buffId] or 0
                if level > oldLevel then
                    stageLockBuffIdDic[buffId] = level
                end
            end
        end
    end
end

function XFubenBabelTowerConfigs.Init()
    BabelActivityTemplate = XTableManager.ReadByIntKey(SHARE_BABEL_ACTIVITY, XTable.XTableBabelTowerActivity, "Id")
    BabelBuffTemplate = XTableManager.ReadByIntKey(SHARE_BABEL_BUFF, XTable.XTableBabelTowerBuff, "Id")
    BabelBuffGroupTemplate = XTableManager.ReadByIntKey(SHARE_BABEL_BUFFGROUP, XTable.XTableBabelTowerBuffGroup, "Id")
    BabelRankLevelTemplate = XTableManager.ReadByIntKey(SHARE_BABEL_RANKLEVEL, XTable.XTableBabelTowerRankLevel, "Id")
    BabelStageTemplate = XTableManager.ReadByIntKey(SHARE_BABEL_STAGE, XTable.XTableBabelTowerStage, "Id")
    BabelStageGuideTemplate = XTableManager.ReadByIntKey(SHARE_BABEL_STAGEGUIDE, XTable.XTableBabelTowerStageGuide, "Id")
    BabelSupportConditionTemplate = XTableManager.ReadByIntKey(SHARE_BABEL_SUPPORTCONDITION, XTable.XTableBabelTowerSupportCondition, "Id")
    BabelRankRewardTemplate = XTableManager.ReadByIntKey(SHARE_BABEL_RANKREWARD, XTable.XTableBabelTowerRankReward, "Id")
    BabeGlobalUnlockTemplate = XTableManager.ReadByIntKey(SHARE_BABEL_STAGELEVELGLOBALUNLOCK, XTable.XTableBabelTowerStageLevelGlobalUnlock, "Id")

    BabelStageGuideDetailsConfigs = XTableManager.ReadByIntKey(CLIENT_BABEL_STAGEGUIDEDETAIL, XTable.XTableBabelTowerStageGuideDetails, "Id")
    BabelBuffDetailsConfigs = XTableManager.ReadByIntKey(CLIENT_BABEL_BUFFDETAIL, XTable.XTableBabelTowerBuffDetails, "Id")
    BabelBuffGroupDetailsConfigs = XTableManager.ReadByIntKey(CLIENT_BABEL_BUFFGROUPDETAIL, XTable.XTableBabelTowerBuffGroupDetails, "Id")
    BabelBuffGroupDetailsTextConfigs = XTableManager.ReadByIntKey(CLIENT_BABEL_BUFFGROUPDETAILTEXT, XTable.XTableBabelTowerBuffGroupDetailsText, "Id")
    BabelStageConfigs = XTableManager.ReadByIntKey(CLIENT_BABEL_STAGEDETAIL, XTable.XTableBabelTowerStageDetails, "Id")
    BabelActivityDetailsConfigs = XTableManager.ReadByIntKey(CLIENT_BABEL_ACTIVITYDETAIL, XTable.XTableBabelTowerActivityDetails, "Id")
    BabelConditionDetailsConfigs = XTableManager.ReadByIntKey(CLIENT_BABEL_CONDITIONDETAIL, XTable.XTableBabelTowerConditionDetails, "Id")

    InitStageLevelConfig()
    XConfigCenter.CreateGetPropertyByFunc(XFubenBabelTowerConfigs, "BabelClienConfig", function()
        return XTableManager.ReadByStringKey(CLIENT_BABEL_CLIENT_CONFIG, XTable.XTableBabelTowerClientConfig, "Key")
    end)
end

function XFubenBabelTowerConfigs.GetActivityName(id)
    if not BabelActivityDetailsConfigs[id] then return "" end
    return BabelActivityDetailsConfigs[id].Name
end

function XFubenBabelTowerConfigs.GetActivityBeginStory(id)
    if not BabelActivityDetailsConfigs[id] then return nil end
    return BabelActivityDetailsConfigs[id].BeginStoryId
end

function XFubenBabelTowerConfigs.GetActivityRankTitle(id)
    if not BabelActivityDetailsConfigs[id] then return nil end
    return BabelActivityDetailsConfigs[id].RankTitle
end

function XFubenBabelTowerConfigs.GetActivityRewardId(id)
    if not BabelActivityDetailsConfigs[id] then return 0 end
    return BabelActivityDetailsConfigs[id].RewardId
end

function XFubenBabelTowerConfigs.GetConditionDescription(id)
    if not BabelConditionDetailsConfigs[id] then return "" end
    return BabelConditionDetailsConfigs[id].Desc
end

function XFubenBabelTowerConfigs.GetAllBabelTowerActivityTemplate()
    return BabelActivityTemplate
end

function XFubenBabelTowerConfigs.GetBabelTowerActivityTemplateById(id)
    if not BabelActivityTemplate[id] then
        XLog.ErrorTableDataNotFound("XFubenBabelTowerConfigs.GetBabelTowerActivityTemplateById",
        "BabelTowerActivity", SHARE_BABEL_ACTIVITY, "Id", tostring(id))
        return nil
    end
    return BabelActivityTemplate[id]
end

-- 获取stage数据,加成相关
function XFubenBabelTowerConfigs.GetBabelTowerStageTemplate(stageId)
    if not BabelStageTemplate[stageId] then
        XLog.ErrorTableDataNotFound("XFubenBabelTowerConfigs.GetBabelTowerStageTemplate",
        "BabelTowerStage", SHARE_BABEL_STAGE, "stageId", tostring(stageId))
        return nil
    end
    return BabelStageTemplate[stageId]
end

function XFubenBabelTowerConfigs.GetBaseBuffIds(stageId)
    local buffIds = {}

    local config = XFubenBabelTowerConfigs.GetBabelTowerStageTemplate(stageId)
    for _, buffId in pairs(config.BaseBuffId) do
        if buffId > 0 then
            tableInsert(buffIds, buffId)
        end
    end

    return buffIds
end

function XFubenBabelTowerConfigs.GetStageTeamCount(stageId)
    local config = XFubenBabelTowerConfigs.GetBabelTowerStageTemplate(stageId)
    return config.TeamCount
end

-- 引导的数据
function XFubenBabelTowerConfigs.GetBabelTowerStageGuideTemplate(guideId)
    if not BabelStageGuideTemplate[guideId] then
        XLog.ErrorTableDataNotFound("XFubenBabelTowerConfigs.GetBabelTowerStageGuideTemplate",
        "BabelTowerStageGuide", SHARE_BABEL_STAGEGUIDE, "guideId", tostring(guideId))
        return nil
    end
    return BabelStageGuideTemplate[guideId]
end

-- 关卡引导的本地数据
function XFubenBabelTowerConfigs.GetStageGuideConfigs(guideId)
    if not BabelStageGuideDetailsConfigs[guideId] then
        XLog.ErrorTableDataNotFound("XFubenBabelTowerConfigs.GetStageGuideConfigs",
        "StageGuideDetails", CLIENT_BABEL_STAGEGUIDEDETAIL, "guideId", tostring(guideId))
        return nil
    end
    return BabelStageGuideDetailsConfigs[guideId]
end

-- buffGroup组的本地数据
function XFubenBabelTowerConfigs.GetBabelBuffGroupConfigs(buffGroupId)
    if not BabelBuffGroupDetailsConfigs[buffGroupId] then
        XLog.ErrorTableDataNotFound("XFubenBabelTowerConfigs.GetBuffGroupConfigs",
        "BabelBuffGroupDetails", CLIENT_BABEL_BUFFGROUPDETAIL, "buffGroupId", tostring(buffGroupId))
        return nil
    end
    return BabelBuffGroupDetailsConfigs[buffGroupId]
end

function XFubenBabelTowerConfigs.GetBabelBuffGroupText(id)
    if not XTool.IsNumberValid(id) then
        return ""
    end
    if not BabelBuffGroupDetailsTextConfigs[id] then
        XLog.ErrorTableDataNotFound("XFubenBabelTowerConfigs.GetBabelBuffGroupText", "BabelTowerBuffGroupDetailsText", CLIENT_BABEL_BUFFGROUPDETAILTEXT, "Id", tostring(id))
        return ""
    end
    return BabelBuffGroupDetailsTextConfigs[id].Text or ""
end

function XFubenBabelTowerConfigs.IsBuffGroupHard(buffGroupId)
    local config = XFubenBabelTowerConfigs.GetBabelBuffGroupConfigs(buffGroupId)
    return config and config.IsStress and config.IsStress ~= 0
end

-- buff的本地数据
function XFubenBabelTowerConfigs.GetBabelBuffConfigs(buffId)
    if not BabelBuffDetailsConfigs[buffId] then
        XLog.ErrorTableDataNotFound("XFubenBabelTowerConfigs.GetBabelBuffConfigs",
        "BabelBuffGroupDetails", CLIENT_BABEL_BUFFDETAIL, "buffId", tostring(buffId))
        return nil
    end
    return BabelBuffDetailsConfigs[buffId]
end

function XFubenBabelTowerConfigs.GetBaseBuffNameWithSpilt(buffId)
    local config = XFubenBabelTowerConfigs.GetBabelBuffConfigs(buffId)
    return XUiHelper.RichTextToTextString(config.Name)
end

-- stage本地数据
function XFubenBabelTowerConfigs.GetBabelStageConfigs(stageId)
    if not BabelStageConfigs[stageId] then
        XLog.ErrorTableDataNotFound("XFubenBabelTowerConfigs.GetBabelStageConfigs",
        "BabelStageDetails", CLIENT_BABEL_STAGEDETAIL, "stageId", tostring(stageId))
        return nil
    end
    return BabelStageConfigs[stageId]
end

function XFubenBabelTowerConfigs.GetStageName(stageId)
    local config = XFubenBabelTowerConfigs.GetBabelStageConfigs(stageId)
    return config.Name
end


-- 排行榜分段
function XFubenBabelTowerConfigs.GetBabelTowerRankLevelTemplate(id)
    if not BabelRankLevelTemplate[id] then
        XLog.ErrorTableDataNotFound("XFubenBabelTowerConfigs.GetBabelTowerRankLevelTemplate", "RankLevel", SHARE_BABEL_RANKLEVEL, "Id", tostring(id))
        return nil
    end
    return BabelRankLevelTemplate[id]
end

-- 支援条件
function XFubenBabelTowerConfigs.GetBabelTowerSupportConditonTemplate(supportId)
    if not BabelSupportConditionTemplate[supportId] then
        XLog.ErrorTableDataNotFound("XFubenBabelTowerConfigs.GetBabelTowerSupportConditonTemplate",
        "SupportCondition", SHARE_BABEL_SUPPORTCONDITION, "supportId", tostring(supportId))
        return nil
    end
    return BabelSupportConditionTemplate[supportId]
end

-- buff组
function XFubenBabelTowerConfigs.GetBabelTowerBuffGroupTemplate(groupId)
    if not BabelBuffGroupTemplate[groupId] then
        XLog.ErrorTableDataNotFound("XFubenBabelTowerConfigs.GetBabelTowerBuffGroupTemplate",
        "BabelTowerBuffGroup", SHARE_BABEL_BUFFGROUP, "groupId", tostring(groupId))
        return nil
    end
    return BabelBuffGroupTemplate[groupId]
end

-- buff
---@return XTableBabelTowerBuff
function XFubenBabelTowerConfigs.GetBabelTowerBuffTemplate(buffId)
    if not BabelBuffTemplate[buffId] then
        XLog.ErrorTableDataNotFound("XFubenBabelTowerConfigs.GetBabelTowerBuffTemplate", "BabelBuff", SHARE_BABEL_BUFF, "buffId", tostring(buffId))
        return nil
    end
    return BabelBuffTemplate[buffId]
end

function XFubenBabelTowerConfigs.GetBabelTowerRankReward(rankLevel)
    local rankRewards = {}
    for _, rankReward in pairs(BabelRankRewardTemplate) do
        if rankReward.LevelId == rankLevel then
            table.insert(rankRewards, {
                Id = rankReward.Id,
                RankLevel = rankReward.LevelId,
                MinRank = rankReward.MinRank,
                MaxRank = rankReward.MaxRank,
                MailId = rankReward.MailId,
                RankIcon = rankReward.RankIcon
            })
        end
    end
    table.sort(rankRewards, function(rank1, rank2)
        return rank1.MinRank < rank2.MinRank
    end)
    return rankRewards
end


function XFubenBabelTowerConfigs.GetStageDifficultConfigs(stageId)
    local config = BabelStageLevelDic[stageId]
    if not config then
        XLog.Error("XFubenBabelTowerConfigs.GetStageDifficultConfigs Error: stageId is: " .. stageId .. " ,path is: " .. SHARE_BABEL_STAGELEVEL)
        return
    end
    return config
end

function XFubenBabelTowerConfigs.GetStageDifficultConfig(stageId, difficult)
    local configs = XFubenBabelTowerConfigs.GetStageDifficultConfigs(stageId)
    local config = configs[difficult]
    if not config then
        XLog.Error("XFubenBabelTowerConfigs.GetStageDifficultConfig Error: difficult is: " .. difficult .. " ,path is: " .. SHARE_BABEL_STAGELEVEL, BabelStageLevelDic)
        return
    end
    return config
end

function XFubenBabelTowerConfigs.GetStageDifficultLockBuffIdOpenLevel(stageId, buffId)
    local config = BabelStageLevelLockBuffIdDic[stageId]
    if not config then return 0 end
    return config[buffId] or 0
end

--- 检查buffGroupId是否难度buff组
function XFubenBabelTowerConfigs.CheckBuffGroupIdIsDifficultBuffGroup(stageId, buffGroupId)
    local difficultConfigs = XFubenBabelTowerConfigs.GetStageDifficultConfigs(stageId)
    local buffGroupConfig = XFubenBabelTowerConfigs.GetBabelTowerBuffGroupTemplate(buffGroupId)
    if not buffGroupConfig or not difficultConfigs then
        return false
    end
    local buffIds = buffGroupConfig and buffGroupConfig.BuffId or {}
    for _, config in pairs(difficultConfigs) do
        for _, buffId in pairs(buffIds) do
            -- 只要有一个满足就是难度buff组
            if config.BuffId == buffId then
                return true
            end
        end
    end
    return false
end

--- 检查buffId是否是难度buff
function XFubenBabelTowerConfigs.CheckBuffIdIsDifficultBuff(stageId, buffId)
    local difficultConfigs = XFubenBabelTowerConfigs.GetStageDifficultConfigs(stageId)
    if not difficultConfigs then
        return false
    end
    for _, config in pairs(difficultConfigs) do
        if config.BuffId == buffId then
            return true
        end
    end
    return false
end

--- 获取关卡难度等级通过buffId
function XFubenBabelTowerConfigs.GetStageDifficultLevelByBuffId(stageId, buffId)
    if not XTool.IsNumberValid(buffId) then
        return 1
    end
    local difficultConfigs = XFubenBabelTowerConfigs.GetStageDifficultConfigs(stageId)
    for level, config in pairs(difficultConfigs) do
        if config.BuffId == buffId then
            return level
        end
    end
    return 1
end

function XFubenBabelTowerConfigs.GetStageDifficultRecommendAbility(stageId, difficult)
    local config = XFubenBabelTowerConfigs.GetStageDifficultConfig(stageId, difficult)
    return config.RecommendAblity
end

function XFubenBabelTowerConfigs.GetStageDifficultName(stageId, difficult)
    local config = XFubenBabelTowerConfigs.GetStageDifficultConfig(stageId, difficult)
    return config.Name
end

function XFubenBabelTowerConfigs.GetStageDifficultRatio(stageId, difficult)
    local config = XFubenBabelTowerConfigs.GetStageDifficultConfig(stageId, difficult)
    return getRoundingValue(config.ScoreRatio + 0.0001, 1)
end

-- 根据buffid获取队伍成员数量减少数量
function XFubenBabelTowerConfigs.GetBuffTeamLimitCount(buffId)
    local buffConfig = XFubenBabelTowerConfigs.GetBabelTowerBuffTemplate(buffId)
    if buffConfig then
        if buffConfig.TeamLimitCount <= 0 then
            return 3
        end
        return buffConfig.TeamLimitCount
    end
    return 3
end

function XFubenBabelTowerConfigs.GetActivityConfigValue(key)
    local babelClienConfig = XFubenBabelTowerConfigs.GetBabelClienConfig()
    if not babelClienConfig[key] then
        XLog.ErrorTableDataNotFound(
            "XFubenBabelTowerConfigs.GetActivityConfigValue",
            "客户端配置字段_Key",
            CLIENT_BABEL_CLIENT_CONFIG,
            "Key",
            tostring(key))
    end
    return babelClienConfig[key].Values
end

--region BabelTowerStageLevelGlobalUnlock.tab

---@return XTableBabelTowerStageLevelGlobalUnlock[]
function XFubenBabelTowerConfigs.GetStageLevelGlobalUnlock()
    return BabeGlobalUnlockTemplate
end

--- 检查是否存在buffId根据解锁等级
function XFubenBabelTowerConfigs.CheckIsHaveBuffIdByLevel(level, buffId)
    if not XTool.IsNumberValid(level) then
        return false
    end
    local configs = XFubenBabelTowerConfigs.GetStageLevelGlobalUnlock()
    for _, config in pairs(configs) do
        if config.Level <= level and table.contains(config.BuffIdList or {}, buffId) then
            return true
        end
    end
    return false
end

--endregion
