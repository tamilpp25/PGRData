local ipairs = ipairs
local pairs = pairs
local tableInsert = table.insert

XFubenShortStoryChapterConfigs = {}

local TABLE_SHORT_STORY_ACTIVITY = "Share/Fuben/ShortStory/ShortStoryActivity.tab"
local TABLE_SHORT_STORY_CHAPTER = "Share/Fuben/ShortStory/ShortStoryChapter.tab"
local TABLE_SHORT_STORY_CHAPTER_DETAILS = "Share/Fuben/ShortStory/ShortStoryDetails.tab"
local TABLE_SHORT_STORY_CHAPTER_STAR_TREASURE = "Share/Fuben/ShortStory/ShortStoryStarTreasure.tab"
local TABLE_SHORT_STORY_EXPLORE_GROUP = "Client/Fuben/ShortStory/ShortStoryExploreGroup.tab"
local TABLE_SHORT_STORY_NEXT_CHAPTER = "Client/Fuben/ShortStory/ShortStoryNextChapter.tab"

local ShortStoryActivityCfg = {}
local ShortStoryChapterCfg = {}
local ShortStoryChapterDetailsCfg = {}
local ShortStoryChapterStarTreasureCfg = {}
local ShortStoryExploreGroupCfg = {}
local ShortStoryNextChapterCfg = {}

local function GetShortStoryActivity(id)
    local config = ShortStoryActivityCfg[id]
    if not config then
        XLog.Error("XFubenShortStoryChapterConfigs GetShortStoryActivity error:配置不存在, id:" ..
                id .. ",path: " .. TABLE_SHORT_STORY_ACTIVITY)
        return
    end
    return config
end

local function GetShortStoryChapter(id)
    local config = ShortStoryChapterCfg[id]
    if not config then
        XLog.Error("XFubenShortStoryChapterConfigs GetShortStoryChapter error:配置不存在, id:" ..
                id .. ",path: " .. TABLE_SHORT_STORY_CHAPTER)
        return
    end
    return config
end

local function GetChapterDetails(chapterId)
    local config = ShortStoryChapterDetailsCfg[chapterId]
    if not config then
        XLog.Error("XFubenShortStoryChapterConfigs GetChapterDetails error:配置不存在, chapterId:" ..
                chapterId .. ",path: " .. TABLE_SHORT_STORY_CHAPTER_DETAILS)
        return
    end
    return config
end

local function GetStarTreasure(treasureId)
    local config = ShortStoryChapterStarTreasureCfg[treasureId]
    if not config then
        XLog.Error("XFubenShortStoryChapterConfigs GetStarTreasure error:配置不存在, treasureId:" ..
                treasureId .. ",path: " .. TABLE_SHORT_STORY_CHAPTER_STAR_TREASURE)
        return
    end
    return config
end

local function GetExploreGroups(groupId)
    local exploreGroups = {}
    for _, exploreGroup in pairs(ShortStoryExploreGroupCfg) do
        if exploreGroup.GroupId == groupId then
            tableInsert(exploreGroups,exploreGroup)
        end
    end
    return exploreGroups
end

function XFubenShortStoryChapterConfigs.Init()
    ShortStoryActivityCfg = XTableManager.ReadByIntKey(TABLE_SHORT_STORY_ACTIVITY, XTable.XTableShortStoryActivity, "Id")
    ShortStoryChapterCfg = XTableManager.ReadByIntKey(TABLE_SHORT_STORY_CHAPTER,XTable.XTableShortStory,"Id")
    ShortStoryChapterDetailsCfg = XTableManager.ReadByIntKey(TABLE_SHORT_STORY_CHAPTER_DETAILS,XTable.XTableShortStoryDetails,"ChapterId")
    ShortStoryChapterStarTreasureCfg = XTableManager.ReadByIntKey(TABLE_SHORT_STORY_CHAPTER_STAR_TREASURE,XTable.XTableShortStoryStarTreasure,"TreasureId")
    ShortStoryExploreGroupCfg = XTableManager.ReadByIntKey(TABLE_SHORT_STORY_EXPLORE_GROUP,XTable.XTableShortStoryExploreGroup,"Id")
    ShortStoryNextChapterCfg = XTableManager.ReadByIntKey(TABLE_SHORT_STORY_NEXT_CHAPTER,XTable.XTableShortStoryNextChapter,"ChapterId")
