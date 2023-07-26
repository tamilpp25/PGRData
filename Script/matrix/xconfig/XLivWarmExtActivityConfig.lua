XLivWarmExtActivityConfig = XLivWarmExtActivityConfig or {}

local LIV_WARM_EXT_ACTIVITY_PATH = "Share/MiniActivity/LivWarmActivity/LivWarmExtActivity.tab"
local LIV_WARM_EXT_PATH = "Client/MiniActivity/LivWarmActivity/LivWarmExtImg.tab"
local LIV_WARM_EXT_TIMELINE_PATH = "Client/MiniActivity/LivWarmActivity/LivWarmExtTimeline.tab"

local LivWarmExtTemplates = {}
local LivWarmExtImgTemplates = {}
local LivWarmExtTimelineTemplates = {}

function XLivWarmExtActivityConfig:Init()
    LivWarmExtTemplates = XTableManager.ReadByIntKey(LIV_WARM_EXT_ACTIVITY_PATH, XTable.XTableLivWarmExtActivity, "Id")
    LivWarmExtImgTemplates = XTableManager.ReadByIntKey(LIV_WARM_EXT_PATH, XTable.XTableLivWarmExtImg, "Id")
    LivWarmExtTimelineTemplates = XTableManager.ReadByIntKey(LIV_WARM_EXT_TIMELINE_PATH, XTable.XTableLivWarmExtTimeline, "Id")
end

--这里这里用于传出完整配置条目，外部谨允许局部域生命周期内使用，不允许持有！！！！
local GetLivWarmExtTemplatesById =  function(id)
    if not LivWarmExtTemplates[id] then
        XLog.Error(string.format("没有找到相关配置，请检查配置表%s：>>>>>>>>Id:%s", LIV_WARM_EXT_ACTIVITY_PATH,id))
        return {}
    end
    return LivWarmExtTemplates[id]
end

local GetLivWarmExtImgTemplatesById = function(id)
    if not LivWarmExtImgTemplates[id] then
        XLog.Error(string.format("没有找到相关配置，请检查配置表%s：>>>>Id:%s", LIV_WARM_EXT_PATH,id))
        return {}
    end
    return LivWarmExtImgTemplates[id]
end

local GetLivWarmExtTimelineTemplatesById = function(id)
    if not LivWarmExtTimelineTemplates[id] then
        XLog.Error(string.format("没有找到相关配置，请检查配置表%s：>>>>Id:%s", LIV_WARM_EXT_TIMELINE_PATH,id))
        return {}
    end
    return LivWarmExtTimelineTemplates[id]
end


---act 表相关--------------

function XLivWarmExtActivityConfig.GetActivityTimeId(id)
    local cfg = GetLivWarmExtTemplatesById(id)
    return cfg.TimeId or 0
end

function XLivWarmExtActivityConfig.GetActivityName(id)
    local cfg = GetLivWarmExtTemplatesById(id)
    return cfg.Name or ""
end

function XLivWarmExtActivityConfig.GetDefaultActivityId()
    local defaultActivityId = 0
    for activityId, config in ipairs(LivWarmExtTemplates) do
        defaultActivityId = activityId
        if XTool.IsNumberValid(config.TimeId) and XFunctionManager.CheckInTimeByTimeId(config.TimeId) then
            break
        end
    end
    return defaultActivityId
end

function XLivWarmExtActivityConfig.GetActivityStartTime(activityId)
    return XFunctionManager.GetStartTimeByTimeId(XLivWarmExtActivityConfig.GetActivityTimeId(activityId))
end

function XLivWarmExtActivityConfig.GetActivityEndTime(activityId)
    return XFunctionManager.GetEndTimeByTimeId(XLivWarmExtActivityConfig.GetActivityTimeId(activityId))
end
--------------act end -----------------

------------img start----------------
function XLivWarmExtActivityConfig.GetLivWarmExtImgCondition(id)
    local cfg = GetLivWarmExtImgTemplatesById(id)
    return cfg.Condition or 0
end

function XLivWarmExtActivityConfig.GetLivWarmExtImgTimeId(id)
    local cfg = GetLivWarmExtImgTemplatesById(id)
    return cfg.TimeId or 0
end

function XLivWarmExtActivityConfig.GetLivWarmExtImgImgUrl(id)
    local cfg = GetLivWarmExtImgTemplatesById(id)
    return cfg.ImgUrl or ""
end

function XLivWarmExtActivityConfig.GetSuitAbleImgUrl()
    local defaultId = 1
    for id, v in ipairs(LivWarmExtImgTemplates) do
        local isPass = not XTool.IsNumberValid(v.Condition) or XConditionManager.CheckCondition(v.Condition)
        if isPass then
             local isOpen = XFunctionManager.CheckInTimeByTimeId(v.TimeId)
            if isOpen then
                if defaultId < id then
                    defaultId = id
                end
            end
        end
    end
    return XLivWarmExtActivityConfig.GetLivWarmExtImgImgUrl(defaultId)
end
------img end----------------
---TimeLine start------
function XLivWarmExtActivityConfig.GetLivWarmExtTimelineTimeId(id)
    local cfg = GetLivWarmExtTimelineTemplatesById(id)
    return cfg.TimeId or 0
end

function XLivWarmExtActivityConfig.GetLivWarmExtTimelineLockedIcon(id)
    local cfg = GetLivWarmExtTimelineTemplatesById(id)
    return cfg.LockedIcon or ""
end

function XLivWarmExtActivityConfig.GetLivWarmExtTimelineUnlockIcon(id)
    local cfg = GetLivWarmExtTimelineTemplatesById(id)
    return cfg.UnlockIcon or ""
end

function XLivWarmExtActivityConfig.GetLivWarmExtTimelineName(id)
    local cfg = GetLivWarmExtTimelineTemplatesById(id)
    return cfg.Name or ""
end

function XLivWarmExtActivityConfig.GetLivWarmExtTimelineUrl(id)
    local cfg = GetLivWarmExtTimelineTemplatesById(id)
    return cfg.Url or ""
end

function XLivWarmExtActivityConfig.GetLivWarmExtTimelineLength()
    local cfg = LivWarmExtTimelineTemplates
    return #cfg or 0
end
-------------TimeLine end ------------

