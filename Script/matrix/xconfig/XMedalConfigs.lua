XMedalConfigs = XMedalConfigs or {}

local TABLE_MEDAL = "Share/Medal/Medal.tab"
local TABLE_SCORETITLE = "Share/ScoreTitle/ScoreTitle.tab"
local TABLE_EXPAND_INFO = "Share/ScoreTitle/ScoreTitleExpandInfo.tab"
local TABLE_SCORESCREEN_TAG = "Share/ScoreTitle/ScoreScreenTag.tab"
local TABLE_SPECOAL_COLLECTION_LEVEL = "Share/ScoreTitle/SpecialCollectionLevel.tab"
local TABLE_COLLECTION_LEVEL = "Client/Medal/CollectionLevel.tab"
local TABLE_SHARE_NAMEPLATE = "Share/Nameplate/Nameplate.tab"



local Meadals = {}
local ScoreTitles = {}
local ScoreScreenTag = {}
local CollectionLevel = {}
local SpecialCollectionLevelDic = {}
local NameplateConfigs = {}
local NameplateGroupDic = {}

local ExpandInfo = {}

local tableSort = table.sort

XMedalConfigs.ViewType = {
    Medal = 1, --勋章
    Collection = 2, --收藏品
    Nameplate = 3, --铭牌
}

-- 收藏页的收藏品字号
XMedalConfigs.EnumCollectionScoreTextSize = {
    CS.XGame.ClientConfig:GetInt("CollectionScoreTextSize1"),
    CS.XGame.ClientConfig:GetInt("CollectionScoreTextSize2"),
    CS.XGame.ClientConfig:GetInt("CollectionScoreTextSize3"),
    CS.XGame.ClientConfig:GetInt("CollectionScoreTextSize4"),
    CS.XGame.ClientConfig:GetInt("CollectionScoreTextSize5"),
}

XMedalConfigs.XNameplatePanelPath = CS.XGame.ClientConfig:GetString("NameplatePanelPath")

XMedalConfigs.MedalType = {
    Normal = 1,
    Babel = 2,
    Experience = 6,
    Anniversary = 9,
}

XMedalConfigs.ShowScore = {
    OFF = 0,
    ON = 1,
}

XMedalConfigs.MedalId = {
    BossSingle = 3, --百万讨伐勋章
}

-- 周年庆收藏品扩展信息
XMedalConfigs.ExpandInfoType = {
    CreateTime = "1", -- 创建时间
    MaxFubenBfrt = "2", -- 据点战最高章节
    MaxAssignChapter = "3", -- 边界公约最高章节
    MaxCharacterLiberateLvCount = "4"   -- 终解成员数
}

XMedalConfigs.Hide = { OFF = 0, ON = 1 }--0显示,1隐藏

XMedalConfigs.NameplateQuality = {
    Copper = 1, --青铜
    Silver = 2, --白银
    Gold = 3, --黄金
}

XMedalConfigs.NameplateGetType = {
    TypeOne = 1, --同组低品质替换高品质
    TypeTwo = 2, --达成条件后获得，提升品质
    TypeThree = 3, --重复获得转换经验
    TypeFour = 4 --重复获得转换其他道具
}

XMedalConfigs.NameplateShow = {
    ShowIcon = 1, --单独显示资源
    ShowBackAndTitle = 2, --资源加title
}

function XMedalConfigs.Init()
    Meadals = XTableManager.ReadByIntKey(TABLE_MEDAL, XTable.XTableMedal, "Id")
    ScoreTitles = XTableManager.ReadByIntKey(TABLE_SCORETITLE, XTable.XTableScoreTitle, "Id")
    ExpandInfo = XTableManager.ReadByIntKey(TABLE_EXPAND_INFO, XTable.XTableScoreTitleExpandInfo, "Id")
    ScoreScreenTag = XTableManager.ReadByIntKey(TABLE_SCORESCREEN_TAG, XTable.XTableScoreScreenTag, "Id")
    CollectionLevel = XTableManager.ReadByIntKey(TABLE_COLLECTION_LEVEL, XTable.XTableCollectionLevel, "Id")
    NameplateConfigs = XTableManager.ReadByIntKey(TABLE_SHARE_NAMEPLATE, XTable.XTableNameplate, "Id")

    XMedalConfigs.SetSpecialCollectionLevelDic()

    XMedalConfigs.InitNameplateConfig()
end

function XMedalConfigs.InitNameplateConfig()
    for _, config in pairs(NameplateConfigs) do
        if config.Title and config.IconType == 2 then
            if config.Title and string.Utf8Len(config.Title) > 6 then
                XLog.Error("铭牌Title字符数量超过六个----Id = " .. config.Id .. " " .. config.Title)
            end
        elseif not config.Title and config.IconType == 2 then
            XLog.Error("铭牌Title为空请检查" .. config.Id)
        end
        NameplateGroupDic[config.Group] = NameplateGroupDic[config.Group] or {}
        table.insert(NameplateGroupDic[config.Group], config)
    end
