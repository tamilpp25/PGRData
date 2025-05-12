-- 天赋档位
---@class XTheatre4ColorTalentSlot
local XTheatre4ColorTalentSlot = XClass(nil, "XTheatre4ColorTalentSlot")

function XTheatre4ColorTalentSlot:Ctor()
    -- 天赋槽位Id
    self.SlotId = 0
    -- 天赋列表
    ---@type table<number, XTheatre4Talent>
    self.Talents = {}
end

-- 服务端通知
function XTheatre4ColorTalentSlot:NotifySlotData(data)
    self.SlotId = data.SlotId or 0
    self:UpdateTalents(data.Talents)
end

function XTheatre4ColorTalentSlot:UpdateTalents(data)
    self.Talents = {}
    if not data then
        return
    end
    for _, v in pairs(data) do
        self:AddTalent(v)
    end
end

function XTheatre4ColorTalentSlot:AddTalent(data)
    if not data then
        return
    end
    ---@type XTheatre4Talent
    local talent = self.Talents[data.TalentId]
    if not talent then
        talent = require("XModule/XTheatre4/XEntity/XTheatre4Talent").New()
        self.Talents[data.TalentId] = talent
    end
    talent:NotifyTalentData(data)
end

-- 获取天赋档位Id
function XTheatre4ColorTalentSlot:GetSlotId()
    return self.SlotId
end

-- 获取天赋列表
---@return table<number, XTheatre4Talent>
function XTheatre4ColorTalentSlot:GetTalents()
    return self.Talents
end

-- 获取天赋Ids
function XTheatre4ColorTalentSlot:GetTalentIds()
    local ids = {}
    for id, _ in pairs(self.Talents) do
        table.insert(ids, id)
    end
    return ids
end

-- 获取所有的效果
function XTheatre4ColorTalentSlot:GetAllEffects()
    local effects = {}
    for _, talent in pairs(self.Talents) do
        for index, effect in pairs(talent:GetEffects()) do
            effects[index] = effect
        end
    end
    return effects
end

return XTheatre4ColorTalentSlot
