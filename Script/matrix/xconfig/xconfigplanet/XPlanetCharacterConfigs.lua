XPlanetCharacterConfigs = XPlanetCharacterConfigs or {}
local XPlanetCharacterConfigs = XPlanetCharacterConfigs

XPlanetCharacterConfigs.ATTR = {
    Life = 1,
    MaxLife = 2,
    Attack = 3,
    Defense = 4,
    CriticalChance = 5,
    CriticalDamage = 6,
    AttackSpeed = 7,
}

---@type XConfig
local _ConfigCharacter

---@type XConfig
local _ConfigAttr

---@type XConfig
local _ConfigBaseAttr

function XPlanetCharacterConfigs.Init()
    --_ConfigAttr = XConfig.New("Client/PlanetRunning/PlanetRunningAttr.tab", XTable.XTablePlanetRunningAttr, "Id")
    --_ConfigBaseAttr = XConfig.New("Share/PlanetRunning/PlanetRunningFightingGrowUp.tab", XTable.XTablePlanetRunningFightingGrowUp, "Name")
end

function XPlanetCharacterConfigs._GetConfigCharacter()
    if not _ConfigCharacter then
        _ConfigCharacter = XConfig.New("Share/PlanetRunning/PlanetRunningCharacter.tab", XTable.XTablePlanetRunningCharacter, "Id")
    end
    return _ConfigCharacter
end

function XPlanetCharacterConfigs.GetCharacterModel(characterId)
    return XPlanetCharacterConfigs._GetConfigCharacter():GetProperty(characterId, "Model")
end

function XPlanetCharacterConfigs.CheckHasCharacter(characterId)
    return _ConfigCharacter:GetConfigs()[characterId]
end 

function XPlanetCharacterConfigs.GetCharacterEvents(characterId)
    return XPlanetCharacterConfigs._GetConfigCharacter():GetProperty(characterId, "Events")
end

function XPlanetCharacterConfigs.GetCharacterName(characterId)
    return XPlanetCharacterConfigs._GetConfigCharacter():GetProperty(characterId, "Name")
end

function XPlanetCharacterConfigs.GetCharacterStory(characterId)
    local text = XPlanetCharacterConfigs._GetConfigCharacter():GetProperty(characterId, "Story")
    return XUiHelper.ReplaceTextNewLine(text)
end

function XPlanetCharacterConfigs.GetCharacterFrom(characterId)
    return XPlanetCharacterConfigs._GetConfigCharacter():GetProperty(characterId, "From")
end

function XPlanetCharacterConfigs.GetCharacterIcon(characterId)
    return XPlanetCharacterConfigs._GetConfigCharacter():GetProperty(characterId, "Icon")
end

function XPlanetCharacterConfigs.GetAllCharacter()
    return XPlanetCharacterConfigs._GetConfigCharacter():GetConfigs()
end

function XPlanetCharacterConfigs.GetCharacterPriority(characterId)
    return XPlanetCharacterConfigs._GetConfigCharacter():GetProperty(characterId, "Sorting")
end

function XPlanetCharacterConfigs.GetCharacterDefaultUnlock(characterId)
    return XPlanetCharacterConfigs._GetConfigCharacter():GetProperty(characterId, "DefaultUnlock")
end

function XPlanetCharacterConfigs.GetCharacterLockDesc(characterId)
    return XPlanetCharacterConfigs._GetConfigCharacter():GetProperty(characterId, "LockDesc")
end

function XPlanetCharacterConfigs.GetCharacterAttrId(characterId)
    return XPlanetCharacterConfigs._GetConfigCharacter():GetProperty(characterId, "NpcAttributeId")
end

function XPlanetCharacterConfigs.GetAttrName(key)
    return _ConfigAttr:GetProperty(key, "Name")
end

function XPlanetCharacterConfigs.GetAttrValue4Ui(attrType, value)
    if attrType == XPlanetCharacterConfigs.ATTR.AttackSpeed
            or attrType == XPlanetCharacterConfigs.ATTR.CriticalChance
            or attrType == XPlanetCharacterConfigs.ATTR.CriticalDamage
    then
        return string.format("%.1f%%", value / 100)
    end
    return value
end

function XPlanetCharacterConfigs.GetAllAttr()
    local allAttr = _ConfigAttr:GetConfigs()
    local result = {}
    for i, config in pairs(allAttr) do
        if not string.IsNilOrEmpty(config.Desc) then
            result[#result + 1] = {
                Name = config.Name,
                Desc = config.Desc
            }
        end
    end
    return result
end

function XPlanetCharacterConfigs.GetBaseSpeed()
    local params = _ConfigBaseAttr:TryGetProperty("AttackSpeed", "Params") or {}
    return params[1] or 0
end
