---==============XTableReformStage========================================
---@class XTableReformStage
---@field public Id number
---@field public Name string
---@field public UnlockStageId number
---@field public OpenTime number
---@field public FullPoint number
---@field public StageGoalId number
---@field public StageGoalDesc string
---@field public Pressure number
---@field public HardPressure number
---@field public EnemyGroupId number
---@field public AffixGroupId number
---@field public HardEnemyGroupId number
---@field public DefaultEnemyGroupId number
---@field public LastDefaultEnemyGroupId number
---=======================================================================
---==============XTableReformChapter======================================
---@class XTableReformChapter
---@field public Id number
---@field public ChapterDesc string
---@field public OpenTime number
---@field public Order number
---@field public FullPoint number
---@field public ChapterEventID number
---@field public ChapterEventDesc number
---@field public ChapterStageID table<number, number>
---=======================================================================
---==============XTableReformCharaterBuffGroup============================
---@class XTableReformCharaterBuffGroup
---@field public Id number
---@field public CharacterBuffId number
---@field public CharacterBuffDesc string

XReform2ndConfigs = XReform2ndConfigs or {}

local XReform2ndConfigs = XReform2ndConfigs
local ReformStageCfgs = nil
local ReformChapterCfgs = nil
local ReformMemberSourceCfgs = nil
local ReformMemberGroupCfgs = nil
local ReformClientCfgs = nil

--region Local Function
local function GetStageCfgs()
    if not ReformStageCfgs then
        ReformStageCfgs = XTableManager.ReadByIntKey("Share/Fuben/Reform/ReformStage.tab", XTable.XTableReformStage, "Id")
    end

    return ReformStageCfgs
end

local function GetChapterCfgs()
    if not ReformChapterCfgs then
        ReformChapterCfgs = XTableManager.ReadByIntKey("Share/Fuben/Reform/ReformChapter.tab", XTable.XTableReformChapter, "Id")
    end

    return ReformChapterCfgs
end

local function GetMemberSourceCfgs()
    if not ReformMemberSourceCfgs then
        ReformMemberSourceCfgs = XTableManager.ReadByIntKey("Share/Fuben/Reform/ReformMemberSource.tab", XTable.XTableReformMemberSource, "Id")
    end

    return ReformMemberSourceCfgs
end

local function GetMemberGroupCfgs()
    if not ReformMemberGroupCfgs then
        ReformMemberGroupCfgs = XTableManager.ReadByIntKey("Share/Fuben/Reform/ReformMemberGroup.tab", XTable.XTableReformGroup, "Id")
    end

    return ReformMemberGroupCfgs
end

local function GetReformClientCfgs()
    if not ReformClientCfgs then
        ReformClientCfgs = XTableManager.ReadByStringKey("Client/Fuben/Reform/ReformClientConfig.tab", XTable.XTableReformClientConfig, "Key")
    end
    
    return ReformClientCfgs
end

---@param id number 关卡ID
---@return XTableReformStage 关卡配置
local function GetReformStageTableConfigById(id)
    local config = GetStageCfgs()

    return config[id]
end

---@param id number 章节ID
---@return XTableReformChapter 章节配置
local function GetReformChapterTableConfigById(id)
    local config = GetChapterCfgs()

    return config[id]
end

local function GetReformMemberSourceConfigById(id)
    local config = GetMemberSourceCfgs()

    return config[id]
end

local function GetReformMemberGroupConfigById(id)
    local config = GetMemberGroupCfgs()

    return config[id]
end

local function GetReformClientConfigByKey(key) 
    local config = GetReformClientCfgs()
    
    return config[key]
end
--endregion

--region Init
function XReform2ndConfigs.Init()
end

function XReform2ndConfigs.ReleaseStageConfig()
    ReformStageCfgs = nil
end

function XReform2ndConfigs.ReleaseChapterConfig()
    ReformChapterCfgs = nil
end

function XReform2ndConfigs.ReleaseMemberSourceConfig()
    ReformMemberSourceCfgs = nil
end

function XReform2ndConfigs.ReleaseMemberGroupConfig()
    ReformMemberGroupCfgs = nil
end

function XReform2ndConfigs.ReleaseClientConfig()
    ReformClientCfgs = nil
end

function XReform2ndConfigs.GetStageConfig()
    return GetStageCfgs()
end

function XReform2ndConfigs.GetChapterConfig()
    return GetChapterCfgs()
