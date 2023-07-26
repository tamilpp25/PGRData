XFubenCharacterTowerConfigs = XFubenCharacterTowerConfigs or {}

local SHARE_CHARACTER_TOWER = "Share/Fuben/CharacterTower/CharacterTower.tab"
local SHARE_CHARACTER_TOWER_CHAPTER = "Share/Fuben/CharacterTower/CharacterTowerChapter.tab"
local SHARE_CHARACTER_TOWER_RELATION = "Share/Fuben/CharacterTower/CharacterTowerRelation.tab"
local SHARE_CHARACTER_TOWER_TREASURE = "Share/Fuben/CharacterTower/CharacterTowerTreasure.tab"

local CLIENT_CHARACTER_TOWER_CHAPTER_DETAIL = "Client/Fuben/CharacterTower/CharacterTowerChapterDetail.tab"
local CLIENT_CHARACTER_TOWER_RELATION_DETAIL = "Client/Fuben/CharacterTower/CharacterTowerRelationDetail.tab"
local CLIENT_CHARACTER_TOWER_CONFIG = "Client/Fuben/CharacterTower/CharacterTowerConfig.tab"
local CLIENT_CHARACTER_TOWER_ACTION_DISPLAY = "Client/Fuben/CharacterTower/CharacterTowerActionDisplay.tab"
local CLIENT_CHARACTER_TOWER_DISPLAY_CONTROLLER = "Client/Fuben/CharacterTower/CharacterTowerDisplayController.tab"

local CharacterTowerCfg = {}
local CharacterTowerChapterCfg = {}
local CharacterTowerRelationCfg = {}
local CharacterTowerTreasureCfg = {}

local CharacterTowerChapterDetailCfg = {}
local CharacterTowerRelationDetailCfg = {}
local CharacterTowerActionDisplayCfg = {}
local CharacterTowerDisplayControllerCfg = {}

local ConditionType2InfoDic = {}

XFubenCharacterTowerConfigs.CharacterTowerChapterType = {
    Story = 1, -- 剧情关
    Challenge = 2, -- 挑战关
}

XFubenCharacterTowerConfigs.ListeningType = {
    Character = 1, -- 角色
    Favorability = 2, -- 好感度
    Stage = 3, -- 关卡
}   

-- 配置监听类型的条件Type
XFubenCharacterTowerConfigs.ListeningConditionType = {
    [1] = { 13103, 13108, 13114 },
    [2] = { 13117 },
    [3] = { 10105, 17117 },
}

function XFubenCharacterTowerConfigs.Init()
    CharacterTowerCfg = XTableManager.ReadByIntKey(SHARE_CHARACTER_TOWER, XTable.XTableCharacterTower, "Id")
    CharacterTowerChapterCfg = XTableManager.ReadByIntKey(SHARE_CHARACTER_TOWER_CHAPTER, XTable.XTableCharacterTowerChapter, "Id")
    CharacterTowerRelationCfg = XTableManager.ReadByIntKey(SHARE_CHARACTER_TOWER_RELATION, XTable.XTableCharacterTowerRelation, "Id")
    CharacterTowerTreasureCfg = XTableManager.ReadByIntKey(SHARE_CHARACTER_TOWER_TREASURE, XTable.XTableCharacterTowerTreasure, "TreasureId")
    CharacterTowerChapterDetailCfg = XTableManager.ReadByIntKey(CLIENT_CHARACTER_TOWER_CHAPTER_DETAIL, XTable.XTableCharacterTowerChapterDetail, "Id")
    CharacterTowerRelationDetailCfg = XTableManager.ReadByIntKey(CLIENT_CHARACTER_TOWER_RELATION_DETAIL, XTable.XTableCharacterTowerRelationDetail, "Id")
    CharacterTowerActionDisplayCfg = XTableManager.ReadByIntKey(CLIENT_CHARACTER_TOWER_ACTION_DISPLAY, XTable.XTableCharacterTowerActionDisplay, "Id")
    CharacterTowerDisplayControllerCfg = XTableManager.ReadByIntKey(CLIENT_CHARACTER_TOWER_DISPLAY_CONTROLLER, XTable.XTableCharacterTowerDisplayController, "CharacterId")
    XConfigCenter.CreateGetPropertyByFunc(XFubenCharacterTowerConfigs, "CharacterTowerConfig", function()
        return XTableManager.ReadByStringKey(CLIENT_CHARACTER_TOWER_CONFIG, XTable.XTableCharacterTowerConfig, "Key")
    end)
end

local function GetCharacterTowerCfg(id)
    local config = CharacterTowerCfg[id]
    if not config then
        XLog.ErrorTableDataNotFound("GetCharacterTowerCfg", "tab", SHARE_CHARACTER_TOWER, "id", tostring(id))
        return nil
    end
    return config
end

local function GetCharacterTowerChapterCfg(chapterId)
    local config = CharacterTowerChapterCfg[chapterId]
    if not config then
        XLog.ErrorTableDataNotFound("GetCharacterTowerChapterCfg", "tab", SHARE_CHARACTER_TOWER_CHAPTER, "Id", tostring(chapterId))
        return nil
    end
    return config
end

local function GetCharacterTowerRelationCfg(relationId)
    local config = CharacterTowerRelationCfg[relationId]
    if not config then
        XLog.ErrorTableDataNotFound("GetCharacterTowerRelationCfg", "tab", SHARE_CHARACTER_TOWER_RELATION, "Id", tostring(relationId))
        return nil
    end
    return config
