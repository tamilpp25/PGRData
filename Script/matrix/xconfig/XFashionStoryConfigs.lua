XFashionStoryConfigs = XFashionStoryConfigs or {}

local TABLE_FASHION_STORY = "Share/Fuben/FashionStory/FashionStory.tab"
local TABLE_FASHION_STORY_STAGE = "Share/Fuben/FashionStory/FashionStoryStage.tab"

-- 活动类型
XFashionStoryConfigs.Type = {
    Both = 1,           -- 具有章节关与试玩关
    OnlyChapter = 2,    -- 只有章节关
    OnlyTrial = 3,      -- 只有试玩关
}

-- 玩法模式
XFashionStoryConfigs.Mode = {
    Chapter = 1,    -- 章节关
    Trial = 2,      -- 试玩关
}

XFashionStoryConfigs.StoryEntranceId = 0

local FashionStory = {}
local FashionStoryStage = {}

function XFashionStoryConfigs.Init()
    FashionStory = XTableManager.ReadByIntKey(TABLE_FASHION_STORY, XTable.XTableFashionStory, "Id")
    FashionStoryStage = XTableManager.ReadByIntKey(TABLE_FASHION_STORY_STAGE, XTable.XTableFashionStoryStage, "StageId")
end


--------------------------------------------------内部接口---------------------------------------------------------------

local function GetFashionStoryCfg(id)
    local cfg = FashionStory[id]
    if not cfg then
        XLog.ErrorTableDataNotFound("GetFashionStoryCfg", "系列涂装剧情活动配置",
                TABLE_FASHION_STORY, "Id", tostring(id))
        return {}
    end
    return cfg
end

local function GetFashionStoryStageCfg(stageId)
    local cfg = FashionStoryStage[stageId]
    if not cfg then
        XLog.ErrorTableDataNotFound(" GetFashionStoryStageCfg", "活动关卡配置",
                TABLE_FASHION_STORY_STAGE, "StageId", tostring(stageId))
        return {}
    end
    return cfg
end


----------------------------------------------FashionStory.tab----------------------------------------------------------

function XFashionStoryConfigs.GetAllFashionStoryId()
    local allFashionStoryId = {}
    for id, _ in pairs(FashionStory) do
        table.insert(allFashionStoryId, id)
    end
    return allFashionStoryId
end

function XFashionStoryConfigs.GetName(id)
    local cfg = GetFashionStoryCfg(id)
    return cfg.Name
end

function XFashionStoryConfigs.GetActivityTimeId(id)
    local cfg = GetFashionStoryCfg(id)
    return cfg.TimeId
end

function XFashionStoryConfigs.GetChapterPrefab(id)
    local cfg = GetFashionStoryCfg(id)
    return cfg.ChapterPrefab
end

function XFashionStoryConfigs.GetActivityBannerIcon(id)
    local cfg = GetFashionStoryCfg(id)
    return cfg.ActivityBannerIcon
end

function XFashionStoryConfigs.GetChapterBg(id)
    local cfg = GetFashionStoryCfg(id)
    return cfg.ChapterBg
end

function XFashionStoryConfigs.GetTrialBg(id)
    local cfg = GetFashionStoryCfg(id)
    return cfg.TrialBg
end

function XFashionStoryConfigs.GetSkipIdList(id)
    local cfg = GetFashionStoryCfg(id)
    return cfg.SkipId
end

function XFashionStoryConfigs.GetChapterStagesList(id)
    local cfg = GetFashionStoryCfg(id)
    return cfg.ChapterStages
end

function XFashionStoryConfigs.GetTrialStagesList(id)
    local cfg = GetFashionStoryCfg(id)
    return cfg.TrialStages
end

function XFashionStoryConfigs.GetChapterFightStagePrefab(id)
    local cfg = GetFashionStoryCfg(id)
    return cfg.FightStagePrefab
end

function XFashionStoryConfigs.GetChapterStoryStagePrefab(id)
    local cfg = GetFashionStoryCfg(id)
    return cfg.StoryStagePrefab
end

function XFashionStoryConfigs.GetStoryEntranceBg(id)
    local cfg = GetFashionStoryCfg(id)
    return cfg.StoryEntranceBg
end

function XFashionStoryConfigs.GetStoryEntranceFinishTag(id)
    local cfg = GetFashionStoryCfg(id)
    return cfg.StoryFinishTag
end

function XFashionStoryConfigs.GetStoryTimeId(id)
    local cfg = GetFashionStoryCfg(id)
    return cfg.StoryTimeId
end

function XFashionStoryConfigs.GetAllStageId(id)
    return XTool.MergeArray(XFashionStoryConfigs.GetChapterStagesList(id), XFashionStoryConfigs.GetTrialStagesList(id))
end


----------------------------------------------FashionStoryStage.tab----------------------------------------------------------

function XFashionStoryConfigs.GetStageTimeId(stageId)
    local cfg = GetFashionStoryStageCfg(stageId)
    return cfg.TimeId
end

function XFashionStoryConfigs.GetStoryStageDetailBg(id)
    local cfg = GetFashionStoryStageCfg(id)
    return cfg.StoryStageDetailBg
end

function XFashionStoryConfigs.GetStoryStageDetailIcon(id)
    local cfg = GetFashionStoryStageCfg(id)
    return cfg.StoryStageDetailIcon
end

function XFashionStoryConfigs.GetTrialDetailBg(id)
    local cfg = GetFashionStoryStageCfg(id)
    return cfg.TrialDetailBg
end

function XFashionStoryConfigs.GetTrialDetailSpine(id)
    local cfg = GetFashionStoryStageCfg(id)
    return cfg.TrialDetailSpine
end

function XFashionStoryConfigs.GetTrialDetailHeadIcon(id)
    local cfg = GetFashionStoryStageCfg(id)
    return cfg.TrialDetailHeadIcon
end

function XFashionStoryConfigs.GetTrialDetailRecommendLevel(id)
    local cfg = GetFashionStoryStageCfg(id)
    return cfg.TrialDetailRecommendLevel
end

function XFashionStoryConfigs.GetTrialDetailDesc(id)
    local cfg = GetFashionStoryStageCfg(id)
    return cfg.TrialDetailDesc
end

function XFashionStoryConfigs.GetTrialFinishTag(id)
    local cfg = GetFashionStoryStageCfg(id)
    return cfg.FinishTag
end
