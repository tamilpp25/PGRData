---@class XDlcHuntModel
local XDlcHuntModel = XClass(nil, "XDlcHuntModel")

function XDlcHuntModel:Ctor()
    self._CharacterId = false
    self._IsDirty = true
end

---@param member XDlcHuntMember
function XDlcHuntModel:SetDataByMember(member)
    local characterId = member:GetCharacterId()
    if self._CharacterId == characterId then
        return
    end
    self._IsDirty = true
    self._CharacterId = characterId
end

---@param character XDlcHuntCharacter
function XDlcHuntModel:SetDataByCharacter(character)
    local characterId = character:GetCharacterId()
    if self._CharacterId == characterId then
        return
    end
    self._IsDirty = true
    self._CharacterId = characterId
end

function XDlcHuntModel:GetCharacterId()
    return self._CharacterId
end

function XDlcHuntModel:GetModelId()
    local characterId = self:GetCharacterId()
    return XDlcHuntCharacterConfigs.GetCharacterModelId(characterId)
end

function XDlcHuntModel:GetWeaponId()
    local characterId = self:GetCharacterId()
    return XDlcHuntCharacterConfigs.GetCharacterWeaponId(characterId) 
end

function XDlcHuntModel:IsDirty()
    return self._IsDirty
end

function XDlcHuntModel:ClearDirty()
    self._IsDirty = false
end

function XDlcHuntModel:SetDirty()
    self._IsDirty = true
end

return XDlcHuntModel