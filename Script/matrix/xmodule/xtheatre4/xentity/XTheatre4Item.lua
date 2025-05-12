-- 物品
---@class XTheatre4Item
local XTheatre4Item = XClass(nil, "XTheatre4Item")

function XTheatre4Item:Ctor()
    -- 唯一ID
    self.Uid = 0
    -- 玩法物品id
    self.ItemId = 0
    -- 附带效果
    ---@type table<number, XTheatre4Effect>
    self.Effects = {}
    -- 剩余持续天数
    self.LeftDays = -1
end

-- 服务端通知
function XTheatre4Item:NotifyItemData(data)
    self.Uid = data.Uid or 0
    self.ItemId = data.ItemId or 0
    self:UpdateEffects(data.Effects)
    self.LeftDays = data.LeftDays or -1
end

function XTheatre4Item:UpdateEffects(data)
    self.Effects = {}
    if not data then
        return
    end
    for _, v in pairs(data) do
        self:AddEffect(v)
    end
end

function XTheatre4Item:AddEffect(data)
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

-- 获取唯一ID
function XTheatre4Item:GetUid()
    return self.Uid
end

-- 获取玩法物品id
function XTheatre4Item:GetItemId()
    return self.ItemId
end

-- 获取效果集
---@return table<number, XTheatre4Effect>
function XTheatre4Item:GetEffects()
    return self.Effects
end

-- 获取剩余持续天数 -1 为永久
function XTheatre4Item:GetLeftDays()
    return self.LeftDays
end

return XTheatre4Item
