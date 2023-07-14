--玩法兵法蓝图配置类
XRpgTowerConfig = XRpgTowerConfig or {}

--    ===================表地址
local SHARE_TABLE_PATH = "Share/Fuben/Rpg/"
local CLIENT_TABLE_PATH = "Client/Fuben/Rpg/"

local TABLE_CHARACTER = SHARE_TABLE_PATH .. "RpgCharacter.tab"
local TABLE_CONFIG = SHARE_TABLE_PATH .. "RpgConfig.tab"
local TABLE_TALENT = SHARE_TABLE_PATH .. "RpgTalent.tab"
local TABLE_STAGE = SHARE_TABLE_PATH .. "RpgStage.tab"
local TABLE_TEAM_LEVEL = SHARE_TABLE_PATH .. "RpgTeamLevel.tab"
local TABLE_TALENT_LAYER = SHARE_TABLE_PATH .. "RpgTalentLayer.tab"
local TABLE_MONSTER = CLIENT_TABLE_PATH .. "RpgMonsters.tab"
local TABLE_BASE_CHARACTER = CLIENT_TABLE_PATH .. "RpgBaseCharacter.tab"
local TABLE_ITEM_CONFIG = CLIENT_TABLE_PATH .. "RpgItemConfig.tab"
local TABLE_TALENT_TYPE = CLIENT_TABLE_PATH .. "RpgTalentType.tab"
--    ===================原表数据
local RpgTowerConfig = {}
local RCharacterConfig = {}
local RCharaTalentConfig = {}
local RCharaTalentLayerConfig = {}
local RStageConfig = {}
local RMonsterConfig = {}
local RBaseCharacterConfig = {}
local RItemConfig = {}
local RTeamLevelConfig = {}
local RTalentTypeConfig = {}
--    ===================构建搜索用字典
local CharacterAndLevel2RCharacterDic = {}
local RCharacter2TalentDic = {}
local StageId2RStageCfgDic = {}
local ActivityId2RStageListDic = {}
local CharacterId2TalentsDic = {}

--    ===================变量
local TheLatestConfigIndex
local CharaMaxLevel = 1
local TeamMaxLevel = 1
--[[
================
获取最新的玩法基础配置ID
================
]]
local GetLatestConfigId = function()
    TheLatestConfigIndex = -1
    --先适配第一个时间内的配置
    local now = XTime.GetServerNowTimestamp()
    for id, config in pairs(RpgTowerConfig) do
        local startTime = XFunctionManager.GetStartTimeByTimeId(config.TimeId)
        local endTime = XFunctionManager.GetEndTimeByTimeId(config.TimeId)
        if startTime <= now and now <= endTime then
            TheLatestConfigIndex = id
            break
        end
    end
    --若没有活动在时间内，以以下选取开始时间最晚的
    if TheLatestConfigIndex == -1 then
        local tempTime = 0
        local tempId = -1
        for id, config in pairs(RpgTowerConfig) do
            local startTime = XFunctionManager.GetStartTimeByTimeId(config.TimeId)
            if startTime > now then
                local delta = startTime - now
                if tempTime == 0 or tempTime > delta then
                    tempTime = delta
                    tempId = id
                end
            end
        end
        if tempId ~= -1 then
            TheLatestConfigIndex = tempId
        else
            tempTime = 0
            for id, config in pairs(RpgTowerConfig) do
                local endTime = XFunctionManager.GetEndTimeByTimeId(config.TimeId)
                if endTime < now then
                    local delta = now - endTime
                    if tempTime == 0 or tempTime > delta then
                        tempTime = delta
                        tempId = id
                    end
                end
            end
            if tempId ~= -1 then
                TheLatestConfigIndex = tempId
            else
                TheLatestConfigIndex = #RpgTowerConfig
            end
        end
    end
end
--===============
--获取满级级数
--===============
local GetTeamMaxLevel = function()
    local maxLevel = 0
    for _, _ in pairs(RTeamLevelConfig) do
        maxLevel = maxLevel + 1
    end
    TeamMaxLevel = maxLevel
