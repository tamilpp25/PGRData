XFashionStoryConfigs = XFashionStoryConfigs or {}

local TABLE_FASHION_STORY = "Share/Fuben/FashionStory/FashionStory.tab"
local TABLE_FASHION_STORY_STAGE = "Share/Fuben/FashionStory/FashionStoryStage.tab"
local TABLE_SINGLE_LINE="Share/Fuben/FashionStory/FashionStorySingleLine.tab"
-- 活动类型
XFashionStoryConfigs.Type = {
    Both = 1,           -- 具有章节关与试玩关
    OnlyChapter = 2,    -- 只有章节关
    OnlyTrial = 3,      -- 只有试玩关
}

-- 界面类型
XFashionStoryConfigs.PrefabType={
    Old=1, --旧玩法界面
    Group=2, --新玩法界面
}

-- 玩法模式
XFashionStoryConfigs.Mode = {
    Chapter = 1,    -- 章节关
    Trial = 2,      -- 试玩关
}

--跳转功能
XFashionStoryConfigs.FashionStorySkip={
    SkipToStore=1   --跳转到外部商店
}

--关卡未解锁原因
XFashionStoryConfigs.TrialStageUnOpenReason={
    OutOfTime=0, --不在开放时间
    PreStageUnPass=1, --前置关卡未通关
}

--关卡组（章节）未解锁原因
XFashionStoryConfigs.GroupUnOpenReason={
    OutOfTime=0, --不在开放时间
    PreGroupUnPass=1, --前置章节未通关
}

XFashionStoryConfigs.StoryEntranceId = 0

--一组关卡最大数量（该参数受当期设定影响）
XFashionStoryConfigs.StageCountInGroupUpperLimit=2

local FashionStory = {}
local FashionStoryStage = {}
local SingleLine={}

function XFashionStoryConfigs.Init()
    FashionStory = XTableManager.ReadByIntKey(TABLE_FASHION_STORY, XTable.XTableFashionStory, "Id")
    FashionStoryStage = XTableManager.ReadByIntKey(TABLE_FASHION_STORY_STAGE, XTable.XTableFashionStoryStage, "StageId")
    SingleLine = XTableManager.ReadByIntKey(TABLE_SINGLE_LINE, XTable.XTableFashionStorySingleLine, "Id")

end

function XFashionStoryConfigs.GetGroupNewFullKey(singleLineId)
    local fullKey="FashionStoryGroupNew"..tostring(singleLineId)..tostring(XDataCenter.FashionStoryManager.GetCurrentActivityId())..XPlayer.Id
    return fullKey
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

local function GetSingleLineCfg(id)
    local cfg = SingleLine[id]
    if not cfg then
        XLog.ErrorTableDataNotFound("GetSingleLineCfg", "系列涂装剧情活动组配置",
                TABLE_SINGLE_LINE, "Id", tostring(id))
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


function XFashionStoryConfigs.GetActivityTimeId(id)
    local cfg = GetFashionStoryCfg(id)
    return cfg.TimeId
end


function XFashionStoryConfigs.GetTrialBg(id)
    local cfg = GetFashionStoryCfg(id)
    return cfg.TrialBg
end

function XFashionStoryConfigs.GetSkipIdList(id)
    local cfg = GetFashionStoryCfg(id)
    return cfg.SkipId
end

function XFashionStoryConfigs.GetTrialStagesList(id)
    local cfg = GetFashionStoryCfg(id)
    return cfg.TrialStages
end

function XFashionStoryConfigs.GetPrefabType(id)
    local cfg=GetFashionStoryCfg(id)
    return cfg.PrefabType
end

function XFashionStoryConfigs.GetSingleLines(id)
    local cfg=GetFashionStoryCfg(id)
    local avaliableSingleLineIds={}
    for i, singlelineid in ipairs(cfg.SingleLines) do
        if singlelineid then
            table.insert(avaliableSingleLineIds,singlelineid)
        end
    end
    return avaliableSingleLineIds
end

--获取singleline表中读取到的首个有效singlelineId：用于兼容旧玩法
function XFashionStoryConfigs.GetFirstSingleLine(id)
    local cfg=GetFashionStoryCfg(id)
    for i, singleLineId in ipairs(cfg.SingleLines) do
        if singleLineId then
            return singleLineId
        end
    end
end

function XFashionStoryConfigs.GetTaskLimitId(id)
    local cfg=GetFashionStoryCfg(id)
    return cfg.TaskLimitId
end

function XFashionStoryConfigs.GetFashionStorySkipId(id)
    local cfg=GetFashionStoryCfg(id)
    return cfg.SkipId[id]
end

function XFashionStoryConfigs.GetFashionStoryTrialStages(id)
    local cfg=GetFashionStoryCfg(id)
    local avaliableStages={}
    for i, stage in ipairs(cfg.TrialStages) do
        if stage then
            table.insert(avaliableStages,stage)
        end
    end
    return avaliableStages
end

