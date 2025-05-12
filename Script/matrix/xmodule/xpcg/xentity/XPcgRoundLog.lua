---@class XPcgRoundLog
local XPcgRoundLog = XClass(nil, "XPcgRoundLog")

function XPcgRoundLog:Ctor(roundId)
    self.RoundId = roundId
    ---@type XPcgEffectSettle[]
    self.CommanderEffectSettles = {}    -- 指挥官
    ---@type XPcgEffectSettle[]
    self.MonsterEffectSettles = {}      -- 怪物
end

function XPcgRoundLog:AddCommanderEffectSettles(datas)
    for _, data in ipairs(datas) do
        table.insert(self.CommanderEffectSettles, data)
    end
end

function XPcgRoundLog:AddMonsterEffectSettles(datas)
    for _, data in ipairs(datas) do
        table.insert(self.MonsterEffectSettles, data)
    end
end

function XPcgRoundLog:GetRoundId()
    return self.RoundId
end

---@return XPcgEffectSettle[]
function XPcgRoundLog:GetCommanderEffectSettles()
    return self.CommanderEffectSettles
end

---@return XPcgEffectSettle[]
function XPcgRoundLog:GetMonsterEffectSettles()
    return self.MonsterEffectSettles
end

return XPcgRoundLog