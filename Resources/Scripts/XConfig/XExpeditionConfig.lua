XExpeditionConfig = XExpeditionConfig or {}
--基础角色表
local TABLE_EXPEDITION_BASE_CHARACTER = "Share/Fuben/Expedition/ExpeditionBaseCharacter.tab"
--角色表
local TABLE_EXPEDITION_CHARACTER = "Share/Fuben/Expedition/ExpeditionCharacter.tab"
--远征章节表
local TABLE_EXPEDITION_CHAPTER = "Share/Fuben/Expedition/ExpeditionChapter.tab"
--远征关卡表
local TABLE_EXPEDITION_STAGE = "Share/Fuben/Expedition/ExpeditionStage.tab"
--玩法配置
local TABLE_EXPEDITION_CONFIG = "Share/Fuben/Expedition/ExpeditionConfig.tab"
--角色基础组合羁绊表
local TABLE_EXPEDITION_COMBO = "Share/Fuben/Expedition/ExpeditionCombo.tab"
--角色组合羁绊子分类表
local TABLE_EXPEDITION_CHILDCOMBO = "Share/Fuben/Expedition/ExpeditionChildCombo.tab"
--角色分类展示表
local TABLE_EXPEDITION_CHARACTER_TYPE = "Share/Fuben/Expedition/ExpeditionCharacterType.tab"
--角色阶级升级表
local TABLE_EXPEDITION_CHARACTER_ELEMENTS = "Client/Fuben/Expedition/ExpeditionCharacterElements.tab"
--羁绊大类表
local TABLE_EXPEDITION_COMBO_TYPENAME = "Client/Fuben/Expedition/ExpeditionComboTypeName.tab"
--螺母购买刷新次数表
local TABLE_EXPEDITION_DRAW_CONSUME = "Share/Fuben/Expedition/ExpeditionDrawConsume.tab"
--全局增益羁绊
local TABLE_EXPEDITION_GLOBAL_COMBO = "Client/Fuben/Expedition/ExpeditionGlobalCombo.tab"
--队伍位置表
local TABLE_EXPEDITION_TEAMPOS = "Share/Fuben/Expedition/ExpeditionTeamPos.tab"
--招募概率表
local TABLE_EXPEDITION_DRAWPR = "Share/Fuben/Expedition/ExpeditionDrawPR.tab"
--招募概率星数对照表
local TABLE_EXPEDITION_DRAWRANK = "Share/Fuben/Expedition/ExpeditionDrawRank.tab"

local BaseConfig = {}
local ChildComboConfig = {}
local ComboConfig = {}
local CharacterTypeConfig = {}
local CharacterConfig = {}
local CharacterElements = {}
local BaseCharacterConfig = {}
local ChapterConfig = {}
local EStageConfig = {}
local ComboTypeNameConfig = {}
local DrawConsumeConfig = {}
local GlobalComboConfig = {}
local TeamPosConfig = {}
local DrawPRConfig = {}
local DrawRankConfig = {}

local Type2CharacterDic = {}
local Rank2CharacterDic = {}
local Chapter2StageDic = {}
local Chapter2ConfigDic = {}
local Chapter2TeamPosDic = {}
local NewBaseConfigIndex = 0

local BaseComboStatus = {} -- 废弃
local BaseComboDic = {}
local StageToEStageDic = {}
local ComboConditionList = {
    [1] = "MemberNum", -- 检查合计数量
    [2] = "TotalRank",  -- 检查合计等级
    [3] = "TargetMember", -- 检查对应角色等级
    [4] = "TargetTypeAndRank", -- 检查指定特征的高于指定等级的人
}

