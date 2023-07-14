XDlcConfig = XDlcConfig or {}

local TABLE_DLC_LIST_PATH       = "Client/DlcRes/DlcList.tab"
local TABLE_PATHC_CONFIG_PATH   = "Client/DlcRes/PatchConfig.tab"
local TABLE_UNPATCH_CONFIG_PATH = "Client/DlcRes/UnPatchConfig.tab"

local DlcListConfig = nil
local PatchConfig = nil
local UnPatchConfig = nil

local EntryDlcIdMap = nil
local StageIdMap = nil
local RootId2DlcListIds -- 根节点 -> 子节点列表

local EntryType = {
    MainChapter         = 1,  -- 主线      参数：章节id（chapterMain.Id），配置在 Share/Fuben/MainLine/ChapterMain.tab
    ShortStory          = 2,  -- 浮点纪实  参数：章节id 配置:Share/Fuben/ShortStory/ShortStoryChapter.tab
    Prequel             = 3,  -- 间章旧闻  参数：章节ChapterId 配置:Share/Fuben/Prequel/Chapter.tab
    FestivalActivity    = 4,  -- 活动记录  参数：活动Id 配置:Share/Fuben/Festival/FestivalActivity.tab
    CharacterTower      = 5,  -- 本我回廊  参数：活动Id 配置:Share/Fuben/CharacterTower/CharacterTower.tab
    ExtraChapter        = 6,  -- 外篇旧闻  参数：活动Id 配置:Share/Fuben/ExtraChapter/ChapterExtra.tab
    Challenge           = 7,  -- 挑战      参数：挑战类型（XFubenManager.ChapterType），定义在 Share/Fuben/FubenChallengeBanner.tab
    Archive             = 8,  -- 图鉴      参数：默认0
    CharacterVoice      = 9,  -- 角色语音  参数：默认0
}
XDlcConfig.EntryType = EntryType

XDlcConfig.DownloadState = {
    Ready       = 1, --准备下载
    InProgress  = 2, --下载中
    Pause       = 3, --暂停
}

XDlcConfig.RoodId = {
    MainLine    = 100, --主线
    BranchLine  = 200, --支线
    Challenge   = 300, --挑战
    Other       = 400, --其他
}

local ChapterType2EntryType

local DlcResourceType = CS.XFightResourceManager.XStageResourceType

function XDlcConfig.Init()
    DlcListConfig = XTableManager.ReadByIntKey(TABLE_DLC_LIST_PATH, XTable.XTableDlcList, "Id")
    PatchConfig = XTableManager.ReadByIntKey(TABLE_PATHC_CONFIG_PATH, XTable.XTablePatchConfig, "Id")
    UnPatchConfig = XTableManager.ReadByIntKey(TABLE_UNPATCH_CONFIG_PATH, XTable.XTableUnPatchConfig, "Id")

    EntryDlcIdMap = {}
    RootId2DlcListIds = {}
    for id, config in pairs(DlcListConfig) do
        local entryType = config.EntryType
        if not EntryDlcIdMap[entryType] then
            EntryDlcIdMap[entryType] = {}
        end
        EntryDlcIdMap[entryType][config.EntryParam] = id
        local rootId = config.RootId
        if rootId == 0 then
            RootId2DlcListIds[id] = RootId2DlcListIds[id] or {}
        else
            RootId2DlcListIds[rootId] = RootId2DlcListIds[rootId] or {}
            table.insert(RootId2DlcListIds[rootId], id)
        end
    end
    XDlcConfig.InitPatchConfig()
end