end

local GetExpandInfoById = function(id)
    local config = ExpandInfo[id]

    if not config then
        XLog.ErrorTableDataNotFound("XMedalConfigs.GetExpandInfoById",
        "ExpandInfo", TABLE_EXPAND_INFO, "Id", tostring(id))
        return {}
    end

    return config
end

function XMedalConfigs.GetExpandInfoStrServerKeyById(id)
    local cfg = GetExpandInfoById(id)
    return cfg.StrServerKey
end

function XMedalConfigs.GetExpandInfoDescById(id)
    local cfg = GetExpandInfoById(id)
    return cfg.Desc
end

function XMedalConfigs.GetExpandInfoEmptyDescById(id)
    local cfg = GetExpandInfoById(id)
    return cfg.EmptyDesc
end

function XMedalConfigs.GetMeadalConfigById(Id)
    return Meadals[Id]
end

function XMedalConfigs.GetMeadalConfigs()
    return Meadals
end

function XMedalConfigs.GetScoreTitlesConfigs()
    return ScoreTitles
end

function XMedalConfigs.GetScoreScreenTagConfigs()
    return ScoreScreenTag
end

function XMedalConfigs.GetCollectionDefaultQualityById(id)
    return ScoreTitles[id].InitQuality
end

function XMedalConfigs.GetCollectionNameById(id)
    return ScoreTitles[id].Name
end

function XMedalConfigs.GetShowScoreById(id)
    return ScoreTitles[id].ShowScore
end

function XMedalConfigs.GetCollectionDescById(id)
    return ScoreTitles[id].MainDesc
end

function XMedalConfigs.GetCollectionWorldDescById(id)
    return ScoreTitles[id].WorldDesc
end

function XMedalConfigs.GetCollectionIconById(id)
    return ScoreTitles[id].MedalImg
end

function XMedalConfigs.GetCollectionGroupById(id)
    return ScoreTitles[id].GroupId
end

function XMedalConfigs.GetCollectionPriorityById(id)
    return ScoreTitles[id].Priority
end

function XMedalConfigs.GetCollectionPrefabPath(id)
    return ScoreTitles[id].PrefabPath
end

function XMedalConfigs.GetCollectionShowMaxLevel(id)
    return ScoreTitles[id] and ScoreTitles[id].ShowMaxLevel or 0
end

function XMedalConfigs.GetCollectionDefaultLevelConfigs()
    return CollectionLevel
end

function XMedalConfigs.GetCollectionDefaultLevelById(id)
    local levelIcon = nil
    local qualities = ScoreTitles[id].Qualities
    if qualities and #qualities > 0 then
        for _, level in pairs(CollectionLevel) do
            if level.CurLevel == 0 and level.MaxLevel == #qualities then
                levelIcon = level.Icon
            end
        end
    end
    return levelIcon
end

function XMedalConfigs.SetSpecialCollectionLevelDic()
    local template = XTableManager.ReadByIntKey(TABLE_SPECOAL_COLLECTION_LEVEL, XTable.XTableSpecialCollectionLevel, "Index")
    for _, level in pairs(template) do
        if not SpecialCollectionLevelDic[level.Id] then
            SpecialCollectionLevelDic[level.Id] = {}
        end
        table.insert(SpecialCollectionLevelDic[level.Id], level)
    end
    for _, LevelList in pairs(SpecialCollectionLevelDic) do
        table.sort(LevelList, function(a, b)
            return a.Score < b.Score
        end)
    end
end

function XMedalConfigs.GetSpecialCollectionCurLevelAndNextScoreByScore(id, score)
    local levelData = SpecialCollectionLevelDic[id]
    if not levelData then
        return 0
    end
    local curLevel
    local nextExp
    local maxLevel
    local maxExp
    local exScore = 0
    for index, data in pairs(levelData) do
        if data.Score > score then
            curLevel = data.Level
            nextExp = (index > 1) and levelData[index].Score - levelData[index - 1].Score or levelData[index].Score
            exScore = (index > 1) and levelData[index - 1].Score - 1 or 0
            break
        else
            maxLevel = data.Level
            maxExp = (index > 1) and levelData[index].Score - levelData[index - 1].Score or levelData[index].Score
            exScore = (index > 1) and levelData[index - 1].Score - 1 or 0
        end

    end

    if curLevel then
        return curLevel, nextExp, exScore
    else
        if maxLevel then
            return maxLevel, maxExp, exScore-------关于满级等级是否+1这一点存在一些歧义
        end
    end

    return 0, 0, 0