local InitConfig = function()
    BaseConfig = XTableManager.ReadByIntKey(TABLE_EXPEDITION_CONFIG, XTable.XTableExpeditionConfig, "Id")
    ComboConfig = XTableManager.ReadByIntKey(TABLE_EXPEDITION_COMBO, XTable.XTableExpeditionCombo, "Id")
    ChildComboConfig = XTableManager.ReadByIntKey(TABLE_EXPEDITION_CHILDCOMBO, XTable.XTableExpeditionChildCombo, "Id")
    ChapterConfig = XTableManager.ReadByIntKey(TABLE_EXPEDITION_CHAPTER, XTable.XTableExpeditionChapter, "Id")
    EStageConfig = XTableManager.ReadByIntKey(TABLE_EXPEDITION_STAGE, XTable.XTableExpeditionStage, "Id")
    BaseCharacterConfig = XTableManager.ReadByIntKey(TABLE_EXPEDITION_BASE_CHARACTER, XTable.XTableExpeditionBaseCharacter, "Id")
    CharacterConfig = XTableManager.ReadByIntKey(TABLE_EXPEDITION_CHARACTER, XTable.XTableExpeditionCharacter, "Id")
    CharacterTypeConfig = XTableManager.ReadByStringKey(TABLE_EXPEDITION_CHARACTER_TYPE, XTable.XTableExpeditionCharacterType, "Id")
    ComboTypeNameConfig = XTableManager.ReadByIntKey(TABLE_EXPEDITION_COMBO_TYPENAME, XTable.XTableExpeditionComboTypeName, "Id")
    DrawConsumeConfig = XTableManager.ReadByIntKey(TABLE_EXPEDITION_DRAW_CONSUME, XTable.XTableExpeditionDrawConsume, "Id")
    GlobalComboConfig = XTableManager.ReadByIntKey(TABLE_EXPEDITION_GLOBAL_COMBO, XTable.XTableExpeditionGlobalCombo, "Id")
    CharacterElements = XTableManager.ReadByIntKey(TABLE_EXPEDITION_CHARACTER_ELEMENTS, XTable.XTableExpeditionCharacterElements, "Id")
    TeamPosConfig = XTableManager.ReadByIntKey(TABLE_EXPEDITION_TEAMPOS, XTable.XTableExpeditionTeamPos, "Id")
    DrawPRConfig = XTableManager.ReadByIntKey(TABLE_EXPEDITION_DRAWPR, XTable.XTableExpeditionDrawPR, "Level")
    DrawRankConfig = XTableManager.ReadByIntKey(TABLE_EXPEDITION_DRAWRANK, XTable.XTableExpeditionDrawRank, "Id")
end

local GetNewBaseConfigId = function()
    local startTime = 0
    for id, config in pairs(BaseConfig) do
        if id > NewBaseConfigIndex then NewBaseConfigIndex = id end
    end   
end

local InitComboConfig = function()
    for i = 1, #ComboConfig do
        if not BaseComboDic[ComboConfig[i].ChildComboId] then
            BaseComboDic[ComboConfig[i].ChildComboId] = {}
        end
        table.insert(BaseComboDic[ComboConfig[i].ChildComboId], ComboConfig[i])
    end
end

local InitStages = function()
    for _, eStage in pairs(EStageConfig) do
        if not Chapter2StageDic[eStage.ChapterId] then Chapter2StageDic[eStage.ChapterId] = {} end
        Chapter2StageDic[eStage.ChapterId][eStage.OrderId] = eStage
        if not StageToEStageDic[eStage.StageId] then
            StageToEStageDic[eStage.StageId] = eStage
        end
    end
end


local InitCharacter = function()
    for _, v in pairs(BaseCharacterConfig) do
        for _, type in pairs(v.Type) do
            if not Type2CharacterDic[type] then Type2CharacterDic[type] = {} end
            if not Type2CharacterDic[type][v.Id] then Type2CharacterDic[type][v.Id] = 1 end
        end
        Rank2CharacterDic[v.Id] = {}
    end
end

local InitRank2CharacterDic = function()
    for _, v in pairs(CharacterConfig) do
        Rank2CharacterDic[v.BaseId][v.Rank] = v
        if not Rank2CharacterDic[v.BaseId].MaxRank or Rank2CharacterDic[v.BaseId].MaxRank < v.Rank then
            Rank2CharacterDic[v.BaseId].MaxRank = v.Rank
        end
    end
end

local InitChapter2TeamPosDic = function()
    for _, v in pairs(TeamPosConfig) do
        if not Chapter2TeamPosDic[v.ChapterId] then Chapter2TeamPosDic[v.ChapterId] = {} end
        table.insert(Chapter2TeamPosDic[v.ChapterId], v)
    end