end

function XFubenShortStoryChapterConfigs.UpdateChapterData()
    for _,chapter in pairs(ShortStoryChapterCfg) do
        for difficult,chapterId in pairs(chapter.ChapterId) do
            local chapterDetail = GetChapterDetails(chapterId)
            for k, v in ipairs(chapterDetail.StageId) do
                local stageInfo = XDataCenter.FubenManager.GetStageInfo(v)
                stageInfo.Type = XDataCenter.FubenManager.StageType.ShortStory
                stageInfo.OrderId = k
                stageInfo.ChapterId = chapterDetail.ChapterId
                stageInfo.Difficult = difficult
            end
        end
    end
end

------------------------------------------ShortStoryActivity.tab Start--------------------------------------------------
function XFubenShortStoryChapterConfigs.GetShortStoryActivity(id)
    local config = GetShortStoryActivity(id)
    return config
end
------------------------------------------ShortStoryActivity.tab End----------------------------------------------------
------------------------------------------ShortStoryChapter.tab Start---------------------------------------------------
function XFubenShortStoryChapterConfigs.GetShortStoryChapterIds(id)
    local chapterIds = {}
    local config = GetShortStoryChapter(id)
    for _, chapterId in pairs(config.ChapterId) do
        if XTool.IsNumberValid(chapterId) then
            tableInsert(chapterIds, chapterId)
        end
    end
    return chapterIds
end

function XFubenShortStoryChapterConfigs.GetChapterMainIdByChapterId(chapterId)
    for _,chapter in pairs(ShortStoryChapterCfg) do
        for _,id in pairs(chapter.ChapterId) do
            if id == chapterId then
                return chapter.Id
            end
        end
    end
    return nil
end

function XFubenShortStoryChapterConfigs.GetChapterIdsByDifficult(difficult)
    local chapterIds = {}
    for _,chapter in pairs(ShortStoryChapterCfg) do
        local chapterId = chapter.ChapterId[difficult]
        if XTool.IsNumberValid(chapterId) then
            chapterIds[chapter.OrderId] = chapterId
        end
    end
    return chapterIds
end

function XFubenShortStoryChapterConfigs.GetChapterIdByDifficultAndOrderId(difficult, orderId)
    for _,chapter in pairs(ShortStoryChapterCfg) do
        if chapter.OrderId == orderId then
            local chapterId = chapter.ChapterId[difficult]
            return chapterId
        end
    end
    return nil
end

function XFubenShortStoryChapterConfigs.GetChapterIdByIdAndDifficult(id, difficult)
    local config = GetShortStoryChapter(id) 
    return config.ChapterId[difficult]
end

function XFubenShortStoryChapterConfigs.GetChapterNameById(id)
    local config = GetShortStoryChapter(id)
    return config.ChapterName
end

function XFubenShortStoryChapterConfigs.GetChapterEnById(id)
    local config = GetShortStoryChapter(id)
    return config.ChapterEn
end

function XFubenShortStoryChapterConfigs.GetIconById(id)
    local config = GetShortStoryChapter(id)
    return config.Icon
end

function XFubenShortStoryChapterConfigs.GetZhouMuId(id)
    local config = GetShortStoryChapter(id)
    return config.ZhouMuId
end

function XFubenShortStoryChapterConfigs.GetChapterTextColorList(id)
    local config = GetShortStoryChapter(id)
    return config.ChapterTextColor
end
------------------------------------------ShortStoryChapter.tab End-----------------------------------------------------
------------------------------------------ShortStoryDetails.tab Start---------------------------------------------------
function XFubenShortStoryChapterConfigs.GetChapterIdsByChapterDetails()
    local chapterIds = {}
    for _,chapterDetail in pairs(ShortStoryChapterDetailsCfg) do
        if XTool.IsNumberValid(chapterDetail.ChapterId) then
            tableInsert(chapterIds,chapterDetail.ChapterId)
        end
    end
    return chapterIds
