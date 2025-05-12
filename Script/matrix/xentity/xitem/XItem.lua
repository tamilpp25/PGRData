---@class XItem
XItem = XClass(nil, "XItem")

local Default = {
    Id = 0,
    Count = 0,
    BuyTimes = 0, -- 单日购买次数
    RefreshTime = 0,
    CreateTime = 0,
    TotalBuyTimes = 0, -- 总购买次数
    LastBuyTime = 0,
}

function XItem:Ctor(itemData, template)
    for key in pairs(Default) do
        self[key] = Default[key]
    end

    if template then
        self.Template = template
        self.Id = template.Id
    end

    self:RefreshItem(itemData)
end

function XItem:RefreshItem(itemData)
    if not itemData then
        return
    end

    if itemData.RefreshTime then
        self.RefreshTime = itemData.RefreshTime
    end
    
    if itemData.Count then
        self:SetCount(itemData.Count)
    end

    if itemData.BuyTimes then
        self:SetBuyTimes(itemData.BuyTimes)
    end

    if itemData.CreateTime then
        self.CreateTime = itemData.CreateTime
    end

    if itemData.TotalBuyTimes then
        self.TotalBuyTimes = itemData.TotalBuyTimes
    end

    if itemData.LastBuyTime then
        self.LastBuyTime = itemData.LastBuyTime
    end
end

function XItem:SetCount(count)
    if self.Count == count then
        return
    end

    self.Count = count

    CsXGameEventManager.Instance:Notify(XEventId.EVENT_ITEM_COUNT_UPDATE_PREFIX .. self.Id, self.Id, self.Count)
    XEventManager.DispatchEvent(XEventId.EVENT_ITEM_COUNT_UPDATE_PREFIX .. self.Id, self.Id, self.Count)
end

function XItem:SetBuyTimes(buyTimes)
    if buyTimes == self.BuyTimes then
        return
    end

    self.BuyTimes = buyTimes

    XEventManager.DispatchEvent(XEventId.EVENT_ITEM_BUYTIEMS_UPDATE_PREFIX .. self.Id, self.Id, self.BuyTimes)
end

function XItem:GetCount()
    return self.Count
end

function XItem:GetMaxCount()
    return self.Template.MaxCount
end

-- 获取总购买次数
function XItem:GetTotalBuyTimes()
    return self.TotalBuyTimes
end

-- 获取最后购买时间
function XItem:GetLastBuyTime()
    return self.LastBuyTime
end

function XItem:CheckIsOverTotalBuyTimes()
    local maxTotalBuyTimes = XItemConfigs.GetBuyAssetTotalLimit(self.Id)
    if maxTotalBuyTimes <= 0 then return false end
    return self.TotalBuyTimes >= maxTotalBuyTimes
end

function XItem:GetIsInBuyTime()
    local buyTimeId = XItemConfigs.GetBuyAssetTimeId(self.Id)
    if buyTimeId <= 0 then return true end
    return XFunctionManager.CheckInTimeByTimeId(buyTimeId)
end