end
--[[
================
初始化玩法基础配置
================
]]
local InitConfig = function()
    RpgTowerConfig = XTableManager.ReadByIntKey(TABLE_CONFIG, XTable.XTableRpgConfig, "Id")
    RTeamLevelConfig = XTableManager.ReadByIntKey(TABLE_TEAM_LEVEL, XTable.XTableRpgTeamLevel, "Level")
    RCharaTalentLayerConfig = XTableManager.ReadByIntKey(TABLE_TALENT_LAYER, XTable.XTableRpgTalentLayer, "LayerId")
    RTalentTypeConfig = XTableManager.ReadByIntKey(TABLE_TALENT_TYPE, XTable.XTableRpgTalentType, "Id")
    GetTeamMaxLevel()
end

--[[
================
构建字典：角色ID+等级搜索玩法角色
================
]]
local CreateCharaAndLevel2RCharaDic = function()
    for _, rCharaCfg in pairs(RCharacterConfig) do
        if not CharacterAndLevel2RCharacterDic[rCharaCfg.CharacterId] then
            CharacterAndLevel2RCharacterDic[rCharaCfg.CharacterId] = {}
        end
        CharacterAndLevel2RCharacterDic[rCharaCfg.CharacterId][rCharaCfg.Level] = rCharaCfg
        if rCharaCfg.Level > CharaMaxLevel then CharaMaxLevel = rCharaCfg.Level end
    end
end

--[[
================
初始化角色配置表
================
]]
local InitCharacterConfig = function()
    RCharacterConfig = XTableManager.ReadByIntKey(TABLE_CHARACTER, XTable.XTableRpgCharacter, "Id")
    RBaseCharacterConfig = XTableManager.ReadByIntKey(TABLE_BASE_CHARACTER, XTable.XTableRpgBaseCharacter, "Id")
    CreateCharaAndLevel2RCharaDic()
end

--[[
================
构建字典：StageId转到RStage
================
]]
local CreateStageId2RStageCfgDic = function()
    for _, rStageCfg in pairs(RStageConfig) do
        if not StageId2RStageCfgDic[rStageCfg.StageId] then
            StageId2RStageCfgDic[rStageCfg.StageId] = rStageCfg
        end
    end
end

--[[
================
构建字典：ActivityId检索对应RStage列表
================
]]
local CreateActivityId2RStageListDic = function()
    for _, rStageCfg in pairs(RStageConfig) do
        if not ActivityId2RStageListDic[rStageCfg.ActivityId] then
            ActivityId2RStageListDic[rStageCfg.ActivityId] = {}
        end
        ActivityId2RStageListDic[rStageCfg.ActivityId][rStageCfg.OrderId] = rStageCfg
    end
end
--[[
================
初始化玩法关卡表
================
]]
local InitStageConfig = function()
    RStageConfig = XTableManager.ReadByIntKey(TABLE_STAGE, XTable.XTableRpgStage, "Id")
    CreateStageId2RStageCfgDic()
    CreateActivityId2RStageListDic()
end
--[[
================
初始化怪物数据表
================
]]
local InitMonsterConfig = function()
    RMonsterConfig = XTableManager.ReadByIntKey(TABLE_MONSTER, XTable.XTableRpgMonsters, "Id")
end
--[[
================
构建角色ID映射对应角色天赋列表字典
================
]]
local CreateCharacterId2TalentsDic = function()
    for _, talentCfg in pairs(RCharaTalentConfig) do
        if not CharacterId2TalentsDic[talentCfg.CharacterId] then
            CharacterId2TalentsDic[talentCfg.CharacterId] = {}
        end
        if not CharacterId2TalentsDic[talentCfg.CharacterId][talentCfg.LayerId] then
            CharacterId2TalentsDic[talentCfg.CharacterId][talentCfg.LayerId] = {}
        end
        table.insert(CharacterId2TalentsDic[talentCfg.CharacterId][talentCfg.LayerId], talentCfg)
    end