end

function XReform2ndConfigs.GetReformMemberGroupConfig()
    return GetMemberGroupCfgs()
end

function XReform2ndConfigs.GetMemberSourceConfig()
    return GetMemberSourceCfgs()
end

function XReform2ndConfigs.GetReformClientConfig()
    return GetReformClientCfgs()
end
--endregiond

--region 压力值 <-> Star
function XReform2ndConfigs.GetStarMax(isHardMode)
    if isHardMode then
        return 4
    end
    return 3
end

function XReform2ndConfigs.GetStarHardMode()
    return 2
end

local function GetStarArray(stageId)
    return GetReformStageTableConfigById(stageId).StarNeedScore
end

function XReform2ndConfigs.GetStarByPressure(pressure, stageId)
    if not stageId then
        XLog.Error("[XReform2ndConfigs] GetStarByPressure stageId is nil")
        return 0
    end
    local stageArray = GetStarArray(stageId)
    for i = #stageArray, 1, -1 do
        if pressure >= stageArray[i] then
            return i
        end
    end
    return 0
end

function XReform2ndConfigs.GetPressureByStar(star, stageId)
    if not stageId then
        XLog.Error("[XReform2ndConfigs] GetPressureByStar stageId is nil")
        return 0
    end
    if star == 0 then
        return 0
    end
    local stageArray = GetStarArray(stageId)
    return stageArray[star] or 0
end
--endregion

--region ClientTable
function XReform2ndConfigs.GetDisplayTaskIds()
    local config = GetReformClientConfigByKey("TaskRewardDisplay")

    if not config then
        return 
    end 
    
    return config.Values
end
--endregion

--region StageTable
function XReform2ndConfigs.GetStageConfigById(id)
    return GetReformStageTableConfigById(id)
end

function XReform2ndConfigs.GetStageUnlockStageIdById(id)
    local config = GetReformStageTableConfigById(id)

    return config.UnlockStageId
end

function XReform2ndConfigs.GetStageOpenTimeById(id)
    local config = GetReformStageTableConfigById(id)

    return config.OpenTimeId
end

function XReform2ndConfigs.GetStageFullPointById(id)
    local config = GetReformStageTableConfigById(id)

    return config.FullPoint
end

function XReform2ndConfigs.GetStageGoalDescById(id)
    local config = GetReformStageTableConfigById(id)

    return config.StageGoalDesc
end

local function GetStageDifficultyId(stageId)
    return GetReformStageTableConfigById(stageId).StageDiff[1]
end

function XReform2ndConfigs.GetStageName(id)
    return GetReformStageTableConfigById(id).Name
end

function XReform2ndConfigs.GetStageRecommendCharacterIds(id)
    return GetReformStageTableConfigById(id).RecommendCharacterIds
end

function XReform2ndConfigs.IsStageValid(id)
    local config = GetReformStageTableConfigById(id)
    return config and true or false
end

function XReform2ndConfigs.GetStageRecommendCharacterGroupIdById(id)
    local config = GetReformStageTableConfigById(id)

    return config.RecommendCharacterGroupId
end

function XReform2ndConfigs.GetStagePressureEasy(id)
    local config = GetReformStageTableConfigById(id)
    return config.PressureEasy
end

function XReform2ndConfigs.GetStagePressureHard(id)
    local config = GetReformStageTableConfigById(id)
    return config.PressureHard
end
--endregion

--region ChapterTable
function XReform2ndConfigs.GetChapterDescById(id)
    local config = GetReformChapterTableConfigById(id)

    return config.ChapterDesc
end

function XReform2ndConfigs.GetChapterOpenTimeById(id)
    local config = GetReformChapterTableConfigById(id)

    return config.OpenTime
end

function XReform2ndConfigs.GetChapterOrderById(id)
    local config = GetReformChapterTableConfigById(id)

    return config.Order
end

function XReform2ndConfigs.GetChapterEventIDById(id)
    local config = GetReformChapterTableConfigById(id)

    return config.ChapterEventId
end

function XReform2ndConfigs.GetChapterEventDescById(id)
    local config = GetReformChapterTableConfigById(id)

    return config.ChapterEventDesc
end

function XReform2ndConfigs.GetChapterStageIdById(id)
    local config = GetReformChapterTableConfigById(id)

    return config.ChapterStageId
end
--endregion

