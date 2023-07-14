XLivWarmSoundsActivityConfig = XLivWarmSoundsActivityConfig or {}

local TABLE_ACT_CONFIG_PATH = "Client/MiniActivity/LivWarmSoundsActivity/LivWarmSoundsActivityLocal.tab"
local TABLE_SOUND_CONFIG_PATH = "Client/MiniActivity/LivWarmSoundsActivity/LivWarmSoundsActivitySoundLocal.tab"
local TABLE_STAGE_CONFIG_PATH = "Client/MiniActivity/LivWarmSoundsActivity/LivWarmSoundsActivityStageLocal.tab"
local SHARE_TABLE_ACT_CONFIG_PATH = "Share/MiniActivity/LivWarmSoundsActivity/LivWarmSoundsActivityConfig.tab"
local SHARE_STAGE_CONFIG_PATH = "Share/MiniActivity/LivWarmSoundsActivity/LivWarmSoundsActivityStage.tab"

local SoundsActivityTemplates = {}
local SoundTemplates = {}
local StageTemplates = {}
local ShareSoundsActivityTemplates = {}
local ShareStageTemplates = {}

function XLivWarmSoundsActivityConfig:Init()
    SoundsActivityTemplates = XTableManager.ReadByIntKey(TABLE_ACT_CONFIG_PATH, XTable.XTableLivWarmSoundsActivityLocal, "Id")
    SoundTemplates = XTableManager.ReadByIntKey(TABLE_SOUND_CONFIG_PATH, XTable.LivWarmSoundsActivitySoundLocal, "SoundId")
    StageTemplates = XTableManager.ReadByIntKey(TABLE_STAGE_CONFIG_PATH, XTable.LivWarmSoundsActivityStageLocal, "Id")
    ShareSoundsActivityTemplates = XTableManager.ReadByIntKey(SHARE_TABLE_ACT_CONFIG_PATH, XTable.XTableLivWarmSoundsActivityCfg, "Id")
    ShareStageTemplates = XTableManager.ReadByIntKey(SHARE_STAGE_CONFIG_PATH, XTable.XTableLivWarmSoundsActivityStage, "Id")
end

--这里这里用于传出完整配置条目，外部谨允许局部域生命周期内使用，不允许持有！！！！
local GetSoundsActivityById =  function(id)
    if not SoundsActivityTemplates[id] then
        XLog.Error("没有找到相关配置，请检查配置表：>>>>", TABLE_ACT_CONFIG_PATH)
        return {}
    end
    return SoundsActivityTemplates[id]
end

local GetSoundConfigById = function(id)
    if not SoundTemplates[id] then
        XLog.Error("没有找到相关配置，请检查配置表：>>>>", TABLE_SOUND_CONFIG_PATH)
        return {}
    end
    return SoundTemplates[id]
end

local GetStageConfigById = function(id)
    if not StageTemplates[id] then
        XLog.Error("没有找到相关配置，请检查配置表：>>>>", TABLE_STAGE_CONFIG_PATH)
        return {}
    end
    return StageTemplates[id]
end

local GetShareSoundsActivityById = function(id)
    if not ShareSoundsActivityTemplates[id] then
        XLog.Error("没有找到相关配置，请检查配置表：>>>>", SHARE_TABLE_ACT_CONFIG_PATH)
        return {}
    end
    return ShareSoundsActivityTemplates[id]
end

local GetShareStageConfigById = function(id)
    if not ShareStageTemplates[id] then
        XLog.Error("没有找到相关配置，请检查配置表：>>>>", SHARE_STAGE_CONFIG_PATH)
        return {}
    end
    return ShareStageTemplates[id]
end

---act 表相关--------------
function XLivWarmSoundsActivityConfig.GetActivityName(id)
    local cfg = GetSoundsActivityById(id)
    return cfg.Name or ""
end

function XLivWarmSoundsActivityConfig.GetActivityTimeId(id)
    local cfg = GetShareSoundsActivityById(id)
    return cfg.TimeId or 0
end

function XLivWarmSoundsActivityConfig.GetActivityHelpId(id)
    local cfg = GetSoundsActivityById(id)
    return cfg.HelpId or 0
end

function XLivWarmSoundsActivityConfig.GetActivityClearBgImg(id)
    local cfg = GetSoundsActivityById(id)
    return cfg.ClearBgImg or ""
