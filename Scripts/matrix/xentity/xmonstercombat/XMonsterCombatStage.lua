local type = type
local pairs = pairs

--[[
public class XMonsterCombatStage
{
    // 关卡id
    public int StageId;
    // 最高分数
    public int MaxScore;
}
]]

local Default = {
    _StageId = 0, -- 关卡id
    _MaxScore = 0, -- 最高分数
}

---@class XMonsterCombatStage
---@field _StageId number
---@field _MaxScore number
local XMonsterCombatStage = XClass(nil, "XMonsterCombatStage")

function XMonsterCombatStage:Ctor(data)
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end

    if data then
        self:UpdateData(data)
    end
end

function XMonsterCombatStage:UpdateData(data)
    self._StageId = data.StageId
    self._MaxScore = data.MaxScore
end

function XMonsterCombatStage:GetMaxScore()
    return self._MaxScore
end

return XMonsterCombatStage