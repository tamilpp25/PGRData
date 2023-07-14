XPrequelConfigs = XPrequelConfigs or {}

local TABLE_PREQUEL_CHAPTER = "Share/Fuben/Prequel/Chapter.tab"
local TABLE_PREQUEL_COVER = "Share/Fuben/Prequel/Cover.tab"
local TABLE_PREQUEL_COVERINFO = "Client/Fuben/Prequel/CoverInfo.tab"
local TABLE_PREQUEL_CHAPTERINFO = "Client/Fuben/Prequel/ChapterInfo.tab"
local TABLE_FRAGMENT = "Client/Fuben/Prequel/Fragment.tab"

local PrequelChapter = {}
local PrequelCover = {}
local PrequelCoverInfo = {}
local PrequelChapterInfo = {}
local Fragment = {} --角色碎片

-- config层
local Stage2ChapterMap = {}--记录stage对应的chapter

function XPrequelConfigs.Init()
    PrequelChapter = XTableManager.ReadAllByIntKey(TABLE_PREQUEL_CHAPTER, XTable.XTablePrequelChapter, "ChapterId")
    PrequelCover = XTableManager.ReadAllByIntKey(TABLE_PREQUEL_COVER, XTable.XTablePrequelCover, "CoverId")
    PrequelCoverInfo = XTableManager.ReadAllByIntKey(TABLE_PREQUEL_COVERINFO, XTable.XTablePrequelCoverInfo, "CoverId")
    PrequelChapterInfo = XTableManager.ReadByIntKey(TABLE_PREQUEL_CHAPTERINFO, XTable.XTablePrequelChapterInfo, "ChapterId")
    Fragment = XTableManager.ReadByIntKey(TABLE_FRAGMENT, XTable.XTableFragment, "Id")

    XPrequelConfigs.InitCoverChapterMapping()
end

function XPrequelConfigs.InitCoverChapterMapping()
    -- Chapter2CoverMap[chapterId] = coverId
    -- for coverId, coverInfo in pairs(PrequelCover) do
    --     for _, chapterId in pairs(coverInfo.ChapterId) do
    --         Chapter2CoverMap[chapterId] = coverId
    --     end
    -- end
    -- Stage2ChapterMap[stageId] = chapterId
    for chapterId, chapterInfo in pairs(PrequelChapter) do
        for _, stageId in pairs(chapterInfo.StageId) do
            Stage2ChapterMap[stageId] = chapterId
        end
    end
end

function XPrequelConfigs.GetChapterByStageId(stageId)
    return Stage2ChapterMap[stageId]
end

function XPrequelConfigs.GetPrequelCoverInfoById(coverId)

    local coverInfo = PrequelCoverInfo[coverId]
    if not coverInfo then
        XLog.ErrorTableDataNotFound("XPrequelConfigs.GetPrequelCoverInfoById", "coverInfo", TABLE_PREQUEL_COVERINFO, "coverId", tostring(coverId))
        return
    end

    return coverInfo
end

function XPrequelConfigs.GetPrequelChapterInfoById(chapterId)
    local chapterInfo = PrequelChapterInfo[chapterId]

    if not chapterInfo then
        XLog.ErrorTableDataNotFound("XPrequelConfigs.GetPrequelChapterInfoById", "chapterInfo", TABLE_PREQUEL_CHAPTERINFO, "chapterId", tostring(chapterId))
    end

    return chapterInfo
end

function XPrequelConfigs.GetPrequelCoverList()
    return PrequelCover
end

function XPrequelConfigs.GetPrequelCoverById(coverId)
    local coverData = PrequelCover[coverId]

    if not coverData then
        XLog.ErrorTableDataNotFound("XPrequelConfigs.GetPrequelCoverById", "coverData", TABLE_PREQUEL_COVER, "coverId", tostring(coverId))
        return
    end

    return coverData
end

function XPrequelConfigs.GetPrequelChapterById(chapterId)
    local chapterData = PrequelChapter[chapterId]

    if not chapterData then
        XLog.ErrorTableDataNotFound("XPrequelConfigs.GetPrequelChapterById", "chapterData", TABLE_PREQUEL_CHAPTER, "chapterId", tostring(chapterId))
        return
    end

    return chapterData
end

function XPrequelConfigs.GetPequelAllChapter()
    return PrequelChapter
end

function XPrequelConfigs.GetRegionalProgress(current, total)
    return string.format("<color=#0f70bc><size=48>%d</size></color>/%d", current, total)
end

function XPrequelConfigs.GetNotEnoughCost(costNum)
    return string.format("<color=#f11b25>%d</color>", costNum)
end

function XPrequelConfigs.GetFragments()
    return Fragment
end
--[[修改过的PreStageId
XUiGridCourse
XFubenManager
--]]