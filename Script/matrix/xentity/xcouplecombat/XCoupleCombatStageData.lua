local type = type
local pairs = pairs

local Default = {
    _StageId = 0,       --关卡id
    _CharacterIds = {}, --关卡上阵成员id
}

--关卡数据
local XCoupleCombatStageData = XClass(nil, "XCoupleCombatStageData")

function XCoupleCombatStageData:Ctor()
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end
end

function XCoupleCombatStageData:UpdateData(data)
    self._StageId = data.StageId
    self._CharacterIds = data.CharacterIds
end

function XCoupleCombatStageData:ResetMember()
    self._CharacterIds = {}
end

function XCoupleCombatStageData:GetStageId()
    return self._StageId
end

function XCoupleCombatStageData:GetCharacterIds()
    return self._CharacterIds
end

return XCoupleCombatStageData