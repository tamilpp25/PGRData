local type = type
local pairs = pairs

local Default = {
    _Pos = 0,
    _IsLock = true,
    _MonsterId = 0,
}

local XPokemonTeamPosData = XClass(nil, "XPokemonTeamPosData")

function XPokemonTeamPosData:Ctor(pos)
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end

    self._Pos = pos
end

function XPokemonTeamPosData:IsLock()
    return self._IsLock
end

function XPokemonTeamPosData:Unlock()
    self._IsLock = false
end

function XPokemonTeamPosData:SetMonsterId(monsterId)
    self._MonsterId = monsterId or 0
end

function XPokemonTeamPosData:GetMonsterId()
    return self._MonsterId
end

return XPokemonTeamPosData