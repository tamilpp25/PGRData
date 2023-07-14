XDlcConfig = XDlcConfig or {}

local TABLE_DLC_LIST_PATH = "Client/DlcRes/DlcList.tab"
local TABLE_PATHC_CONFIG_PATH = "Client/DlcRes/PatchConfig.tab"
local TABLE_UNPATCH_CONFIG_PATH = "Client/DlcRes/UnPatchConfig.tab"

local DlcListConfig = nil
local PatchConfig = nil
local UnPatchConfig = nil

local EntryDlcIdMap = nil
local StageIdMap = nil

local EntryType = {
    MainChapter = 1, -- 主线，参数：章节id（chapterMain.Id），配置在 Share/Fuben/MainLine/ChapterMain.tab
    ExtraChapter = 2, -- 外篇，参数：章节id（chapterId），配置在 Share/Fuben/ExtraChapter/ChapterExtra.tab
    Chanllenge = 3, -- 挑战，参数：挑战类型（XFubenManager.ChapterType），定义在 Share/Fuben/FubenChallengeBanner.tab
    Bfrt = 4, -- 据点，参数：章节id（chapterId），配置在 Share/Fuben/Bfrt/BfrtChapter.tab
}
XDlcConfig.EntryType = EntryType

function XDlcConfig.Init()
    DlcListConfig = XTableManager.ReadByIntKey(TABLE_DLC_LIST_PATH, XTable.XTableDlcList, "Id")
    PatchConfig = XTableManager.ReadByIntKey(TABLE_PATHC_CONFIG_PATH, XTable.XTablePatchConfig, "Id")
    UnPatchConfig = XTableManager.ReadByIntKey(TABLE_UNPATCH_CONFIG_PATH, XTable.XTableUnPatchConfig, "Id")

    EntryDlcIdMap = {}
    for id, config in pairs(DlcListConfig) do
        if not EntryDlcIdMap[config.EntryType] then
            EntryDlcIdMap[config.EntryType] = {}
        end
        EntryDlcIdMap[config.EntryType][config.EntryParam] = id
    end
    StageIdMap = {}
end

function XDlcConfig.GetDlcListConfig()
    return DlcListConfig
end

function XDlcConfig.GetPatchConfig()
    return PatchConfig
end

function XDlcConfig.GetUnPatchConfig()
    return UnPatchConfig
end

function XDlcConfig.GetListConfigById(id)
    local config = DlcListConfig[id]
    if not config then
        XLog.ErrorTableDataNotFound("XDlcConfig.GetListConfigById",
        "DlcList", TABLE_DLC_LIST_PATH, "Id", tostring(id))
    end
    return config
end

-- 根据功能入口获取分包id
function XDlcConfig.GetDlcIdsByEntry(entryType, entryParam)
    if EntryDlcIdMap[entryType] then
        local dlcId = EntryDlcIdMap[entryType][entryParam]
        if dlcId then
            return DlcListConfig[dlcId].PatchConfigIds
        end
    end
    XLog.Debug("尝试根据[功能入口]或取分包id, 失败: entryType:" .. tostring(entryType) .. ", entryParam:" .. tostring(entryParam))
end

-- 根据关卡id获取分包id
function XDlcConfig.GetDlcIdsByStageId(stageId)
    local dlcId  = StageIdMap[stageId]
    if not StageIdMap[stageId] then
        for id, config in pairs(DlcListConfig) do
            -- 主线和外篇入口参数使用stageId
            if config.EntryType == EntryType.MainChapter or config.EntryType == EntryType.ExtraChapter and stageId == config.EntryParam then
                dlcId = id
                StageIdMap[stageId] = id
            end
        end
    end
    if dlcId then
        return DlcListConfig[dlcId].PatchConfigIds
    end
    XLog.Debug("尝试根据[stageId]获取分包id, 失败: stageId:" .. tostring(stageId))
end