local type = type

local Default = {
    _Id = 0,
    _IsUnlock = false,
}

local XPokemonMonsterSkill = XClass(nil, "XPokemonMonsterSkill")

function XPokemonMonsterSkill:Ctor(id)
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end

    self._Id = id
end

function XPokemonMonsterSkill:IsUnlock()
    return self._IsUnlock or false
end

function XPokemonMonsterSkill:Unlock(value)
    self._IsUnlock = true
end

return XPokemonMonsterSkill