end
--[[
================
初始化天赋数据表
================
]]
local InitTalentConfig = function()
    RCharaTalentConfig = XTableManager.ReadByIntKey(TABLE_TALENT, XTable.XTableRpgTalent, "TalentId")
    CreateCharacterId2TalentsDic()
end
--[[
================
初始化玩法道具表
================
]]
local InitItemConfig = function()
    RItemConfig = XTableManager.ReadByIntKey(TABLE_ITEM_CONFIG, XTable.XTableRpgItemConfig, "Id")
end
--[[
================
初始化Config
================
]]
function XRpgTowerConfig.Init()
    InitConfig()
    InitCharacterConfig()
    InitStageConfig()
    InitMonsterConfig()
    InitTalentConfig()
    InitItemConfig()
end

--================
--获取开始时间最晚的玩法配置
--================
function XRpgTowerConfig.GetLatestConfig()
    GetLatestConfigId()
    if not RpgTowerConfig[TheLatestConfigIndex] then
        XLog.Error(string.format("兵法蓝图玩法配置为空，请检查！%s",
                TABLE_CONFIG))
        return
    end
    return RpgTowerConfig[TheLatestConfigIndex]
end

--[[
================
获取指定ID的玩法配置
@param id:兵法蓝图配置ID
================
]]
function XRpgTowerConfig.GetRpgTowerConfigById(id)
    if not RpgTowerConfig[id] then
        XLog.ErrorTableDataNotFound(
            "XRpgTowerConfig.GetRpgTowerConfigById",
            "RpgConfig",
            TABLE_CONFIG,
            "Id",
            tostring(id))
        return RpgTowerConfig[TheLatestConfigIndex]
    end
    return RpgTowerConfig[id]
end

--[[
================
获取指定ID的玩法角色配置
@param rCharaId:兵法蓝图角色ID
================
]]
function XRpgTowerConfig.GetRCharacterCfgById(rCharaId)
    if not RCharacterConfig[rCharaId] then
        XLog.ErrorTableDataNotFound(
            "XRpgTowerConfig.GetRCharacterCfgById",
            "RCharacter",
            TABLE_CHARACTER,
            "Id",
            tostring(rCharaId))
        return nil
    end
    return RCharacterConfig[rCharaId]
end

--[[
================
获取指定角色ID和星级的玩法角色配置
@param characterId:角色ID
@param level:角色玩法内的星级
================
]]
function XRpgTowerConfig.GetRCharacterCfgByCharacterIdAndLevel(characterId, level)
    if not CharacterAndLevel2RCharacterDic[characterId] then
        XLog.Error(string.format("要查找的角色ID没有对应的兵法蓝图角色，请检查%s, 角色ID为%d",
                TABLE_CHARACTER,
                characterId))
        return nil
    elseif not CharacterAndLevel2RCharacterDic[characterId][level] then
        XLog.Error(string.format("查找的兵法蓝图角色没有对应等级配置，请检查%s, 角色ID为%d, 等级为%d",
                TABLE_CHARACTER,
                characterId,
                level))
        return nil
    end
    return CharacterAndLevel2RCharacterDic[characterId][level]
end

--[[
================
获取角色最大星级数
================
]]
function XRpgTowerConfig.GetCharaMaxLevel()
    return CharaMaxLevel
end

--[[
================
获取配置内所有关卡列表
================
]]
function XRpgTowerConfig.GetRStageList()
    return RStageConfig
end
--[[
================
通过活动ID获取活动所属所有关卡列表
================
]]
function XRpgTowerConfig.GetRStageListByActivityId(activityId)
    if not ActivityId2RStageListDic[activityId] then
        XLog.Error(string.format("兵法蓝图关卡表并不存在属于给定的活动ID的数据，请检查！表地址:%s, ActivityId:%s",
                TABLE_STAGE,
                tostring(activityId)))
        return nil
    end
    return ActivityId2RStageListDic[activityId]
