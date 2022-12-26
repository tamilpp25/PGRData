local TABLE_FUBEN_BRANCH_ACTIVITY_PATH = "Share/Fuben/FubenBranch/FubenBranchActivity.tab"
local TABLE_FUBEN_BRANCH_CHALLENGE_PATH = "Share/Fuben/FubenBranch/FubenBranchChallenge.tab"
local TABLE_FUBEN_BRANCH_SECTION_PATH = "Share/Fuben/FubenBranch/FubenBranchSection.tab"

local pairs = pairs

local FubenBranchTemplates = {}
local FubenBranchSectionTemplates = {}
local FubenBranchChallengeTemplates = {}

local DefaultActivityId = 0

XFubenActivityBranchConfigs = XFubenActivityBranchConfigs or {}

function XFubenActivityBranchConfigs.Init()
    FubenBranchTemplates = XTableManager.ReadByIntKey(TABLE_FUBEN_BRANCH_ACTIVITY_PATH, XTable.XTableFubenBranchActivity, "Id")
    FubenBranchSectionTemplates = XTableManager.ReadByIntKey(TABLE_FUBEN_BRANCH_SECTION_PATH, XTable.XTableFubenBranchSection, "Id")
    FubenBranchChallengeTemplates = XTableManager.ReadByIntKey(TABLE_FUBEN_BRANCH_CHALLENGE_PATH, XTable.XTableFubenBranchChallenge, "Id")

    for activityId, config in pairs(FubenBranchTemplates) do
        if XTool.IsNumberValid(config.ActivityTimeId) then
            DefaultActivityId = activityId
            break
        end
        DefaultActivityId = activityId--若全部过期，取最后一行配置作为默认下次开启的活动ID
    end
end

function XFubenActivityBranchConfigs.GetSectionCfgs()
    return FubenBranchSectionTemplates
end

function XFubenActivityBranchConfigs.GetChapterCfg(chapterId)
    local chapterCfg = FubenBranchChallengeTemplates[chapterId]
    if not chapterCfg then
        XLog.ErrorTableDataNotFound("XFubenActivityBranchConfigs.GetChapterCfg",
        "FubenBranchChallenge", TABLE_FUBEN_BRANCH_CHALLENGE_PATH, "chapterId", tostring(chapterId))
        return
    end
    return chapterCfg
end

function XFubenActivityBranchConfigs.GetSectionCfg(sectionId)
    local sectionCfg = FubenBranchSectionTemplates[sectionId]
    if not sectionCfg then
        XLog.ErrorTableDataNotFound("XFubenActivityBranchConfigs.GetSectionCfg",
        "FubenBranchSection", TABLE_FUBEN_BRANCH_SECTION_PATH, "sectionId", tostring(sectionId))
        return
    end
    return sectionCfg
end

function XFubenActivityBranchConfigs.GetActivityConfig(activityId)
    local activityCfg = FubenBranchTemplates[activityId]
    if not activityCfg then
        XLog.ErrorTableDataNotFound("XFubenActivityBranchConfigs.GetActivityConfig",
        "FubenBranch", TABLE_FUBEN_BRANCH_ACTIVITY_PATH, "activityId", tostring(activityId))
        return
    end
    return activityCfg
end

function XFubenActivityBranchConfigs.GetDefaultActivityId()
    return DefaultActivityId
end

function XFubenActivityBranchConfigs.GetActivityBeginTime(activityId)
    local config = XFubenActivityBranchConfigs.GetActivityConfig(activityId)
    return XFunctionManager.GetStartTimeByTimeId(config.ActivityTimeId)
end

function XFubenActivityBranchConfigs.GetActivityEndTime(activityId)
    local config = XFubenActivityBranchConfigs.GetActivityConfig(activityId)
    return XFunctionManager.GetEndTimeByTimeId(config.ActivityTimeId)
end

function XFubenActivityBranchConfigs.GetChallengeBeginTime(activityId)
    local config = XFubenActivityBranchConfigs.GetActivityConfig(activityId)
    return XFunctionManager.GetStartTimeByTimeId(config.ChallengeTimeId)
end

function XFubenActivityBranchConfigs.GetFightEndTime(activityId)
    local config = XFubenActivityBranchConfigs.GetActivityConfig(activityId)
    return XFunctionManager.GetEndTimeByTimeId(config.FightTimeId)
end