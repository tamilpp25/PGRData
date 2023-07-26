XDlcHuntCharacterConfigs = XDlcHuntCharacterConfigs or {}

---@type XConfig
local _ConfigElement

---@type XConfig
local _ConfigCharacter

---@type XConfig
local _ConfigDetail

function XDlcHuntCharacterConfigs.Init()
    _ConfigElement = XConfig.New("Client/DlcHunt/DlcHuntElement.tab", XTable.XTableDlcHuntElement, "Id")
    _ConfigCharacter = XConfig.New("Share/DlcHunt/Character/DlcHuntCharacter.tab", XTable.XTableDlcHuntCharacter, "Id")
    _ConfigDetail = XConfig.New("Client/DlcHunt/Character/DlcHuntCharacterDetail.tab", XTable.XTableDlcHuntCharacterDetail, "Id")
end

--region character
function XDlcHuntCharacterConfigs.GetAllCharacterId()
    local list = {}
    for id, config in pairs(_ConfigCharacter:GetConfigs()) do
        list[#list + 1] = id
    end
    table.sort(list, function(a, b)
        return XDlcHuntCharacterConfigs.GetCharacterPriority(a) < XDlcHuntCharacterConfigs.GetCharacterPriority(b)
    end)
    return list
end

function XDlcHuntCharacterConfigs.GetCharacterName(characterId)
    return _ConfigCharacter:GetProperty(characterId, "Name")
end

function XDlcHuntCharacterConfigs.GetCharacterNameEn(characterId)
    return _ConfigCharacter:GetProperty(characterId, "EnName")
end

function XDlcHuntCharacterConfigs.GetCharacterIcon(characterId)
    return _ConfigCharacter:GetProperty(characterId, "Icon")
end

function XDlcHuntCharacterConfigs.GetCharacterHalfBodyImage(characterId)
    return _ConfigCharacter:GetProperty(characterId, "HalfBodyImage")
end

function XDlcHuntCharacterConfigs.GetCharacterPriority(characterId)
    return _ConfigCharacter:GetProperty(characterId, "Priority")
end

function XDlcHuntCharacterConfigs.GetCharacterElement(characterId)
    return _ConfigCharacter:GetProperty(characterId, "Element")
end

function XDlcHuntCharacterConfigs.GetCharacterNpcId(characterId)
    return _ConfigCharacter:GetProperty(characterId, "NpcId")
end

function XDlcHuntCharacterConfigs.GetCharacterIdByNpcId(npcId)
    local configs = _ConfigCharacter:GetConfigs()
    for characterId, config in pairs(configs) do
        if config.NpcId == npcId then
            return config.Id
        end
    end
    return false
end

function XDlcHuntCharacterConfigs.GetCharacterModelId(characterId)
    local fashionId = XDlcHuntCharacterConfigs.GetFashionId(characterId)
    local resourcesId = XDataCenter.FashionManager.GetResourcesId(fashionId)
    local model = XDataCenter.CharacterManager.GetCharResModel(resourcesId)
    return model
end

function XDlcHuntCharacterConfigs.GetCharacterWeaponId(characterId)
    return _ConfigCharacter:GetProperty(characterId, "EquipId")
end

function XDlcHuntCharacterConfigs.GetFashionId(characterId)
    return _ConfigCharacter:GetProperty(characterId, "DefaultNpcFashionId")
end

function XDlcHuntCharacterConfigs.GetCharacterAttribId(characterId)
    return _ConfigCharacter:GetProperty(characterId, "AttribId")
end

function XDlcHuntCharacterConfigs.GetCharacterAttrTable(characterId)
    local attribId = XDlcHuntCharacterConfigs.GetCharacterAttribId(characterId)
    return XDlcHuntAttrConfigs.GetAttrTable(attribId)
end

-- 仅装饰用
function XDlcHuntCharacterConfigs.GetCharacterCode(characterId)
    return _ConfigCharacter:GetProperty(characterId, "Code")
end
--endregion character

--region element
function XDlcHuntCharacterConfigs.GetCharacterElementIconList(characterId)
    local list = {}
    local elementList = XDlcHuntCharacterConfigs.GetCharacterElement(characterId)
    for i = 1, #elementList do
        local elementId = elementList[i]
        list[#list + 1] = _ConfigElement:GetProperty(elementId, "Icon")
    end
    return list
end
--endregion element

--region detail
function XDlcHuntCharacterConfigs.GetCharacterWeaponName(characterId)
    return _ConfigDetail:GetProperty(characterId, "WeaponName")
end

function XDlcHuntCharacterConfigs.GetCharacterWeaponIcon(characterId)
    return _ConfigDetail:GetProperty(characterId, "WeaponPath")
end

function XDlcHuntCharacterConfigs.GetCharacterElementName(characterId)
    return _ConfigDetail:GetProperty(characterId, "ElementName")
end

function XDlcHuntCharacterConfigs.GetCharacterElementIcon(characterId)
    return _ConfigDetail:GetProperty(characterId, "ElementPath")
end
--endregion detail