--region MemberGroupTable
function XReform2ndConfigs.GetMemberGroupSubIdsById(id)
    local config = GetReformMemberGroupConfigById(id)

    return config.SubId
end

function XReform2ndConfigs.GetMemberGroupRecommendDescById(id)
    local config = GetReformMemberGroupConfigById(id)

    return config.Des
end
--endregion

--region MemberSourceTable
function XReform2ndConfigs.GetMemberSourceRobotIdById(id)
    local config = GetReformMemberSourceConfigById(id)

    return config.RobotId
end

function XReform2ndConfigs.GetMemberSourceStarLevelById(id)
    local config = GetReformMemberSourceConfigById(id)

    return config.StarLevel
end

function XReform2ndConfigs.GetMemberSourceAddScoreById(id)
    local config = GetReformMemberSourceConfigById(id)

    return config.AddScore
end

function XReform2ndConfigs.GetMemebrSourceTargetIdsById(id)
    local config = GetReformMemberSourceConfigById(id)

    return config.TargetId
end

function XReform2ndConfigs.GetMemebrSourceFightEventIdsById(id)
    local config = GetReformMemberSourceConfigById

    return config.FightEventId
end
--endregion

--region Stage
---@type XConfig
local _ConfigStageDifficulty
local function GetConfigStageDifficulty()
    if not _ConfigStageDifficulty then
        _ConfigStageDifficulty = XConfig.New("Share/Fuben/Reform/ReformStageDiff.tab", XTable.XTableReformStageDifficulty, "Id")
    end
    return _ConfigStageDifficulty
end

---@type XConfig
local _ConfigMobGroup
local function GetConfigMobGroup()
    if not _ConfigMobGroup then
        _ConfigMobGroup = XConfig.New("Share/Fuben/Reform/ReformEnemyGroup.tab", XTable.XTableReformGroup, "Id")
    end
    return _ConfigMobGroup
end

---@type XConfig
local _ConfigMobSource
local function GetConfigMobSource()
    if not _ConfigMobSource then
        _ConfigMobSource = XConfig.New("Share/Fuben/Reform/ReformEnemySource.tab", XTable.XTableReformEnemySource, "Id")
    end
    return _ConfigMobSource
end

local function GetStageDifficulty(difficultyId)
    return GetConfigStageDifficulty():GetConfig(difficultyId)
end

local function GetStageDifficultyByStage(stageId)
    local difficultyId = GetStageDifficultyId(stageId)
    return GetStageDifficulty(difficultyId)
end

local function GetMobGroup(mobGroupId)
    return GetConfigMobGroup():GetConfig(mobGroupId)
end

local function GetMobSource(mobSourceId)
    return GetConfigMobSource():GetConfig(mobSourceId)
end