end
--================
--获取指定关卡ID的玩法关卡配置
--@param rStageId:兵法蓝图关卡ID
--================
function XRpgTowerConfig.GetRStageCfgById(rStageId)
    if not RStageConfig[rStageId] then
        XLog.ErrorTableDataNotFound(
            "XRpgTowerConfig.GetRStageCfgById",
            "兵法蓝图关卡",
            TABLE_STAGE,
            "Id",
            tostring(rStageId)
            )
        return nil
    end
    return RStageConfig[rStageId]
end

--[[
================
使用关卡ID查找相应的兵法蓝图关卡配置
@param stageId:关卡ID
================
]]
function XRpgTowerConfig.GetRStageCfgByStageId(stageId)
    if not StageId2RStageCfgDic[stageId] then
        XLog.Error(
            string.format("指定关卡ID不在兵法蓝图关卡表中！请检查！表地址：%s,StageId：%s",
                TABLE_STAGE,
                tostring(stageId))
            )
        return nil
    end
    return StageId2RStageCfgDic[stageId]
end

--[[
================
使用关卡ID查找相应的兵法蓝图关卡Id
@param stageId:关卡ID
================
]]
function XRpgTowerConfig.GetRStageIdByStageId(stageId)
    if not StageId2RStageCfgDic[stageId] then
        XLog.Error(
            string.format("指定关卡ID不在兵法蓝图关卡表中！请检查！表地址：%s,StageId：%s",
                TABLE_STAGE,
                tostring(stageId))
        )
        return nil
    end
    return StageId2RStageCfgDic[stageId].Id
end

--[[
================
使用玩法怪物ID查找兵法蓝图玩法怪物配置
@param rMonsterId:玩法怪物ID
================
]]
function XRpgTowerConfig.GetRMonsterCfgById(rMonsterId)
    if not RMonsterConfig[rMonsterId] then
        XLog.ErrorTableDataNotFound(
            "XRpgTowerConfig.GetRMonsterCfgById",
            "兵法蓝图怪物数据",
            TABLE_MONSTER,
            "Id",
            tostring(rMonsterId)
            )
        return nil
    end
    return RMonsterConfig[rMonsterId]
end
--[[
================
使用玩法怪物ID查找MonsterNpcDataId
@param rMonsterId:玩法怪物ID
================
]]
function XRpgTowerConfig.GetMonsterNpcDataIdByRMonsterId(rMonsterId)
    if not RMonsterConfig[rMonsterId] then
        XLog.ErrorTableDataNotFound(
            "XRpgTowerConfig.GetMonsterNpcDataIdByRMonsterId",
            "兵法蓝图怪物数据",
            TABLE_MONSTER,
            "Id",
            tostring(rMonsterId)
        )
        return nil
    end
    return RMonsterConfig[rMonsterId].MonsterNpcDataId
end

--[[
================
使用玩法怪物ID查找配置字段IsBoss
@param rMonsterId:玩法怪物ID
================
]]
function XRpgTowerConfig.GetMonsterIsBossByRMonsterId(rMonsterId)
    if not rMonsterId then return false end
    if not RMonsterConfig[rMonsterId] then
        XLog.ErrorTableDataNotFound(
            "XRpgTowerConfig.GetMonsterIsBossByRMonsterId",
            "兵法蓝图怪物数据",
            TABLE_MONSTER,
            "Id",
            tostring(rMonsterId)
        )
        return nil
    end
    return RMonsterConfig[rMonsterId].IsBoss == 1
end


--[[
================
使用角色ID查找玩法角色基础配置
@param characterId:角色Id
================
]]
function XRpgTowerConfig.GetRBaseCharaCfgByCharacterId(characterId)
    if not RBaseCharacterConfig[characterId] then
        XLog.ErrorTableDataNotFound(
            "XRpgTowerConfig.GetRBaseCharaCfgByCharacterId",
            "兵法蓝图Base角色数据",
            TABLE_BASE_CHARACTER,
            "Id",
            tostring(characterId)
        )
        return nil
    end
    return RBaseCharacterConfig[characterId]
end

