local type = type
local pairs = pairs

--[[
public class XMonsterCombatFormation
{
    // 章节id
    public int ChapterId;
    // 角色id
    public int CharacterId;
    // 试玩机器人id
    public int RobotId;
    // 怪物id列表
    public List<int> MonsterIds;
}
]]

local Default = {
    _ChapterId = 0, -- 章节id
    _CharacterId = 0, -- 角色id
    _RobotId = 0, -- 试玩机器人id
    _MonsterIds = {} -- 怪物id列表
}

---@class XMonsterCombatFormation
---@field _ChapterId number
---@field _CharacterId number
---@field _RobotId number
---@field _MonsterIds number[]
local XMonsterCombatFormation = XClass(nil, "XMonsterCombatFormation")

function XMonsterCombatFormation:Ctor(data)
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

function XMonsterCombatFormation:UpdateData(data)
    self._ChapterId = data.ChapterId
    self._CharacterId = data.CharacterId
    self._RobotId = data.RobotId
    self._MonsterIds = data.MonsterIds
end

function XMonsterCombatFormation:GetCharacterId()
    return self._CharacterId
end

function XMonsterCombatFormation:GetRobotId()
    return self._RobotId
end

function XMonsterCombatFormation:GetMonsterIds()
    return self._MonsterIds
end

return XMonsterCombatFormation