function XFashionStoryConfigs.GetFashionStoryTrialStageCount(id)
    local stages=GetFashionStoryCfg(id).TrialStages
    local count=0
    for i, stage in ipairs(stages) do
        if stage then
            count=count+1
        end
    end
    return count
end

function XFashionStoryConfigs.GetAllStoryStages(id)
    local allStages={}
    if XFashionStoryConfigs.GetPrefabType(id)==XFashionStoryConfigs.PrefabType.Group then
        local singleLineIds=XFashionStoryConfigs.GetSingleLines(id)
        for i, singleLineId in ipairs(singleLineIds) do
            local stages=XFashionStoryConfigs.GetSingleLineStages(singleLineId)
            allStages=XTool.MergeArray(allStages,stages)
        end
    elseif XFashionStoryConfigs.GetPrefabType(id)==XFashionStoryConfigs.PrefabType.Old then
        local singleLineId=XFashionStoryConfigs.GetFirstSingleLine(id)
        if singleLineId then
            local stages=XFashionStoryConfigs.GetSingleLineStages(singleLineId)
            allStages=XTool.MergeArray(allStages,stages)
        end
    end
    
    return allStages
end

function XFashionStoryConfigs.GetAllStageId(id)
    return XTool.MergeArray(XFashionStoryConfigs.GetAllStoryStages(id),XFashionStoryConfigs.GetTrialStagesList(id))
end
----------------------------------------------SingleLine.tab----------------------------------------------------------
function XFashionStoryConfigs.GetSingleLineName(id)
    local cfg=GetSingleLineCfg(id)
    return cfg.Name
end

function XFashionStoryConfigs.GetSingleLineFirstStage(id)
    local cfg=GetSingleLineCfg(id)
    if cfg.ChapterStages then
        return cfg.ChapterStages[1]
    end
end

function XFashionStoryConfigs.GetSingleLineStages(id)
    local cfg=GetSingleLineCfg(id)
    local avaliableStages={}
    local count=0
    for i, stage in ipairs(cfg.ChapterStages) do
        if count>XFashionStoryConfigs.StageCountInGroupUpperLimit then break end
        
        if stage then
            table.insert(avaliableStages,stage)
            count=count+1
        end
    end
    return avaliableStages
end

function XFashionStoryConfigs.GetSingleLineStagesCount(id)
    local stages=GetSingleLineCfg(id).ChapterStages
    local count=0
    for i, stage in ipairs(stages) do
        if stage then
            count=count+1
        end
    end
    return count>XFashionStoryConfigs.StageCountInGroupUpperLimit and XFashionStoryConfigs.StageCountInGroupUpperLimit or count
end

function XFashionStoryConfigs.GetSingleLineTimeId(id)
    local cfg=GetSingleLineCfg(id)
    return cfg.StoryTimeId
end

function XFashionStoryConfigs.GetChapterPrefab(id)
    local cfg=GetSingleLineCfg(id)
    return cfg.ChapterPrefab
end

function XFashionStoryConfigs.GetChapterStoryStagePrefab(id)
    local cfg=GetSingleLineCfg(id)
    return cfg.StoryStagePrefab
end

function XFashionStoryConfigs.GetChapterFightStagePrefab(id)
    local cfg=GetSingleLineCfg(id)
    return cfg.FightStagePrefab
end

function XFashionStoryConfigs.GetStoryEntranceBg(id)
    local cfg=GetSingleLineCfg(id)
    return cfg.StoryEntranceBg
end

function XFashionStoryConfigs.GetStoryEntranceFinishTag(id)
    local cfg=GetSingleLineCfg(id)
    return cfg.StoryFinishTag
end

function XFashionStoryConfigs.GetSingleLineAsGroupStoryIcon(id)
    local cfg=GetSingleLineCfg(id)
    return cfg.AsGroupStoryIcon
end

function XFashionStoryConfigs.GetSingleLineSummerFashionTitleImg(id)
    local cfg=GetSingleLineCfg(id)
    return cfg.SummerFashionTitleImg
end

function XFashionStoryConfigs.GetSingleLineChapterBg(id)
    local cfg=GetSingleLineCfg(id)
    return cfg.ChapterBg
end
----------------------------------------------FashionStoryStage.tab----------------------------------------------------------

function XFashionStoryConfigs.GetStageTimeId(stageId)
    local cfg = GetFashionStoryStageCfg(stageId)
    return cfg.TimeId
end

function XFashionStoryConfigs.GetPreStageId(stageId)
    local cfg=GetFashionStoryStageCfg(stageId)
    return cfg.PreStageId
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

function XFashionStoryConfigs.GetStoryStageFace(id)
    local cfg = GetFashionStoryStageCfg(id)
    return cfg.StoryStageFace
end

function XFashionStoryConfigs.GetTrialFace(id)
    local cfg = GetFashionStoryStageCfg(id)
    return cfg.TrialFace
end

function XFashionStoryConfigs.GetTrialLockIcon(id)
    local cfg = GetFashionStoryStageCfg(id)
    return cfg.TrialLockIcon
end