---@return XReformMobGroupData[]
function XReform2ndConfigs.GetStageMobGroup(stageId)
    local result = {}

    -- 第x波怪
    local mobGroupIdArray = GetStageDifficultyByStage(stageId).ReformEnemys
    for i = 1, #mobGroupIdArray do
        local mobGroupId = mobGroupIdArray[i]
        local mobGroup = GetMobGroup(mobGroupId).SubId

        -- 第x波怪 第x格
        --local mobGroupArray = {}
        --for j = 1, #mobGroup do
        local mobSourceId = mobGroup[1]
        local mobIdArray = GetMobSource(mobSourceId).TargetId
        --mobGroupArray[j] = mobIdArray
        --end

        ---@class XReformMobGroupData
        local data = {
            MobArray = mobIdArray,
            MobSourceId = mobGroup,
            MobGroupId = mobGroupId,
            MobAmount = #mobGroup
        }

        result[#result + 1] = data
    end

    -- [第X波][可选mob数组]
    return result
end
--endregion

--region buff
---@type XConfig
local _ConfigBuff
local function GetConfigBuff()
    if not _ConfigBuff then
        _ConfigBuff = XConfig.New("Share/Fuben/Reform/ReformBuff.tab", XTable.XTableReformBuff, "Id")
    end
    return _ConfigBuff
end

local function GetBuff(id)
    return GetConfigBuff():GetConfig(id)
end

function XReform2ndConfigs.GetBuffName(id)
    return GetBuff(id).Name
end

function XReform2ndConfigs.GetBuffIcon(id)
    return GetBuff(id).Icon
end

function XReform2ndConfigs.GetBuffDesc(id)
    return GetBuff(id).Desc
end

function XReform2ndConfigs.GetBuffPressure(id)
    return GetBuff(id).SubScore
end
--endregion

--region mob
---@type XConfig
local _ConfigMob
local function GetConfigMob()
    if not _ConfigMob then
        _ConfigMob = XConfig.New("Share/Fuben/Reform/ReformEnemyTarget.tab", XTable.XTableReformEnemyTarget, "Id")
    end
    return _ConfigMob
end

local function GetMob(id)
    return GetConfigMob():GetConfig(id)
end

function XReform2ndConfigs.GetMobName(id)
    return GetMob(id).Name
end

function XReform2ndConfigs.GetMobPressure(id)
    return GetMob(id).AddScore
end

function XReform2ndConfigs.GetMobIcon(id)
    return GetMob(id).HeadIcon
end

function XReform2ndConfigs.GetMobAffixGroupId(id)
    return GetMob(id).AffixGroupId
end

function XReform2ndConfigs.GetMobAffixMaxCount(id)
    return GetMob(id).AffixMaxCount
end

function XReform2ndConfigs.GetMobLevel(id)
    return GetMob(id).ShowLevel
end

function XReform2ndConfigs.GetMobIsHardMode(id)
    local condition = GetMob(id).Condition
    return condition and condition > 0
end
--endregion

--region affix 词缀 buff for mob
---@type XConfig
local _ConfigAffix
local function GetConfigAffix()
    if not _ConfigAffix then
        _ConfigAffix = XConfig.New("Share/Fuben/Reform/ReformAffixSource.tab", XTable.XTableReformAffixSource, "Id")
    end
    return _ConfigAffix
end

local function GetAffix(id)
    return GetConfigAffix():GetConfig(id)
end

function XReform2ndConfigs.GetAffixName(id)
    return GetAffix(id).Name
end

function XReform2ndConfigs.GetAffixIcon(id)
    return GetAffix(id).Icon
end

function XReform2ndConfigs.GetAffixSimpleDesc(id)
    return GetAffix(id).SimpleDes
end

function XReform2ndConfigs.GetAffixDesc(id)
    return GetAffix(id).Des
end

function XReform2ndConfigs.GetAffixIsHardMode(id)
    local condition = GetAffix(id).Condition
    return condition and condition > 0
end

function XReform2ndConfigs.IsAffixValid(id)
    return GetAffix(id) and true or false
end

function XReform2ndConfigs.GetAffixPressure(id)
    return GetAffix(id).AddScore
end
--endregion

--region group
---@type XConfig
local _ConfigAffixGroup
local function GetConfigAffixGroup()
    if not _ConfigAffixGroup then
        _ConfigAffixGroup = XConfig.New("Share/Fuben/Reform/ReformAffixGroup.tab", XTable.XTableReformGroup, "Id")
    end
    return _ConfigAffixGroup
end
local function GetAffixGroup(id)
    return GetConfigAffixGroup():GetConfig(id)
end

function XReform2ndConfigs.GetAffixGroup(id)
    return GetAffixGroup(id).SubId
end
--endregion

--region activity
---@type XConfig
local _ConfigActivity
local function GetConfigActivity()
    if not _ConfigActivity then
        _ConfigActivity = XConfig.New("Share/Fuben/Reform/ReformCfg.tab", XTable.XTableReformCfg, "Id")
    end
    return _ConfigActivity
end

local function GetActivity(id)
    return GetConfigActivity():GetConfig(id)
end

function XReform2ndConfigs.GetActivityHelpKey1(id)
    return GetActivity(id).HelpName
end

function XReform2ndConfigs.GetActivityHelpKey2(id)
    return GetActivity(id).ScoreHelpName
end

function XReform2ndConfigs.GetActivityOpenTimeId(id)
    return GetActivity(id).OpenTimeId
end

function XReform2ndConfigs.GetActivityName(id)
    return GetActivity(id).Name
end

function XReform2ndConfigs.GetActivityBannerIcon(id)
    return GetActivity(id).BannerIcon
end

function XReform2ndConfigs.IsActivityExist(id)
    return GetConfigActivity():TryGetConfig(id) and true or false
end

function XReform2ndConfigs.GetActivityDefaultId(id)
    local configs = GetConfigActivity():GetConfigs()
    for i, config in pairs(configs) do
        return config.Id
    end
    return false
end
--endregion