end

function XLivWarmSoundsActivityConfig.GetDefaultActivityId()
    local defaultActivityId = 0
    for activityId, config in ipairs(ShareSoundsActivityTemplates) do
        defaultActivityId = activityId
        if XTool.IsNumberValid(config.TimeId) and XFunctionManager.CheckInTimeByTimeId(config.TimeId) then
            break
        end
    end
    return defaultActivityId
end

function XLivWarmSoundsActivityConfig.GetActivityStartTime(activityId)
    return XFunctionManager.GetStartTimeByTimeId(XLivWarmSoundsActivityConfig.GetActTimeId(activityId))
end

function XLivWarmSoundsActivityConfig.GetActivityEndTime(activityId)
    return XFunctionManager.GetEndTimeByTimeId(XLivWarmSoundsActivityConfig.GetActTimeId(activityId))
end
--------------act end -----------------

------------sound start----------------
function XLivWarmSoundsActivityConfig.GetSoundRankNumber(id)
    local cfg = GetSoundConfigById(id)
    return cfg.RankNumber or 0
end


function XLivWarmSoundsActivityConfig.GetSoundUrl(id)
    local cfg = GetSoundConfigById(id)
    return cfg.SoundUrl or ""
end

function XLivWarmSoundsActivityConfig.GetSoundCueId(id)
    local cfg = GetSoundConfigById(id)
    return cfg.CueId or 0
end

function XLivWarmSoundsActivityConfig.GetSoundAttachedImgUrl(id)
    local cfg = GetSoundConfigById(id)
    return cfg.AttachedImgUrl or ""
end

function XLivWarmSoundsActivityConfig.GetSoundReflectedImgUrl(id)
    local cfg = GetSoundConfigById(id)
    return cfg.ReflectedImgUrl or ""
end

function XLivWarmSoundsActivityConfig.GetSoundWords(id) --海外新增接口:获取每个片段要显示的文字
    local cfg = GetSoundConfigById(id)
    return cfg.Words or ""
end
-------------sound end ------------

--------stage start------------------
function XLivWarmSoundsActivityConfig.GetStageActivityId(id)
    local cfg = GetStageConfigById(id)
    return cfg.ActivityId or 0
end

function XLivWarmSoundsActivityConfig.GetStageStageName(id)
    local cfg = GetStageConfigById(id)
    return cfg.StageName or ""
end

function XLivWarmSoundsActivityConfig.GetStageCondition(id)
    local cfg = GetShareStageConfigById(id)
    return cfg.Condition or 0
end

function XLivWarmSoundsActivityConfig.GetStageBroadTestTime(id)
    local cfg = GetStageConfigById(id)
    return cfg.BroadTestTime or 0
end

function XLivWarmSoundsActivityConfig.GetStageFinishImg(id)
    local cfg = GetStageConfigById(id)
    return cfg.FinishImg or ""
end

function XLivWarmSoundsActivityConfig.GetStageFinishText(id)
    local cfg = GetStageConfigById(id)
    return cfg.FinishText or ""
end

function XLivWarmSoundsActivityConfig.GetStageFinishUrl(id)
    local cfg = GetStageConfigById(id)
    return cfg.FinishUrl or ""
end

function XLivWarmSoundsActivityConfig.GetStageInitialSoundId(id)
    local cfg = GetStageConfigById(id)
    return cfg.InitialSoundId or 0
end

function XLivWarmSoundsActivityConfig.GetStageFinishSoundId(id)
    local cfg = GetShareStageConfigById(id)
    return cfg.FinishSoundId or 0
end

function XLivWarmSoundsActivityConfig.GetStageHint(id)
    local cfg = GetStageConfigById(id)
    return cfg.Hint or {}
end

function XLivWarmSoundsActivityConfig.GetStagePreStageId(id)
    local cfg = GetStageConfigById(id)
    return cfg.PreStageId or 0
end

function XLivWarmSoundsActivityConfig.GetStagesByActivityId(id)
    local stageIds = {}
    for i, v in pairs(StageTemplates) do
        if id == v.ActivityId then
          table.insert(stageIds,v.Id)
        end
    end
    table.sort(stageIds)
    return stageIds
end

------stage end------

