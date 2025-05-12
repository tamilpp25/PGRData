---@class XTheatre4Talent
local XTheatre4Talent = XClass(nil, "XTheatre4Talent")

function XTheatre4Talent:Ctor()
    -- 天赋Id
    self.TalentId = 0
    -- 效果集
    ---@type table<number, XTheatre4Effect>
    self.Effects = {}
end

function XTheatre4Talent:NotifyTalentData(data)
    self.TalentId = data.TalentId or 0
    self:UpdateEffects(data.Effects)
end

function XTheatre4Talent:UpdateEffects(data)
    self.Effects = {}
    if not data then
        return
    end
    for _, v in pairs(data) do
        self:AddEffect(v)
    end
end

function XTheatre4Talent:AddEffect(data)
    if not data then
        return
    end
    ---@type XTheatre4Effect
    local effect = self.Effects[data.Id]
    if not effect then
        effect = require("XModule/XTheatre4/XEntity/XTheatre4Effect").New()
        self.Effects[data.Id] = effect
    end
    effect:NotifyEffectData(data)
end

-- 获取天赋Id
function XTheatre4Talent:GetTalentId()
    return self.TalentId
end

-- 获取效果集
---@return table<number, XTheatre4Effect>
function XTheatre4Talent:GetEffects()
    return self.Effects
end

return XTheatre4Talent