end

function XFubenShortStoryChapterConfigs.GetChapterOrderIdByStageId(stageId)
    local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
    local config = GetChapterDetails(stageInfo.ChapterId)
    return config.OrderId
end

function XFubenShortStoryChapterConfigs.GetChapterOrderIdByChapterId(chapterId)
    local config = GetChapterDetails(chapterId)
    return config.OrderId
end

function XFubenShortStoryChapterConfigs.GetStageTitleByChapterId(chapterId)
    local config = GetChapterDetails(chapterId)
    return config.StageTitle
end

function XFubenShortStoryChapterConfigs.GetStageIdByChapterId(chapterId)
    local config = GetChapterDetails(chapterId)
    return config.StageId
end

function XFubenShortStoryChapterConfigs.GetDatumLinePrecentByChapterId(chapterId)
    local config = GetChapterDetails(chapterId)
    return config.DatumLinePrecent or 0
end

function XFubenShortStoryChapterConfigs.GetMoveStageIndexByChapterId(chapterId)
    local config = GetChapterDetails(chapterId)
    return config.MoveStageIndex or 0
end

function XFubenShortStoryChapterConfigs.GetTreasureIdByChapterId(chapterId)
    local config = GetChapterDetails(chapterId)
    return config.TreasureId
end

function XFubenShortStoryChapterConfigs.GetDifficultByChapterId(chapterId)
    local config = GetChapterDetails(chapterId)
    return config.Difficult
end

function XFubenShortStoryChapterConfigs.GetActivityConditionByChapterId(chapterId)
    local config = GetChapterDetails(chapterId)
    return config.ActivityCondition
end

function XFubenShortStoryChapterConfigs.GetOpenConditionByChapterId(chapterId)
    local config = GetChapterDetails(chapterId)
    return config.OpenCondition
end

function XFubenShortStoryChapterConfigs.GetExploreGroupIdByChapterId(chapterId)
    local config = GetChapterDetails(chapterId)
    return config.ExploreGroupId
end

function XFubenShortStoryChapterConfigs.CheckChapterTypeIsExplore(chapterId)
    local config = GetChapterDetails(chapterId)
    return config.ExploreGroupId and config.ExploreGroupId > 0
end

function XFubenShortStoryChapterConfigs.GetPrefabNameByChapterId(chapterId)
    local config = GetChapterDetails(chapterId)
    return config.PrefabName
end

function XFubenShortStoryChapterConfigs.GetChapterEnByChapterId(chapterId)
    local config = GetChapterDetails(chapterId)
    return config.ChapterEn
end

function XFubenShortStoryChapterConfigs.CheckChapterDetailsByChapterId(chapterId)
    local config = GetChapterDetails(chapterId)
    if config then
        return true
    end
    return false
end
------------------------------------------ShortStoryDetails.tab End-----------------------------------------------------
------------------------------------------ShortStoryStarTreasure.tab Start----------------------------------------------
function XFubenShortStoryChapterConfigs.GetRequireStarByTreasureId(treasureId)
    local config = GetStarTreasure(treasureId)
    return config.RequireStar
end

function XFubenShortStoryChapterConfigs.GetRewardIdByTreasureId(treasureId)
    local config = GetStarTreasure(treasureId)
    return config.RewardId
end
------------------------------------------ShortStoryStarTreasure.tab End------------------------------------------------
------------------------------------------ShortStoryExploreGroup.tab Start----------------------------------------------
function XFubenShortStoryChapterConfigs.GetExploreGroupInfoByGroupId(groupId)
    local exploreGroups = GetExploreGroups(groupId)
    local preShowIndexs = {}
    for _, group in pairs(exploreGroups) do
        preShowIndexs[group.StageIndex] = group.PreShowIndex
    end
    return preShowIndexs
end
------------------------------------------ShortStoryExploreGroup.tab End------------------------------------------------

function XFubenShortStoryChapterConfigs.GetNextChapterCfgByChapterId(chapterId)
    local config = ShortStoryNextChapterCfg[chapterId]
    return config
end