XCharacterCuteConfig = XCharacterCuteConfig or {}

local XCharacterCuteConfig = XCharacterCuteConfig

local TABLE_CHARACTER_CUTE = "Client/Character/Cute/CharacterCute.tab"
local TABLE_CHARACTER_CUTE_UI_EFFECT = "Client/Character/Cute/CharacterCuteUiEffect.tab"
local CHARACTER_TAB = "Share/Fuben/StageCharacterNpcId.tab"

local _CharacterCuteConfig
local _CharacterTab

local EffectDictionary = {}
-- Q版角色模型
function XCharacterCuteConfig.Init()
    _CharacterCuteConfig = XTableManager.ReadByIntKey(TABLE_CHARACTER_CUTE, XTable.XTableCharacterCute, "CharacterId")
    _CharacterTab = {}
    for stageType, cfg in pairs(XTableManager.ReadByIntKey(CHARACTER_TAB, XTable.XTableStageCharacterNpcId, "StageType"))do
        for i = 1, #cfg.NpcId do
            local npcId = cfg.NpcId[i]
            local characterId = cfg.CharacterId[i]
            if not _CharacterTab[npcId] then
                _CharacterTab[npcId] = characterId
            elseif _CharacterTab[npcId] ~= characterId then
                XLog.Error("[XCharacterCuteConfig] 配置表StageCharacterNpcId里有相同npcId，但是characterId不同的配置:" .. (characterId or "nil"))
            end
        end
    end

    EffectDictionary = {}
    local DefaultRootName = "Root" --默认父节点名
    local defaultActionId = "DefaultEffect"
    local characterCuteUiEffectConfig = XTableManager.ReadByIntKey(TABLE_CHARACTER_CUTE_UI_EFFECT, XTable.XTableCharacterCuteUiEffect, "Id")
    for _, template in pairs(characterCuteUiEffectConfig) do
        if not XTool.IsNumberValid(template.CharacterId) then
            XLog.Error(string.format("CharacterCuteUiEffect表出错！存在没有填CharacterCuteUiEffect的数据！表地址:" .. TABLE_CHARACTER_CUTE_UI_EFFECT))
        end
        if XTool.IsTableEmpty(template.EffectPath) then
            XLog.Error(string.format("CharacterCuteUiEffect表出错！存在没有填EffectPath的数据！表地址:" .. TABLE_CHARACTER_CUTE_UI_EFFECT .. "Id:" .. template.Id))
        end
        local characterId = template.CharacterId
        EffectDictionary[characterId] = EffectDictionary[characterId] or {}
        local actionId = template.ActionId or defaultActionId
        local tempConfig = EffectDictionary[characterId][actionId]
        if not tempConfig then
            tempConfig = {}
            tempConfig.ActionId = actionId
            tempConfig.Id = template.Id
            tempConfig.EffectRootName = {}
            tempConfig.EffectPath = {}
        end
        local effectLength = #tempConfig.EffectPath + 1
        tempConfig.EffectPath[effectLength] = template.EffectPath
        tempConfig.EffectRootName[effectLength] = template.EffectRootName or DefaultRootName
        EffectDictionary[characterId][actionId] = tempConfig
    end

    if XMain.IsDebug then
        for characterId, dict1 in pairs(EffectDictionary) do
            for actionId, mergedTable in pairs(dict1) do
                local usedRoot = {}
                for i = 1, #mergedTable.EffectPath do
                    local rootName = mergedTable.EffectRootName[i] or DefaultRootName
                    if not usedRoot[rootName] then
                        usedRoot[rootName] = true
                    else
                        XLog.Error("CharacterCuteUiEffect表出错！同一动作不能有重复的EffectRootName数据项！首项Id: " .. mergedTable.Id)
                    end
                end
            end
        end
    end
end

local function GetCuteModelConfig(characterId)
    if not _CharacterCuteConfig[characterId] then
        XLog.Error("[XCharacterCuteConfig] Q版模型配置没有角色" .. (characterId or "nil"))
    end
    return _CharacterCuteConfig[characterId] or {}
end

function XCharacterCuteConfig.GetCuteModelModelName(characterId)
    return GetCuteModelConfig(characterId).ModelName or ""
end

function XCharacterCuteConfig.GetCuteModelSmallHeadIcon(characterId)
    return GetCuteModelConfig(characterId).SmallHeadIcon or ""
end

function XCharacterCuteConfig.GetCuteModelRoundnessHeadIcon(characterId)
    return GetCuteModelConfig(characterId).RoundnessHeadIcon or ""
end

function XCharacterCuteConfig.GetCuteModelSmallHeadIconByRobotId(robotId)
    local characterId = XRobotManager.GetCharacterId(robotId)
    local icon = XCharacterCuteConfig.GetCuteModelSmallHeadIcon(characterId)
    return icon
end

function XCharacterCuteConfig.GetCuteModelHalfBodyImage(characterId)
    return GetCuteModelConfig(characterId).HalfBodyImage or ""
end

function XCharacterCuteConfig.GetModelRandomAction(modelName)
    return {}
end

function XCharacterCuteConfig.GetCharacterIdByNpcId(npcId)
    return _CharacterTab[npcId]
end

function XCharacterCuteConfig.CheckHasCuteModel(characterId)
    return _CharacterCuteConfig[characterId]
end

function XCharacterCuteConfig.GetEffectInfo(characterId, actionId)
    if not XTool.IsNumberValid(characterId) then
        XLog.Error(string.format("XCharacterCuteConfig.GetEffectInfo出错，必须参数存在空值,characterId: %s", tostring(characterId)))
        return nil
    end
    local character = EffectDictionary[characterId]
    if not character then
        return nil
    end
    local cfg
    if actionId then
        cfg = character[actionId]
    else
        cfg = character.DefaultEffect
    end
    if not cfg then
        return nil
    end
    return cfg.Id, cfg.EffectRootName, cfg.EffectPath
end

-- Q版角色默认显示控制器
function XCharacterCuteConfig.GetNeedDisplayController(stageId)
    -- 冰雪感谢祭 不加载控制器
    if XFubenSpecialTrainConfig.CheckIsSnowGameStage(stageId) then
        return false
    end
    return true
end