end

function XExpeditionConfig.Init()
    InitConfig()
    GetNewBaseConfigId()
    InitStages()
    InitCharacter()
    InitRank2CharacterDic()
    InitComboConfig()  
    InitChapter2TeamPosDic()
end

function XExpeditionConfig.GetExpeditionConfig()
    return BaseConfig
end

function XExpeditionConfig.GetExpeditionConfigById(Id)
    return BaseConfig[Id] or BaseConfig[NewBaseConfigIndex]
end

function XExpeditionConfig.GetLastestExpeditionConfig()
    return BaseConfig[NewBaseConfigIndex]
end

function XExpeditionConfig.GetEChapterCfg()
    return ChapterConfig
end

function XExpeditionConfig.GetChapterCfgById(chapterId)
    if not ChapterConfig[chapterId] then
        XLog.ErrorTableDataNotFound("XExpeditionConfig.GetChapterCfgById", "虚像地平线章节数据",
            TABLE_EXPEDITION_CHAPTER, "Id", tostring(chapterId))
        return nil
    end
    return ChapterConfig[chapterId]
end

function XExpeditionConfig.GetChapterRewardIdById(chapterId)
    return ChapterConfig[chapterId] and ChapterConfig[chapterId].RewardId or 0
end

function XExpeditionConfig.GetEStageListByChapterId(chapterId)
    return Chapter2StageDic[chapterId]
end

function XExpeditionConfig.GetStageList()
    return StageToEStageDic
end

function XExpeditionConfig.GetEStageByStageId(stageId)
    return StageToEStageDic[stageId]
end

function XExpeditionConfig.GetEStageIdByStageId(stageId)
    return StageToEStageDic[stageId] and StageToEStageDic[stageId].Id
end

function XExpeditionConfig.GetOrderIdByStageId(stageId)
    return StageToEStageDic[stageId].OrderId
end

function XExpeditionConfig.GetBaseCharacterCfg()
    return BaseCharacterConfig
end

function XExpeditionConfig.GetBaseCharacterCfgById(baseId)
    return BaseCharacterConfig[baseId]
end

function XExpeditionConfig.GetBaseIdByECharId(eCharacterId)
    return CharacterConfig[eCharacterId].BaseId
end

function XExpeditionConfig.GetCharacterIdByBaseId(baseId)
    return BaseCharacterConfig[baseId] and BaseCharacterConfig[baseId].CharacterId or 0
end

function XExpeditionConfig.GetCharacterElementByBaseId(baseId)
    return BaseCharacterConfig[baseId] and BaseCharacterConfig[baseId].Elements or {}
end

function XExpeditionConfig.GetCharacterMaxRankByBaseId(baseId)
    return Rank2CharacterDic[baseId].MaxRank
end

function XExpeditionConfig.GetCharacterCfgByBaseIdAndRank(baseId, rank)
    local base = Rank2CharacterDic[baseId]
    if not base then
        return nil
    end
    if base.MaxRank < rank then
        return base[base.MaxRank]
    else
        return base[rank]
    end
end

function XExpeditionConfig.GetCharacterCfgs()
    return CharacterConfig
end

function XExpeditionConfig.GetCharacterCfgById(Id)
    if not CharacterConfig[Id] then
        XLog.ErrorTableDataNotFound("XExpeditionConfig.GetCharacterById", "虚像地平线角色", TABLE_EXPEDITION_CHARACTER, "Id", tostring(Id))
    end
    return CharacterConfig[Id]
end

function XExpeditionConfig.GetEStageCfg(EStageId)
    if not EStageConfig[EStageId] then
        XLog.ErrorTableDataNotFound("XExpeditionConfig.GetEStageCfg", "虚像地平线关卡", TABLE_EXPEDITION_STAGE, "Id", tostring(EStageId))
        return nil
    end
    return EStageConfig[EStageId]
end

function XExpeditionConfig.GetCharacterElementById(elementId)
    return CharacterElements[elementId]
end

