-- 效果实例
---@class XTheatre4Effect
local XTheatre4Effect = XClass(nil, "XTheatre4Effect")

function XTheatre4Effect:Ctor()
    -- 自增Id
    self.Id = 0
    self.EffectId = 0
    self.Count = 0
    -- 自定义数据
    ---@type table<number, number>
    self.CustomData = {}
    -- 颜色资源加成
    ---@type table<number, number> key:colorId value:资源数量
    self.ColorResource = {}
    -- 倍率加成 万分比
    self.MarkupRate = 0
    -- 附着藏品uid
    self.ItemUid = 0
    -- 累计
    self.Accumulate = 0
    -- 涨价次数
    self.UseTimes = 0
end

-- 服务端通知
function XTheatre4Effect:NotifyEffectData(data)
    self.Id = data.Id or 0
    self.EffectId = data.EffectId or 0
    self.Count = data.Count or 0
    self.CustomData = data.CustomData or {}
    self.ColorResource = data.ColorResource or {}
    self.MarkupRate = data.MarkupRate or 0
    self.ItemUid = data.ItemUid or 0
    self.Accumulate = data.Accumulate or 0
    self.UseTimes = data.UseTimes or 0
end

-- 获取自增Id
function XTheatre4Effect:GetId()
    return self.Id
end

-- 获取效果Id
function XTheatre4Effect:GetEffectId()
    return self.EffectId
end

-- 获取效果数量
function XTheatre4Effect:GetCount()
    return self.Count
end

-- 获取自定义数据
function XTheatre4Effect:GetCustomData(key)
    if not XTool.IsNumberValid(key) then
        key = 0
    end
    return self.CustomData[key] or 0
end

-- 获取颜色资源加成
function XTheatre4Effect:GetColorResource(color)
    return self.ColorResource[color]
end

-- 获取倍率加成
function XTheatre4Effect:GetMarkupRate()
    return self.MarkupRate
end

-- 获取附着藏品uid
function XTheatre4Effect:GetItemUid()
    return self.ItemUid
end

-- 获取累计
function XTheatre4Effect:GetAccumulate()
    return self.Accumulate
end

-- 涨价次数
function XTheatre4Effect:GetUseTimes()
    return self.UseTimes
end

return XTheatre4Effect
