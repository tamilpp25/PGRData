-- 颜色属性
---@class XTheatre4ColorTalent
local XTheatre4ColorTalent = XClass(nil, "XTheatre4ColorTalent")

function XTheatre4ColorTalent:Ctor()
    -- 颜色
    self.Color = 0
    -- 颜色等级
    self.Level = 1
    -- 颜色资源
    self.Resource = 0
    -- 颜色资源(红色买死值)
    self.PointCanCost = 0
    -- 日获得资源
    self.DailyResource = 0
    -- 颜色天赋点
    self.Point = 0
    -- 已激活天赋档位集
    ---@type table<number, XTheatre4ColorTalentSlot>
    self.Slots = {}
    -- 待处理天赋档位
    ---@type XTheatre4ColorTalentWaitSlot
    self.WaitSlot = false
end

-- 服务端通知
function XTheatre4ColorTalent:NotifyColorData(data)
    self.Color = data.Color or 0
    self.Level = data.Level or 1
    self.Resource = data.Resource or 0
    self.PointCanCost = data.PointCanCost or 0
    self.DailyResource = data.DailyResource or 0
    self.Point = data.Point or 0
    self:UpdateSlots(data.Slots)
    self:UpdateWaitSlot(data.WaitSlot)
end

function XTheatre4ColorTalent:UpdateSlots(data)
    self.Slots = {}
    if not data then
        return
    end
    for _, v in pairs(data) do
        self:AddSlot(v)
    end
end

function XTheatre4ColorTalent:AddSlot(data)
    if not data then
        return
    end
    ---@type XTheatre4ColorTalentSlot
    local slot = self.Slots[data.SlotId]
    if not slot then
        slot = require("XModule/XTheatre4/XEntity/XTheatre4ColorTalentSlot").New()
        self.Slots[data.SlotId] = slot
    end
    slot:NotifySlotData(data)
end

function XTheatre4ColorTalent:UpdateWaitSlot(data)
    if not data then
        self.WaitSlot = false
        return
    end
    if not self.WaitSlot then
        self.WaitSlot = require("XModule/XTheatre4/XEntity/XTheatre4ColorTalentWaitSlot").New()
    end
    self.WaitSlot:NotifyWaitSlotData(data)
end

-- 修改颜色资源
function XTheatre4ColorTalent:SetResource(resource)
    self.Resource = resource
end

-- 修改颜色资源(红色买死值)
function XTheatre4ColorTalent:SetPointCanCost(pointCanCost)
    self.PointCanCost = pointCanCost
end

-- 修改颜色等级
function XTheatre4ColorTalent:SetLevel(level)
    self.Level = level
end

-- 修改日获得资源
function XTheatre4ColorTalent:SetDailyResource(dailyResource)
    self.DailyResource = dailyResource
end

-- 修改颜色天赋点
function XTheatre4ColorTalent:SetPoint(point)
    self.Point = point
end

-- 获取颜色
function XTheatre4ColorTalent:GetColor()
    return self.Color
end

-- 获取颜色等级
function XTheatre4ColorTalent:GetLevel()
    return self.Level
end

-- 获取颜色资源
function XTheatre4ColorTalent:GetResource()
    return self.Resource
end

function XTheatre4ColorTalent:GetPointCanCost()
    return self.PointCanCost
end

-- 获取日获得资源
function XTheatre4ColorTalent:GetDailyResource()
    return self.DailyResource
end

-- 获取颜色天赋点
function XTheatre4ColorTalent:GetPoint()
    return self.Point
end

---@return XTheatre4ColorTalentSlot[]
function XTheatre4ColorTalent:GetSlots()
    return self.Slots
end

-- 获取所有激活的天赋Ids
function XTheatre4ColorTalent:GetActiveTalentIds()
    local ids = {}
    for _, v in pairs(self.Slots) do
        for _, talentId in pairs(v:GetTalentIds()) do
            table.insert(ids, talentId)
        end
    end
    return ids
end

-- 获取所有天赋效果
function XTheatre4ColorTalent:GetAllEffects()
    local effects = {}
    for _, v in pairs(self.Slots) do
        for index, effect in pairs(v:GetAllEffects()) do
            effects[index] = effect
        end
    end
    return effects
end

-- 获取待处理档位的天赋Ids
function XTheatre4ColorTalent:GetWaitSlotTalentIds()
    if not self.WaitSlot then
        return {}
    end
    return self.WaitSlot:GetTalentIds()
end

-- 获取免费刷新次数
function XTheatre4ColorTalent:GetRefreshFreeTimes()
    if not self.WaitSlot then
        return 0
    end
    return self.WaitSlot:GetRefreshFreeTimes()
end

-- 获取刷新上限
function XTheatre4ColorTalent:GetRefreshLimit()
    if not self.WaitSlot then
        return 0
    end
    return self.WaitSlot:GetRefreshLimit()
end

-- 获取剩余刷新次数
function XTheatre4ColorTalent:GetRefreshTimes()
    if not self.WaitSlot then
        return 0
    end
    return self.WaitSlot:GetRefreshTimes()
end

return XTheatre4ColorTalent
