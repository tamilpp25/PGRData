XCharacterUiEffectConfig = XCharacterUiEffectConfig or {}
local TABLE_CHARACTER_UI_EFFECT = "Client/Character/CharacterUiEffect.tab"
local TABLE_CHARACTER_UI_EQUIP_EFFECT = "Client/Character/CharacterUiEquipEffect.tab"
local EffectDictionary = {}
local EquipEffectDict = {}

local DefaultRootName = "Root" --默认父节点名

function XCharacterUiEffectConfig.Init()
    EffectDictionary = {}
    local defaultActionId = "DefaultEffect"
    local tabCharacterUiEffect = XTableManager.ReadByIntKey(TABLE_CHARACTER_UI_EFFECT, XTable.XTableCharacterUiEffect, "Id")
    for _, template in pairs(tabCharacterUiEffect) do
        if not template.FashionId then
            XLog.Error(string.format("CharacterUiEffect表出错！存在没有填FashionId的数据！表地址:" .. TABLE_CHARACTER_UI_EFFECT))
        end

        if XTool.IsTableEmpty(template.EffectPath) then
            XLog.Error(string.format("CharacterUiEffect表出错！存在没有填EffectPath的数据！表地址:" .. TABLE_CHARACTER_UI_EFFECT .. "Id:" .. template.Id))
        end
        
        local fashionTemplate = XFashionConfigs.GetFashionTemplate(template.FashionId)
        local characterId = fashionTemplate.CharacterId
        EffectDictionary[characterId] = EffectDictionary[characterId] or {}
        EffectDictionary[characterId][template.FashionId] = EffectDictionary[characterId][template.FashionId] or {}
        local actionId = template.ActionId or defaultActionId
        
        local tempConfig = EffectDictionary[characterId][template.FashionId][actionId]
        if not tempConfig then
            tempConfig = {}
            tempConfig.ActionId = actionId
            tempConfig.FashionId = template.FashionId
            tempConfig.Id = template.Id
            tempConfig.EffectRootName = {}
            tempConfig.EffectPath = {}
        end
        local effectLength = #tempConfig.EffectPath + 1
        tempConfig.EffectPath[effectLength] = template.EffectPath
        tempConfig.EffectRootName[effectLength] = template.EffectRootName or DefaultRootName
        EffectDictionary[characterId][template.FashionId][actionId] = tempConfig
        
    end
    EquipEffectDict = {}
    local tabEquipEffect = XTableManager.ReadByIntKey(TABLE_CHARACTER_UI_EQUIP_EFFECT, XTable.XTableCharacterUiEquipEffect, "Id")
    for id, template in pairs(tabEquipEffect) do
        if not template.FashionId then
            XLog.Error(string.format("CharacterUiEffect表出错！存在没有填FashionId的数据！表地址:%s Id = %s", TABLE_CHARACTER_UI_EQUIP_EFFECT, id))
        end

        if not template.EquipModelId then
            XLog.Error(string.format("CharacterUiEffect表出错！存在没有填EquipModelId的数据！表地址:%s Id = %s", TABLE_CHARACTER_UI_EQUIP_EFFECT, id))
        end
        local fashionId = template.FashionId or XWeaponFashionConfigs.DefaultWeaponFashionId
        local equipId = template.EquipModelId
        EquipEffectDict[equipId] = EquipEffectDict[equipId] or {}
        EquipEffectDict[equipId][fashionId] = EquipEffectDict[equipId][fashionId] or {}
        
        local actionId = template.ActionId or defaultActionId
        
        EquipEffectDict[equipId][fashionId][actionId] = EquipEffectDict[equipId][fashionId][actionId] or {}
        table.insert(EquipEffectDict[equipId][fashionId][actionId], template)
    end

    --if XMain.IsDebug then
    --    for characterId, dict1 in pairs(EffectDictionary) do
    --        for fashionId, dict2 in pairs(dict1) do
    --            for actionId, mergedTable in pairs(dict2)do
    --                local usedRoot = {}
    --                for i = 1, #mergedTable.EffectPath do
    --                    local rootName = mergedTable.EffectRootName[i] or DefaultRootName
    --                    if not usedRoot[rootName] then
    --                        usedRoot[rootName] = true
    --                    else
    --                        XLog.Error("CharacterUiEffect表出错！同一动作不能有重复的EffectRootName数据项！首项Id: " .. mergedTable.Id)
    --                    end
    --                end
    --            end
    --        end
    --    end
    --end
end

function XCharacterUiEffectConfig.GetEffectInfo(characterId, fashionId, actionId)
    if not characterId or not fashionId then
        XLog.Error(string.format("XCharacterUiEffectConfig.GetEffectInfo出错，必须参数存在空值,characterId: %s,fashionId: %s",
                tostring(characterId), tostring(fashionId)))
        return nil
    end
    local character = EffectDictionary[characterId]
    if not character then
        --XLog.ErrorTableDataNotFound("XCharacterUiEffectConfig.GetEffectInfo", "Ui角色动作特效", TABLE_CHARACTER_UI_EFFECT, "CharacterId", tostring(characterId))
        return nil
    end
    local fashion = character[fashionId]
    if not fashion then
        --XLog.ErrorTableDataNotFound("XCharacterUiEffectConfig.GetEffectInfo", "Ui角色动作特效", TABLE_CHARACTER_UI_EFFECT, "FashionId", tostring(fashionId))
        return nil
    end
    local cfg
    if actionId then
        cfg = fashion[actionId]
    else
        cfg = fashion.DefaultEffect
    end
    if not cfg then
        return nil
    end
    return cfg.Id, cfg.EffectRootName, cfg.EffectPath
end

function XCharacterUiEffectConfig.GetEquipEffectInfo(weaponModelId, fashionId, actionId)
    if not XTool.IsNumberValid(weaponModelId) then
        XLog.Error("获取装备特效信息出错: EquipModelId 为空")
        return
    end
    fashionId = fashionId or XWeaponFashionConfigs.DefaultWeaponFashionId
    
    local equip = EquipEffectDict[weaponModelId]
    if not equip then
        return
    end
    
    local fashion = equip[fashionId]
    if not fashion then
        return
    end
    
    local template
    if actionId then
        template = fashion[actionId]
    else
        template = fashion.DefaultEffect
    end
    if not template then
        return
    end
    local idList, name2EffectMap = {}, {}
    for _, temp in ipairs(template or {}) do
        table.insert(idList, temp.Id)
        local rootName = temp.EffectRootName or DefaultRootName
        name2EffectMap[rootName] = temp.EffectPath
    end
    return table.concat(idList, "-"), name2EffectMap
end 

function XCharacterUiEffectConfig.GetDefaultRootName()
    return DefaultRootName
end 