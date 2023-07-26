---@class XRestaurantOrderInfo
local XRestaurantOrderInfo = XClass(nil, "XRestaurantOrderInfo")

function XRestaurantOrderInfo:Ctor(id)
    self._Id = id
    self._State = XRestaurantConfigs.OrderState.NotStart
    self._UpdateTime = 0
end

function XRestaurantOrderInfo:GetId()
    return self._Id
end

function XRestaurantOrderInfo:UpdateData(state, updateTime)
    self._State = state
    self._UpdateTime = updateTime
end

function XRestaurantOrderInfo:SetState(state)
    self._State = state
end

function XRestaurantOrderInfo:GetTimeStr(format)
    format = format or "yyyy/MM/dd"
    return XTime.TimestampToGameDateTimeString(self._UpdateTime, format)
end

function XRestaurantOrderInfo:IsFinish()
    return self._State == XRestaurantConfigs.OrderState.Finish
end

function XRestaurantOrderInfo:IsNotStart()
    return self._State == XRestaurantConfigs.OrderState.NotStart
end

function XRestaurantOrderInfo:IsOnGoing()
    return self._State == XRestaurantConfigs.OrderState.OnGoing
end


---@class XRestaurantOrder : XDataEntityBase
---@field _InfoDict table<number, XRestaurantOrderInfo>
---@field _NeedReBuildList boolean 是否需要重构列表
---@field _InfoCacheList XRestaurantOrderInfo[] 缓存列表
local XRestaurantOrder = XClass(XDataEntityBase, "XRestaurantOrder")

local default = {
    _Id = 0, --订单活动Id
    _InfoDict = {}, --订单数据
    _InfoCacheList = {}, --订单数据
    _NeedReBuildList = true, --重构列表
}

function XRestaurantOrder:Ctor(id)
    self:Init(default, id)
end

function XRestaurantOrder:InitData(id)
    self:SetProperty("_Id", id)
end

function XRestaurantOrder:UpdateData(infos)
    for _, info in ipairs(infos) do
        local id = info.OrderId
        local data = self._InfoDict[id]
        if not data then
            data = XRestaurantOrderInfo.New(id)
            self._InfoDict[id] = data
        end
        data:UpdateData(info.State, info.UpdateTime)
    end
    --后端更新
    self._NeedReBuildList = true
end

function XRestaurantOrder:GetOrderInfo(orderId)
    local data = self._InfoDict[orderId]
    if not data then
        XLog.Error("获取订单信息失败, 订单Id = " .. orderId)
        return
    end
    return data
end

function XRestaurantOrder:GetUnlockInfoList()
    if not self._NeedReBuildList then
        return self._InfoCacheList
    end
    local list = {}
    for _, info in pairs(self._InfoDict) do
        if info:IsFinish() then
            table.insert(list, info)
        end
    end
    
    table.sort(list, function(a, b) 
        return a:GetId() < b:GetId()
    end)
    self._InfoCacheList = list
    --更新完毕
    self._NeedReBuildList = false
    return list
end

--获取当天的订单信息，如果没有则当天订单已经完成
function XRestaurantOrder:GetTodayOrderInfo()
    for _, info in pairs(self._InfoDict) do
        if info:IsNotStart() or info:IsOnGoing() then
            return info
        end
    end
end

function XRestaurantOrder:GetId()
    return self._Id
end

return XRestaurantOrder