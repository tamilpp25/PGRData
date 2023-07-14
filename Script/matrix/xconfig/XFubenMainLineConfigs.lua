XFubenMainLineConfigs = XFubenMainLineConfigs or {}

local TABLE_CHAPTER_MAIN = "Share/Fuben/MainLine/ChapterMain.tab"
local TABLE_CHAPTER = "Share/Fuben/MainLine/Chapter.tab"
local TABLE_SUBCHAPTER = "Share/Fuben/MainLine/SubChapter.tab"
local TABLE_TREASURE = "Share/Fuben/MainLine/Treasure.tab"
local TABLE_EXPLOREGROUP = "Client/Fuben/MainLine/ExploreGroup.tab"
local TABLE_EXPLOREITEM = "Client/Fuben/MainLine/ExploreItem.tab"
local TABLE_STAGEEX = "Client/Fuben/MainLine/MainLineStageEx.tab"
local TABLE_PARALLELANIMEGROUP = "Client/Fuben/MainLine/ParallelAnimeGroup.tab"

local ChapterMainTemplates = {}
local ChapterCfg = {}
local TreasureCfg = {}
local ExploreGroupCfg = {}
local ExploreItemCfg = {}
local MainLineExCfg = {}
local SubChapterCfg = {}
local ParallelAnimeGroupCfg = {}

function XFubenMainLineConfigs.Init()
    ChapterMainTemplates = XTableManager.ReadByIntKey(TABLE_CHAPTER_MAIN, XTable.XTableChapterMain, "Id")
    ChapterCfg = XTableManager.ReadAllByIntKey(TABLE_CHAPTER, XTable.XTableChapter, "ChapterId")
    SubChapterCfg = XTableManager.ReadAllByIntKey(TABLE_SUBCHAPTER, XTable.XTableSubChapter, "ChapterId")
    TreasureCfg = XTableManager.ReadAllByIntKey(TABLE_TREASURE, XTable.XTableTreasure, "TreasureId")
    ExploreGroupCfg = XTableManager.ReadByIntKey(TABLE_EXPLOREGROUP, XTable.XTableMainLineExploreGroup, "Id")
    MainLineExCfg = XTableManager.ReadByIntKey(TABLE_STAGEEX, XTable.XTableMainLineStageEx, "Id")
    ParallelAnimeGroupCfg = XTableManager.ReadByIntKey(TABLE_PARALLELANIMEGROUP, XTable.XTableParallelAnimeGroup, "Id")
    ExploreItemCfg = XTableManager.ReadByIntKey(TABLE_EXPLOREITEM, XTable.XTableMainLineExploreItem, "Id")
end

function XFubenMainLineConfigs.GetChapterMainTemplates()
    return ChapterMainTemplates
end

function XFubenMainLineConfigs.GetChapterCfg()
    return ChapterCfg
end

function XFubenMainLineConfigs.GetTreasureCfg()
    return TreasureCfg
end

function XFubenMainLineConfigs.GetExploreGroupCfg()
    return ExploreGroupCfg
end

function XFubenMainLineConfigs.GetExploreItemCfg()
    return ExploreItemCfg
end

function XFubenMainLineConfigs.GetExploreItemCfgById(id)
    return ExploreItemCfg[id]
end

function XFubenMainLineConfigs.GetParallelAnimeGroupCfg()
    return ParallelAnimeGroupCfg
end

---
--- 根据'chapterMainId'获取章节的周目Id
---@param chapterMainId number
---@return number
function XFubenMainLineConfigs.GetZhouMuId(chapterMainId)
    if (ChapterMainTemplates or {})[chapterMainId] == nil then
        XLog.ErrorTableDataNotFound("XFubenMainLineConfigs.GetZhouMuId",
        "主线章节", TABLE_CHAPTER_MAIN, "Id", tostring(chapterMainId))
        return
    end
    return ChapterMainTemplates[chapterMainId].ZhouMuId
end

local GetChapterMainConfig = function(id)
    local config = ChapterMainTemplates[id]
    if not config then
        XLog.Error("XTRPGConfigs GetChapterMainConfig error:配置不存在, Id: " .. id .. ", 配置路径: " .. TABLE_CHAPTER_MAIN)
        return
    end
    return config
end

function XFubenMainLineConfigs.GetChapterMainChapterEn(id)
    local config = GetChapterMainConfig(id)
    return config.ChapterEn
end

function XFubenMainLineConfigs.GetStageExById(id)
    return MainLineExCfg[id]
end

function XFubenMainLineConfigs.GetSubChapterCfg(id)
    return SubChapterCfg[id]
end 