--[[
================
使用天赋ID查找天赋表配置
@param talentId:天赋表talentId
================
]]
function XRpgTowerConfig.GetTalentCfgById(talentId)
    if not RCharaTalentConfig[talentId] then
        XLog.ErrorTableDataNotFound(
            "XRpgTowerConfig.GetTalentCfgById",
            "兵法蓝图角色天赋数据",
            TABLE_TALENT,
            "talentId",
            tostring(talentId)
        )
        return nil
    end
    return RCharaTalentConfig[talentId]
end

--[[
================
使用角色ID查找对应的天赋列表
@param characterId:角色ID
================
]]
function XRpgTowerConfig.GetTalentCfgsByCharacterId(characterId)
    if not CharacterId2TalentsDic[characterId] then
        XLog.ErrorTableDataNotFound(
            "XRpgTowerConfig.GetTalentCfgsByCharacterId",
            "兵法蓝图角色天赋数据",
            TABLE_TALENT,
            "CharacterId",
            tostring(characterId)
        )
        return nil
    end
    return CharacterId2TalentsDic[characterId]
end
--[[
================
使用天赋位置ID查找对应的天赋前置位置列表
@param posId:位置ID
================
]]
function XRpgTowerConfig.GetTalentByCharaIdAndLayerId(charaId, layerId)
    local charaTalents = CharacterId2TalentsDic[charaId]
    if charaTalents then
        return CharacterId2TalentsDic[charaId][layerId]
    end
    return nil
end
--[[
================
使用玩法道具ID查找道具配置
@param rItemId:玩法道具ID
================
]]
function XRpgTowerConfig.GetRItemConfigByRItemId(rItemId)
    if not RItemConfig[rItemId] then
        XLog.ErrorTableDataNotFound(
            "XRpgTowerConfig.GetRItemConfigByRItemId",
            "兵法蓝图道具数据",
            TABLE_ITEM_CONFIG,
            "Id",
            tostring(rItemId)
        )
        return nil
    end
    return RItemConfig[rItemId]
end
--=================
--获取最高等级
--=================
function XRpgTowerConfig.GetTeamMaxLevel()
    return TeamMaxLevel
end
--=================
--根据等级获取队伍等级配置
--@param level:队伍等级
--=================
function XRpgTowerConfig.GetTeamLevelCfgByLevel(level)
    if not RTeamLevelConfig[level] then
        XLog.ErrorTableDataNotFound(
            "XRpgTowerConfig.GetTeamLevelCfgByLevel",
            "Rpg玩法队伍等级",
            TABLE_TEAM_LEVEL,
            "Level",
            tostring(level)
        )
        return nil
    end
    return RTeamLevelConfig[level]
end
--=================
--获取所有天赋等级配置
--=================
function XRpgTowerConfig.GetAllTalentLayerCfgs()
    return RCharaTalentLayerConfig
end
--=================
--根据等级获取天赋配置
--@param level:天赋等级
--=================
function XRpgTowerConfig.GetTalentLayerCfgByLayerId(layerId)
    return RCharaTalentLayerConfig[layerId]
end
--=================
--根据天赋类型获取天赋类型名称
--@param talentTypeId:天赋类型Id
--=================
function XRpgTowerConfig.GetTalentTypeNameById(talentTypeId)
    return RTalentTypeConfig[talentTypeId] and RTalentTypeConfig[talentTypeId].Name
end
--=================
--根据天赋类型获取天赋类型图标
--@param talentTypeId:天赋类型Id
--=================
function XRpgTowerConfig.GetTalentTypeIconById(talentTypeId)
    return RTalentTypeConfig[talentTypeId] and RTalentTypeConfig[talentTypeId].Icon
end
--=================
--根据天赋类型获取编队界面天赋类型底图地址
--@param talentTypeId:天赋类型Id
--=================
function XRpgTowerConfig.GetTalentTypeBattleRoomBgById(talentTypeId)
    return RTalentTypeConfig[talentTypeId] and RTalentTypeConfig[talentTypeId].BattleRoomBg
end

