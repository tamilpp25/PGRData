XCharacterUiEffectConfig = XCharacterUiEffectConfig or {}
local TABLE_CHARACTER_UI_EFFECT = "Client/Character/CharacterUiEffect.tab"
local TABLE_FASHION = "Share/Fashion/Fashion.tab"
local CharacterUiEffectTable = {}
local EffectDictionary = {}
function XCharacterUiEffectConfig.Init()
    EffectDictionary = {}
    CharacterUiEffectTable = XTableManager.ReadByIntKey(TABLE_CHARACTER_UI_EFFECT, XTable.XTableCharacterUiEffect, "Id")
    local FashionTemplates = XTableManager.ReadByIntKey(TABLE_FASHION, XTable.XTableFashion, "Id")
    for _, v in pairs(CharacterUiEffectTable) do
        if not v.FashionId then
            XLog.Error(string.format("CharacterUiEffect表出错！存在没有填FashionId的数据！表地址:" .. TABLE_CHARACTER_UI_EFFECT))
        end
        if not v.EffectPath then
            XLog.Error(string.format("CharacterUiEffect表出错！存在没有填EffectPath的数据！表地址:" .. TABLE_CHARACTER_UI_EFFECT .. "Id:" .. v.Id))
        end
        local fashionTemplate = FashionTemplates[v.FashionId]
        if not fashionTemplate then
            XLog.ErrorTableDataNotFound("CharacterUiEffectConfig.Init", "Fashion", TABLE_FASHION, "fashionId", tostring(v.FashionId))
            return
        end
        local characterId = fashionTemplate.CharacterId
        local character = EffectDictionary[characterId]
        if not character then
            EffectDictionary[characterId] = {}
            character = EffectDictionary[characterId]
        end
        local fashion = character[v.FashionId]
        if not fashion then
            character[v.FashionId] = {}
            fashion = character[v.FashionId]
        end
        if v.ActionId then
            fashion[v.ActionId] = v
        else
            if not fashion.DefaultEffect then
                fashion.DefaultEffect = v
            else
                XLog.Error("CharacterUiEffect表出错！一个FashionId只能有一个不填写ActionId的数据项！FashionId: " .. v.FashionId)
            end
        end
    end
end

function XCharacterUiEffectConfig.GetCharacterUiEffectById(id)
    return CharacterUiEffectTable[id]
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