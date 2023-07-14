XFubenMainLineConfigs = XConfigCenter.CreateTableConfig(XFubenMainLineConfigs, "XFubenMainLineConfigs"
    , "Fuben/MainLine")
--=============
--配置表枚举
--TableName : 表名，对应需要读取的表的文件名字，不写即为枚举的Key字符串
--TableDefindName : 表定于名，默认同表名
--ReadFuncName : 读取表格的方法，默认为ReadByIntKey
--ReadKeyName : 读取表格的主键名，默认为Id
--DirType : 读取的文件夹类型XConfigCenter.DirectoryType，默认是Share
--LogKey : GetCfgByIdKey方法idKey找不到时所输出的日志信息，默认是唯一Id
--=============
XFubenMainLineConfigs.TableKey = enum({
    ChapterMainGroup = {},
})

local TABLE_MAINLINE_ACTIVITY = "Share/Fuben/MainLine/MainLineActivity.tab"
local TABLE_CHAPTER_MAIN = "Share/Fuben/MainLine/ChapterMain.tab"
local TABLE_CHAPTER = "Share/Fuben/MainLine/Chapter.tab"
local TABLE_SUBCHAPTER = "Share/Fuben/MainLine/SubChapter.tab"
local TABLE_TREASURE = "Share/Fuben/MainLine/Treasure.tab"
local TABLE_EXPLOREGROUP = "Client/Fuben/MainLine/ExploreGroup.tab"
local TABLE_EXPLOREITEM = "Client/Fuben/MainLine/ExploreItem.tab"
local TABLE_STAGEEX = "Client/Fuben/MainLine/MainLineStageEx.tab"
local TABLE_PARALLELANIMEGROUP = "Client/Fuben/MainLine/ParallelAnimeGroup.tab"
local TABLE_MAINLINE_STAGE_TRANSFORM = "Client/Fuben/MainLine/MainLineStageTransform.tab"
local TABLE_MAINLINE_TELEPORT = "Client/Fuben/MainLine/MainLineTeleport.tab"
local TABLE_MAINLINE_STAGE_CLEAR_CONTR = "Client/Fuben/MainLine/MainLineStageClearContr.tab"
local TABLE_MAINLINE_IGNORE_STAGE_LIST = "Client/Fuben/MainLine/MainlineIgnoreStageList.tab"
local TABLE_MAINLINE_NEXT_CHAPTER = "Client/Fuben/MainLine/MainLineNextChapter.tab"

local MainLineActivityCfg = {}
local ChapterMainTemplates = {}
local ChapterCfg = {}
local TreasureCfg = {}
local ExploreGroupCfg = {}
local ExploreItemCfg = {}
local MainLineExCfg = {}
local SubChapterCfg = {}
local ParallelAnimeGroupCfg = {}
local MainLineStageTransformCfg = {}
local MainLineTeleportCfg = {}
local MainLineStageClearContrCfg = {}
local MainlineIgnoreStageList = {} -- stage黑名单
local MainlineIgnoreStageListByOrder = {}
local MainLineNextChapterCfg = {}

