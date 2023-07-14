XFubenMainLineConfigs = XFubenMainLineConfigs or {}

local TABLE_CHAPTER_MAIN = "Share/Fuben/MainLine/ChapterMain.tab"
local TABLE_CHAPTER = "Share/Fuben/MainLine/Chapter.tab"
local TABLE_TREASURE = "Share/Fuben/MainLine/Treasure.tab"
local TABLE_EXPLOREGROUP = "Client/Fuben/MainLine/ExploreGroup.tab"
local TABLE_EXPLOREITEM = "Client/Fuben/MainLine/ExploreItem.tab"

local ChapterMainTemplates = {}
local ChapterCfg = {}
local TreasureCfg = {}
local ExploreGroupCfg = {}
local ExploreItemCfg = {}

function XFubenMainLineConfigs.Init()
    ChapterMainTemplates = XTableManager.ReadByIntKey(TABLE_CHAPTER_MAIN, XTable.XTableChapterMain, "Id")
    ChapterCfg = XTableManager.ReadByIntKey(TABLE_CHAPTER, XTable.XTableChapter, "ChapterId")
    TreasureCfg = XTableManager.ReadByIntKey(TABLE_TREASURE, XTable.XTableTreasure, "TreasureId")
    ExploreGroupCfg = XTableManager.ReadByIntKey(TABLE_EXPLOREGROUP, XTable.XTableMainLineExploreGroup, "Id")
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