end

local function GetCharacterTowerTreasureCfg(treasureId)
    local config = CharacterTowerTreasureCfg[treasureId]
    if not config then
        XLog.ErrorTableDataNotFound("GetCharacterTowerTreasureCfg", "tab", SHARE_CHARACTER_TOWER_TREASURE, "TreasureId", tostring(treasureId))
        return nil
    end
    return config
end

local function GetCharacterTowerChapterDetailCfg(chapterId)
    local config = CharacterTowerChapterDetailCfg[chapterId]
    if not config then
        XLog.ErrorTableDataNotFound("GetCharacterTowerChapterDetailCfg", "tab", CLIENT_CHARACTER_TOWER_CHAPTER_DETAIL, "Id", tostring(chapterId))
        return nil
    end
    return config
end

local function GetCharacterTowerRelationDetailCfg(relationId)
    local config = CharacterTowerRelationDetailCfg[relationId]
    if not config then
        XLog.ErrorTableDataNotFound("GetCharacterTowerRelationDetailCfg", "tab", CLIENT_CHARACTER_TOWER_RELATION_DETAIL, "Id", tostring(relationId))
        return nil
    end
    return config
end

--region Share 配置

function XFubenCharacterTowerConfigs.GetAllCharacterTowerCfg()
    return CharacterTowerCfg
end

function XFubenCharacterTowerConfigs.GetCharacterTowerById(id)
    return GetCharacterTowerCfg(id)
end

function XFubenCharacterTowerConfigs.GetChapterIdsById(id)
    local config = GetCharacterTowerCfg(id)
    return config.ChapterIds or {}
end

function XFubenCharacterTowerConfigs.GetCharacterNameById(id)
    local config = GetCharacterTowerCfg(id)
    return config.CharacterName or ""
end

function XFubenCharacterTowerConfigs.GetIdByChapterId(chapterId)
    for _, config in pairs(CharacterTowerCfg) do
        local isContain = table.contains(config.ChapterIds or {}, chapterId)
        if isContain then
            return config.Id
        end
    end
    return 0
end

function XFubenCharacterTowerConfigs.GetChapterConfig(chapterId)
    return GetCharacterTowerChapterCfg(chapterId)
end

function XFubenCharacterTowerConfigs.GetStageIdsByChapterId(chapterId)
    local config = GetCharacterTowerChapterCfg(chapterId)
    return config.StageIds or {}
end

function XFubenCharacterTowerConfigs.GetRelationConfig(relationId)
    return GetCharacterTowerRelationCfg(relationId)
end

function XFubenCharacterTowerConfigs.GetRewardIdByTreasureId(treasureId)
    local config = GetCharacterTowerTreasureCfg(treasureId)
    return config.RewardId or 0
end

function XFubenCharacterTowerConfigs.GetRequireStarByTreasureId(treasureId)
    local config = GetCharacterTowerTreasureCfg(treasureId)
    return config.RequireStar or 0
end

--endregion

--region Client 配置

function XFubenCharacterTowerConfigs.GetChapterDetailConfig(chapterId)
    return GetCharacterTowerChapterDetailCfg(chapterId)
end

function XFubenCharacterTowerConfigs.GetRelationDetailConfig(relationId)
    return GetCharacterTowerRelationDetailCfg(relationId)
end

function XFubenCharacterTowerConfigs.GetCharacterTowerConfigValueByKey(key)
    return XFubenCharacterTowerConfigs.GetCharacterTowerConfig(key).Value
end

function XFubenCharacterTowerConfigs.GetSignBoardActionIdById(id)
    local config = CharacterTowerActionDisplayCfg[id]
    if not config then
        return nil
    end
    return config.SignBoardActionId or 0
end

function XFubenCharacterTowerConfigs.GetDisabledActionId(characterId)
    local config = CharacterTowerDisplayControllerCfg[characterId]
    if not config then
        return {}
    end
    return config.DisabledActionId or {}
end

--endregion

local function InitListeningCondition()
    for _, towerChapter in pairs(CharacterTowerChapterCfg) do
        if XTool.IsNumberValid(towerChapter.RelationGroupId) then
            local towerRelation = GetCharacterTowerRelationCfg(towerChapter.RelationGroupId)
            for _, conditionId in pairs(towerRelation.Conditions) do
                local template = XConditionManager.GetConditionTemplate(conditionId)
                if not ConditionType2InfoDic[template.Type] then
                    ConditionType2InfoDic[template.Type] = {}
                end
                table.insert(ConditionType2InfoDic[template.Type], { CharacterId = towerChapter.CharacterId, ChapterId = towerChapter.Id, ConditionId = conditionId })
            end
        end
    end
end

function XFubenCharacterTowerConfigs.GetInfoDicByListeningType(type)
    if XTool.IsTableEmpty(ConditionType2InfoDic) then
        InitListeningCondition()
    end
    local allConditionInfo = {}
    local conditionTypes = XFubenCharacterTowerConfigs.ListeningConditionType[type]
    for _, conditionType in pairs(conditionTypes or {}) do
        local temp = ConditionType2InfoDic[conditionType] or {}
        allConditionInfo = XTool.MergeArray(allConditionInfo, temp)
    end
    return allConditionInfo
end