end

function XMedalConfigs.SortByPriority(list)
    tableSort(list, function(a, b)
        if a.Priority == b.Priority then
            return a.Id < b.Id
        else
            return a.Priority < b.Priority
        end
    end)
    return list
end

function XMedalConfigs.DeepCopy(orig)
    local copy
    if type(orig) == "table" then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[XMedalConfigs.DeepCopy(orig_key)] = XMedalConfigs.DeepCopy(orig_value)
        end
        setmetatable(copy, XMedalConfigs.DeepCopy(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end


function XMedalConfigs.GetNameplateConfigById(id)
    if not NameplateConfigs or not NameplateConfigs[id] then
        XLog.ErrorTableDataNotFound("XMedalConfigs.GetNameplateConfigById", "铭牌",
        TABLE_SHARE_NAMEPLATE, "id", tostring(id))
    end
    return NameplateConfigs[id]
end

function XMedalConfigs.GetNameplateConfigsByGroup(group)
    if not NameplateGroupDic or not NameplateGroupDic[group] then
        XLog.ErrorTableDataNotFound("XMedalConfigs.GetNameplateConfigsByGroup", "铭牌",
        TABLE_SHARE_NAMEPLATE, "group", tostring(group))
    end
    return NameplateGroupDic[group]
end

function XMedalConfigs.GetNextNameplateConfigByGroup(group, quality)
    local groupList = XMedalConfigs.GetNameplateConfigsByGroup(group)
    local tmpConfig
    for _, config in pairs(groupList) do
        if (not tmpConfig or tmpConfig.NameplateQuality > config.NameplateQuality) and config.NameplateQuality > quality then
            tmpConfig = config
        end
    end
    return tmpConfig
end

function XMedalConfigs.GetNameplateGroup(id)
    local config = XMedalConfigs.GetNameplateConfigById(id)
    if config then
        return config.Group
    end
    return 0
end

function XMedalConfigs.GetNameplateIconType(id)
    local config = XMedalConfigs.GetNameplateConfigById(id)
    if config then
        return config.IconType
    end
    return 0
end

function XMedalConfigs.GetNameplateEffectRes(id)
    local config = XMedalConfigs.GetNameplateConfigById(id)
    if config then
        return config.EffectRes
    end
    return nil
end

function XMedalConfigs.GetNameplateIsNewTextureIcon(id)
    local config = XMedalConfigs.GetNameplateConfigById(id)
    if config then
        return config.IsNewTextureIcon
    end
    return nil
end

function XMedalConfigs.GetNameplateIcon(id)
    local config = XMedalConfigs.GetNameplateConfigById(id)
    if config then
        if config.IconType == XMedalConfigs.NameplateShow.ShowIcon then
            return config.Icon
        else
            return config.BackBoard, config.Title
        end
    end
    return "", ""
end

-- function XMedalConfigs.GetNameplateBackBoard(id)
--     local config = XMedalConfigs.GetNameplateConfigById(id)
--     if config then
--         return config.BackBoard
--     end
--     return ""
-- end
-- function XMedalConfigs.GetNameplateTitle(id)
--     local config = XMedalConfigs.GetNameplateConfigById(id)
--     if config then
--         return config.Title
--     end
--     return ""
-- end
function XMedalConfigs.GetNameplateQuality(id)
    local config = XMedalConfigs.GetNameplateConfigById(id)
    if config then
        return config.NameplateQuality
    end
    return 0
end

function XMedalConfigs.GetNameplateOutLineColor(id)
    local config = XMedalConfigs.GetNameplateConfigById(id)
    if config then
        return config.OutLineColor
    end
    return ""
end

function XMedalConfigs.GetNameplateName(id)
    local config = XMedalConfigs.GetNameplateConfigById(id)
    if config then
        return config.Name
    end
    return ""
end

function XMedalConfigs.GetNameplateDescription(id)
    local config = XMedalConfigs.GetNameplateConfigById(id)
    if config then
        return config.Description
    end
    return ""
end

function XMedalConfigs.GetNameplateHint(id)
    local config = XMedalConfigs.GetNameplateConfigById(id)
    if config then
        return config.Hint
    end
    return ""
end

function XMedalConfigs.GetNameplateGetWay(id)
    local config = XMedalConfigs.GetNameplateConfigById(id)
    if config then
        return config.NameplateGetWay
    end
    return ""
end

function XMedalConfigs.GetNameplateUpgradeType(id)
    local config = XMedalConfigs.GetNameplateConfigById(id)
    if config then
        return config.NameplateUpgradeType
    end
    return ""
end

function XMedalConfigs.GetNameplateQualityIcon(id)
    local config = XMedalConfigs.GetNameplateConfigById(id)
    if config then
        return config.QualityIcon
    end
    return ""
end