function XDlcConfig.InitPatchConfig()
    StageIdMap = {}
    for dlcId, config in pairs(PatchConfig) do
        local resourceType = config.ResourceType
        for index, rType in ipairs(resourceType or {}) do
            local types = string.Split(rType, "|")
            for _, t in ipairs(types or {}) do
                if string.IsNilOrEmpty(t) then
                    goto continue
                end
                if DlcResourceType then
                    local enumValue = DlcResourceType.__CastFrom(tonumber(t))
                    if enumValue == DlcResourceType.File or enumValue == DlcResourceType.Directory then
                        goto continue
                    end
                end
                local param = config.ResourceParam[index]
                local stageIds = string.Split(param, "|")
                for _, stageId in ipairs(stageIds or {}) do
                    local stageIdNum = not string.IsNilOrEmpty(stageId) and tonumber(stageId)
                    if stageIdNum then
                        StageIdMap[stageIdNum] = StageIdMap[stageIdNum] or {}
                        StageIdMap[stageIdNum][dlcId] = true
                    end
                end
                ::continue::
            end
        end
    end

    --调试模式
    if XMain.IsDebug then
        local checkMap = {}
        for stageId, temp in pairs(StageIdMap) do
            for dlcId, _ in pairs(temp) do
                checkMap[stageId] = checkMap[stageId] or {}
                table.insert(checkMap[stageId], dlcId)
            end
        end

        local log = ""
        for stageId, list in pairs(checkMap) do
            if #list >= 2 then
                log = string.format("%s关卡Id:%s -> PatchIdList = %s\n", log, stageId, table.concat(list, ","))
            end
        end

        if not string.IsNilOrEmpty(log) then
            XLog.Error("PatchConfig.tab关卡Id重复:", log)
        end
    end
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

function XDlcConfig.GetDlcListIdsByRootId(rootId)
    return RootId2DlcListIds[rootId] or  {}
end

-- 根据功能入口获取分包id
function XDlcConfig.GetDlcIdsByEntry(entryType, entryParam)
    entryParam = entryParam or 0
    if EntryDlcIdMap[entryType] then
        local dlcId = EntryDlcIdMap[entryType][entryParam]
        if dlcId then
            return DlcListConfig[dlcId].PatchConfigIds
        end
    end
    XLog.Debug("尝试根据[功能入口]或取分包id, 失败: entryType:" .. tostring(entryType) .. ", entryParam:" .. tostring(entryParam))
end

--根据关卡Id获取DlcListId
function XDlcConfig.GetDlcListIdByStageId(stageId)
    local dlcIdMap = StageIdMap[stageId]
    if XTool.IsTableEmpty(dlcIdMap) then
        return {}
    end
    local dlcListIds = {}
    for dlcListId, config in pairs(DlcListConfig) do
        local dlcIds = config.PatchConfigIds
        for _, dId in ipairs(dlcIds or {}) do
            if dlcIdMap[dId] then
                table.insert(dlcListIds, dlcListId)
            end
        end
    end
    return dlcListIds
end

--根据功能入口获取Id
function XDlcConfig.GetDlcListIdByEntry(entryType, entryParam)
    entryParam = entryParam or 0
    if EntryDlcIdMap[entryType] then
        local dlcId = EntryDlcIdMap[entryType][entryParam]
        if dlcId then
            return dlcId
        end
    end
end 

function XDlcConfig.GetEntryTypeByChapterType(chapterType)
    if not ChapterType2EntryType then
        ChapterType2EntryType = {
            [XFubenConfigs.ChapterType.MainLine]        = EntryType.MainChapter,
            [XFubenConfigs.ChapterType.ShortStory]      = EntryType.ShortStory,
            [XFubenConfigs.ChapterType.Prequel]         = EntryType.Prequel,
            [XFubenConfigs.ChapterType.Festival]        = EntryType.FestivalActivity,
            [XFubenConfigs.ChapterType.CharacterTower]  = EntryType.CharacterTower,
            [XFubenConfigs.ChapterType.ExtralChapter]   = EntryType.ExtraChapter,
        }
    end
    local entryType = ChapterType2EntryType[chapterType]
    if not entryType then
        XLog.Error("[DLC] not found entryType! chapterType = " .. chapterType)
        return 0
    end
    return entryType
end

function XDlcConfig.GetSizeAndUnit(size)
    local unit = "KB"
    local num = size / 1024
    if num > 100 then
        unit = "MB"
        num = num / 1024
    end
    return math.ceil(num), unit
end 