function XFubenMainLineConfigs.Init()
    MainLineActivityCfg = XTableManager.ReadByIntKey(TABLE_MAINLINE_ACTIVITY, XTable.XTableMainLineActivity, "Id")
    ChapterMainTemplates = XTableManager.ReadByIntKey(TABLE_CHAPTER_MAIN, XTable.XTableChapterMain, "Id")
    ChapterCfg = XTableManager.ReadAllByIntKey(TABLE_CHAPTER, XTable.XTableChapter, "ChapterId")
    SubChapterCfg = XTableManager.ReadAllByIntKey(TABLE_SUBCHAPTER, XTable.XTableSubChapter, "ChapterId")
    TreasureCfg = XTableManager.ReadAllByIntKey(TABLE_TREASURE, XTable.XTableTreasure, "TreasureId")
    ExploreGroupCfg = XTableManager.ReadByIntKey(TABLE_EXPLOREGROUP, XTable.XTableMainLineExploreGroup, "Id")
    MainLineExCfg = XTableManager.ReadByIntKey(TABLE_STAGEEX, XTable.XTableMainLineStageEx, "Id")
    ParallelAnimeGroupCfg = XTableManager.ReadByIntKey(TABLE_PARALLELANIMEGROUP, XTable.XTableParallelAnimeGroup, "Id")
    MainLineStageTransformCfg = XTableManager.ReadByIntKey(TABLE_MAINLINE_STAGE_TRANSFORM, XTable.XTableMainLineStageTransform, "Id")
    MainLineTeleportCfg = XTableManager.ReadByIntKey(TABLE_MAINLINE_TELEPORT, XTable.XTableMainLineTeleport, "StageId")
    MainLineStageClearContrCfg = XTableManager.ReadByIntKey(TABLE_MAINLINE_STAGE_CLEAR_CONTR, XTable.XTableMainLineStageClearContr, "StageId")
    MainlineIgnoreStageList = XTableManager.ReadByIntKey(TABLE_MAINLINE_IGNORE_STAGE_LIST, XTable.XTableMainlineIgnoreStageList, "StageId")
    MainLineNextChapterCfg = XTableManager.ReadByIntKey(TABLE_MAINLINE_NEXT_CHAPTER, XTable.XTableMainLineNextChapter, "ChapterId")
end

function XFubenMainLineConfigs.GetMainLineActivityCfg(id)
    local config = MainLineActivityCfg[id]
    if not config then
        XLog.ErrorTableDataNotFound("XFubenMainLineConfigs.GetMainLineActivityCfg", "配置表项", 
                TABLE_MAINLINE_ACTIVITY, "Id", tostring(id))
        return nil
    end
    return config
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

function XFubenMainLineConfigs.GetMainlineIgnoreStageList()
    return MainlineIgnoreStageList
end

function XFubenMainLineConfigs.GetMainlineIgnoreStageListByOrder()
    if not XTool.IsTableEmpty(MainlineIgnoreStageListByOrder) then
        return MainlineIgnoreStageListByOrder
    end

    local list = XFubenMainLineConfigs.GetMainlineIgnoreStageList()
    local res = {}
    for k, v in pairs(list) do
        table.insert(res, v.StageId)
    end
    MainlineIgnoreStageListByOrder = res
    return res
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

function XFubenMainLineConfigs.GetStageTransformsByChapterId(chapterId)
    local stageTransforms = {}
    for _, config in pairs(MainLineStageTransformCfg) do
        if config.ChapterId == chapterId then
            table.insert(stageTransforms, config)
        end
    end
    return stageTransforms
end

function XFubenMainLineConfigs.GetSkipStageIdsByStageId(stageId)
    local config = MainLineTeleportCfg[stageId]
    if not config then
        return {}
    end
    return config.SkipStageId or {}
end

function XFubenMainLineConfigs.GetSkipLoadingTypeByStageId(stageId)
    for _, config in pairs(MainLineTeleportCfg) do
        local contain, index = table.contains(config.SkipStageId or {}, stageId)
        if contain then
            return config.SkipLoadingType[index] or LoadingType.Fight
        end
    end
    return LoadingType.Fight
end

function XFubenMainLineConfigs.GetStageClearContrByStageId(stageId)
    local config = MainLineStageClearContrCfg[stageId]
    if not config then
        XLog.ErrorTableDataNotFound("XFubenMainLineConfigs.GetStageClearContrByStageId", "配置表项", TABLE_MAINLINE_STAGE_CLEAR_CONTR, "stageId", tostring(stageId))
        return nil
    end
    return config
end

function XFubenMainLineConfigs.GetNextChapterCfgByChapterId(chapterId)
    local config = MainLineNextChapterCfg[chapterId]
    return config
end