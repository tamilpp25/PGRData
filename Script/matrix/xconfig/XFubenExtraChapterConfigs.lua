XFubenExtraChapterConfigs = {}

local TABLE_CHAPTER_EXTRA = "Share/Fuben/ExtraChapter/ChapterExtra.tab"
local TABLE_CHAPTER_EXTRA_DETAILS = "Share/Fuben/ExtraChapter/ChapterExtraDetails.tab"
local TABLE_CHAPTER_EXTRA_STARTREASURE = "Share/Fuben/ExtraChapter/ChapterExtraStarTreasure.tab"
local TABLE_EXPLOREGROUP = "Client/Fuben/ExtraChapter/ExtraExploreGroup.tab"
local TABLE_EXPLOREITEM = "Client/Fuben/ExtraChapter/ExtraExploreItem.tab"

local ExtraChapterCfgs = {} --TABLE_CHAPTER_EXTRA ChapterExtra.tab 番外章节数据，与Details表关联，难度指向不同的章节详细项
local ExtraChapterDetailsCfgs = {} --TABLE_CHAPTER_EXTRA_DETAILS ChapterExtraDetails.tab 番外章节详细数据
local ExtraChapterStarTreasureCfgs = {} --TABLE_CHAPTER_EXTRA_STARTREASURE ChapterExtraStarTreasure.tab
local ExtraExploreGroupCfgs = {} --TABLE_EXPLOREGROUP ExtraExploreGroup.tab 番外探索组
local ExtraExploreItemCfgs = {} --TABLE_EXPLOREITEM ExtraExploreItem.tab 番外探索道具数据

function XFubenExtraChapterConfigs.Init()
    ExtraChapterCfgs = XTableManager.ReadAllByIntKey(TABLE_CHAPTER_EXTRA, XTable.XTableChapterExtra, "Id")
    ExtraChapterDetailsCfgs = XTableManager.ReadByIntKey(TABLE_CHAPTER_EXTRA_DETAILS, XTable.XTableChapterExtraDetails, "ChapterId")
    ExtraChapterStarTreasureCfgs = XTableManager.ReadByIntKey(TABLE_CHAPTER_EXTRA_STARTREASURE, XTable.XTableChapterExtraStarTreasure, "TreasureId")
    ExtraExploreGroupCfgs = XTableManager.ReadByIntKey(TABLE_EXPLOREGROUP, XTable.XTableExtraExploreGroup, "Id")
    ExtraExploreItemCfgs = XTableManager.ReadByIntKey(TABLE_EXPLOREITEM, XTable.XTableExtraExploreItem, "Id")
end

function XFubenExtraChapterConfigs.GetExtraChapterCfgs()
    return ExtraChapterCfgs
end

function XFubenExtraChapterConfigs.GetExtraChapterDetailsCfgs()
    return ExtraChapterDetailsCfgs
end

function XFubenExtraChapterConfigs.GetExtraChapterStarTreasuresCfgs()
    return ExtraChapterStarTreasureCfgs
end

function XFubenExtraChapterConfigs.GetExploreGroupCfg()
    return ExtraExploreGroupCfgs
end

function XFubenExtraChapterConfigs.GetExploreItemCfg()
    return ExtraExploreItemCfgs
end

function XFubenExtraChapterConfigs.GetExploreItemCfgById(id)
    if not ExtraExploreItemCfgs[id] then
        XLog.ErrorTableDataNotFound("XFubenExtraChapterConfigs.GetExploreItemCfgById", "ExtraExploreItem", TABLE_EXPLOREITEM, "Id", tostring(id))
        return nil
    end
    return ExtraExploreItemCfgs[id]
end

---
--- 根据'chapterMainId'获取章节的周目Id
---@param chapterMainId number
---@return number
function XFubenExtraChapterConfigs.GetZhouMuId(chapterMainId)
    if (ExtraChapterCfgs or {})[chapterMainId] == nil then
        XLog.ErrorTableDataNotFound("XFubenExtraChapterConfigs.GetZhouMuId",
        "外篇章节", TABLE_CHAPTER_EXTRA, "Id", tostring(chapterMainId))
        return
    end
    return ExtraChapterCfgs[chapterMainId].ZhouMuId
end