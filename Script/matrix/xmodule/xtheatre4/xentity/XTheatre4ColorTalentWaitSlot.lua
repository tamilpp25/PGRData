---@class XTheatre4ColorTalentWaitSlot
local XTheatre4ColorTalentWaitSlot = XClass(nil, "XTheatre4ColorTalentWaitSlot")

function XTheatre4ColorTalentWaitSlot:Ctor()
    -- 天赋槽位Id
    self.SlotId = 0
    -- 天赋Ids
    ---@type number[]
    self.TalentIds = {}
    -- 免费刷新次数
    self.RefreshFreeTimes = 0
    -- 刷新上限
    self.RefreshLimit = 0
    -- 剩余刷新次数
    self.RefreshTimes = 0
end

function XTheatre4ColorTalentWaitSlot:NotifyWaitSlotData(data)
    self.SlotId = data.SlotId or 0
    self.TalentIds = data.TalentIds or {}
    self.RefreshFreeTimes = data.RefreshFreeTimes or 0
    self.RefreshLimit = data.RefreshLimit or 0
    self.RefreshTimes = data.RefreshTimes or 0
end

-- 获取槽位Id
function XTheatre4ColorTalentWaitSlot:GetSlotId()
    return self.SlotId
end

-- 获取天赋Ids
function XTheatre4ColorTalentWaitSlot:GetTalentIds()
    return self.TalentIds
end

-- 获取免费刷新次数
function XTheatre4ColorTalentWaitSlot:GetRefreshFreeTimes()
    return self.RefreshFreeTimes
end

-- 获取刷新上限
function XTheatre4ColorTalentWaitSlot:GetRefreshLimit()
    return self.RefreshLimit
end

-- 获取剩余刷新次数
function XTheatre4ColorTalentWaitSlot:GetRefreshTimes()
    return self.RefreshTimes
end

return XTheatre4ColorTalentWaitSlot