function XExpeditionConfig.GetComboTable()
    return ComboConfig
end

function XExpeditionConfig.GetChildComboTable()
    return ChildComboConfig
end
--================
--根据子羁绊类型Id获取具体羁绊列表
--================
function XExpeditionConfig.GetComboByChildComboId(childComboId)
    if not BaseComboDic[childComboId] then
        XLog.ErrorTableDataNotFound(
            "XExpeditionConfig.GetComboByChildComboId",
            "虚像地平线成员组合数据",
            TABLE_EXPEDITION_COMBO,
            "ChildComboId",
            tostring(childComboId))
        return nil
    end
    return BaseComboDic[childComboId]
end

function XExpeditionConfig.GetChildComboById(id)
    if not ChildComboConfig[id] then
        XLog.ErrorTableDataNotFound("XExpeditionConfig.GetEStageCfg",
            "虚像地平线羁绊子分类数据", TABLE_EXPEDITION_CHILDCOMBO, "Id", tostring(id))
        return nil
    end
    return ChildComboConfig[id]
end

function XExpeditionConfig.GetComboById(comboId)
    if not ComboConfig[comboId] then
        XLog.ErrorTableDataNotFound("XExpeditionConfig.GetComboById", "虚像地平线阵容", TABLE_EXPEDITION_COMBO, "Id", tostring(comboId))
        return nil
    end
    return ComboConfig[comboId]
end

function XExpeditionConfig.GetCharactersByCharacterType(typeId)
    if not Type2CharacterDic[typeId] then
        XLog.ErrorTableDataNotFound("XExpeditionConfig.GetCharactersByCharacterType", "虚像地平线角色词条", TABLE_EXPEDITION_CHARACTER_TYPE, "Id", tostring(typeId))
        return nil
    end
    return Type2CharacterDic[typeId]
end

function XExpeditionConfig.IsCharacterHasTypes(characterId, typeIds)
    for _, typeId in pairs(typeIds) do
        local id = tonumber(typeId)
        if not Type2CharacterDic[id] or not Type2CharacterDic[id][characterId] then
            return false
        end
    end
    return true
end

function XExpeditionConfig.GetBaseComboTypeConfig()
    return ComboTypeNameConfig
end

function XExpeditionConfig.GetBaseComboTypeNameById(id)
    return ComboTypeNameConfig[id].Name or ""
end

function XExpeditionConfig.GetBuyDrawMaxTime()
    return #DrawConsumeConfig
end

function XExpeditionConfig.GetDrawPriceByCount(count)
    return DrawConsumeConfig[count] and DrawConsumeConfig[count].ConsumeCount or 0
end

function XExpeditionConfig.GetGlobalConfigs()
    return GlobalComboConfig
end

function XExpeditionConfig.GetGlobalConfigById(comboId)
    return GlobalComboConfig[comboId]
end

function XExpeditionConfig.GetRankByRankWeightId(index)
    return DrawRankConfig[index] and DrawRankConfig[index].Rank or 1
end
--================
--获取队伍位置数据
--@param teamPosId:位置ID
--================
function XExpeditionConfig.GetTeamPosCfgById(teamPosId)
    if not TeamPosConfig[teamPosId] then
        XLog.ErrorTableDataNotFound(
            "XExpeditionConfig.GetTeamPosCfgById",
            "虚像地平线队伍位置数据",
            TABLE_EXPEDITION_TEAMPOS,
            "Id",
            tostring(teamPosId))
        return nil
    end
    return TeamPosConfig[teamPosId]
end
--================
--获取队伍位置数量
--================
function XExpeditionConfig.GetTeamPosListByChapterId(currentChapterId)
    if not TeamPosConfig or not Chapter2TeamPosDic or not Chapter2TeamPosDic[currentChapterId] then return 0 end
    return Chapter2TeamPosDic[currentChapterId]
end
--================
--获取招募概率配置表
--================
function XExpeditionConfig.GetDrawPRConfig()
    return DrawPRConfig
end
--================
--获取招募星数对照表配置
--================
function XExpeditionConfig.GetDrawRankConfig()
    return DrawRankConfig
end