local type = type

--大逃杀角色/机器人状态
---@class XEscapeCharacterState
local XEscapeCharacterState = XClass(nil, "XEscapeCharacterState")

local Default = {
    _CharacterId = 0,
    _LifePermyriad = 0,     --剩余生命（万分比）
    _EnergyPermyriad = 0,   --剩余能量（万分比）
}

function XEscapeCharacterState:Ctor()
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end
end

function XEscapeCharacterState:UpdateData(data)
    self._CharacterId = data.CharacterId
    self._LifePermyriad = data.LifePermyriad
    self._EnergyPermyriad = data.EnergyPermyriad
end

function XEscapeCharacterState:GetCharacterId()
    return self._CharacterId
end

function XEscapeCharacterState:GetLifePermyriadPercent()
    return self._LifePermyriad / 10000
end

function XEscapeCharacterState:GetEnergyPermyriadPercent()
    return self._EnergyPermyriad / 10000
end

return XEscapeCharacterState