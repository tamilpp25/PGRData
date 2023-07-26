local XTeam = require("XEntity/XTeam/XTeam")
---@class XMonsterTeam : XTeam
local XMonsterTeam = XClass(XTeam, "XMonsterTeam")

function XMonsterTeam:Ctor()
    -- 怪物信息 XTeam的Ctor有加载本地信息处理，这里不能直接初始化 
    self.MonsterIds = self.MonsterIds or { 0, 0 }
end

function XMonsterTeam:GetSaveKey()
    return string.format("MonsterTeam_%s_%s", XPlayer.Id, self:GetId())
end

function XMonsterTeam:_Save()
    if self.LocalSave then
        XSaveTool.SaveData(self:GetSaveKey(), {
            Id = self.Id,
            EntitiyIds = self.EntitiyIds,
            FirstFightPos = self.FirstFightPos,
            CaptainPos = self.CaptainPos,
            MonsterIds = self.MonsterIds
        })
    end
    if self.SaveCallback then
        self.SaveCallback(self)
    end
end

function XMonsterTeam:GetMonsterIdByPos(pos)
    return self.MonsterIds[pos] or 0
end

function XMonsterTeam:GetMonsterIds()
    return self.MonsterIds
end

function XMonsterTeam:UpdateMonsterPos(monsterId, pos, isJoin)
    if isJoin then
        self.MonsterIds[pos] = monsterId or 0
    else
        for i, id in pairs(self.MonsterIds) do
            if id == monsterId then
                self.MonsterIds[i] = 0
                break
            end
        end
    end
    self:Save()
end

function XMonsterTeam:UpdateMonsterIds(monsters)
    for pos, monsterId in pairs(monsters) do
        self.MonsterIds[pos] = monsterId
    end
    self:Save()
end

function XMonsterTeam:GetMonsterIsEmpty()
    for _, v in ipairs(self.MonsterIds) do
        if v ~= 0 then
            return false
        end
    end
    return true
end

function XMonsterTeam:GetMonsterIdIsInTeam(monsterId)
    return table.contains(self.MonsterIds, monsterId)
end

-- 排序规则：不等于0的优先
function XMonsterTeam:MonsterSort()
    table.sort(self.MonsterIds, function(a, b)
        local weightA = a > 0 and 10 or 0
        local weightB = b > 0 and 10 or 0
        return weightA > weightB
    end)
end

function XMonsterTeam:Clear()
    self.EntitiyIds = { 0, 0, 0 }
    self.FirstFightPos = 1
    self.CaptainPos = 1
    self.MonsterIds = { 0, 0 }
    self:Save()
end

function XMonsterTeam:ClearMonsterIds()
    self.MonsterIds = { 0, 0 }
    self:Save()
end

return XMonsterTeam