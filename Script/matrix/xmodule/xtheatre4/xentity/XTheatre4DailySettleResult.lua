-- 日结算信息
---@class XTheatre4DailySettleResult
local XTheatre4DailySettleResult = XClass(nil, "XTheatre4DailySettleResult")

function XTheatre4DailySettleResult:Ctor()
    -- 利息
    self.Interest = 0
    -- 利息上限
    self.InterestLimit = 0
    -- 建筑点
    self.BuildPoint = 0
    -- 结算颜色等级
    ---@type table<number, number> key:颜色Id value:颜色等级
    self.ColorLevel = {}
    -- 获取颜色资源
    ---@type table<number, number> key:颜色Id value:资源数量
    self.ColorResource = {}
    -- 结算颜色加成
    self.ColorExtra = 0

    -- 结算前繁荣度
    self.ProsperityBefore = 0
    -- 结算后繁荣度
    self.ProsperityAfter = 0
    -- 结算前颜色数据
    ---@type { Id:number, Level:number, Resource:number, TalentLevel:number }[]
    self.ColorDataBefore = {}
    -- 结算后颜色数据
    ---@type { Id:number, Level:number, Resource:number, TalentLevel:number }[]
    self.ColorDataAfter = {}
    -- 藏品信息列表
    ---@type table<number, { UId:number, ItemId:number, IsPlay:boolean }>
    self.ItemDataList = {}
    -- 藏品效果信息
    ---@type table<number, table<number, { ColorLevel:number, ColorResource:number, MarkupRate:number }>>
    ---key1: UId key2: ColorId value: { ColorLevel:number, ColorResource:number, MarkupRate:number }
    self.ItemEffectData = {}
end

-- 服务端通知
function XTheatre4DailySettleResult:NotifyDailySettleResult(data)
    if not data then
        return
    end
    self.Interest = data.Interest or 0
    self.InterestLimit = data.InterestLimit or 0
    self.BuildPoint = data.BuildPoint or 0
    self.ColorLevel = data.ColorLevel or {}
    self.ColorResource = data.ColorResource or {}
    self.ColorExtra = data.ColorExtra or 0
end

-- 更新日结算前繁荣度信息
function XTheatre4DailySettleResult:SetProsperityBefore(prosperity)
    self.ProsperityBefore = prosperity or 0
end

-- 更新日结算后繁荣度信息
function XTheatre4DailySettleResult:SetProsperityAfter(prosperity)
    self.ProsperityAfter = prosperity or 0
end

-- 更新日结算前颜色信息
function XTheatre4DailySettleResult:SetColorInfoBefore(colorDataBefore)
    self.ColorDataBefore = colorDataBefore or {}
end

-- 更新日结算后颜色信息
function XTheatre4DailySettleResult:SetColorInfoAfter(colorDataAfter)
    self.ColorDataAfter = colorDataAfter or {}
    -- 更新颜色等级
    for colorId, level in pairs(self.ColorLevel) do
        self.ColorDataAfter[colorId].Level = level or 0
    end
    -- 更新颜色资源
    for colorId, resource in pairs(self.ColorResource) do
        self.ColorDataAfter[colorId].Resource = resource or 0
    end
end

-- 更新藏品Id列表
function XTheatre4DailySettleResult:SetItemDataList(itemDataList)
    self.ItemDataList = itemDataList or {}
end

-- 更新藏品效果信息
function XTheatre4DailySettleResult:SetItemEffectData(itemEffectData)
    self.ItemEffectData = itemEffectData or {}
end

-- 获取利息
function XTheatre4DailySettleResult:GetInterest()
    return self.Interest
end

-- 获取利息上限
function XTheatre4DailySettleResult:GetInterestLimit()
    return self.InterestLimit
end

-- 获取建筑点
function XTheatre4DailySettleResult:GetBuildPoint()
    return self.BuildPoint
end

-- 获取日结算前繁荣度
function XTheatre4DailySettleResult:GetProsperityBefore()
    return self.ProsperityBefore
end

-- 获取日结算后繁荣度
function XTheatre4DailySettleResult:GetProsperityAfter()
    return self.ProsperityAfter
end

-- 获取日结算前颜色信息列表
function XTheatre4DailySettleResult:GetColorInfoListBefore()
    return self.ColorDataBefore
end

-- 获取日结算后颜色信息列表
function XTheatre4DailySettleResult:GetColorInfoListAfter()
    return self.ColorDataAfter
end

-- 获取日结算后颜色倍率
function XTheatre4DailySettleResult:GetColorExtra()
    return getRoundingValue(self.ColorExtra, 1)
end

-- 获取叉乘后的颜色信息列表
---@return { Id:number, Level:number, Resource:number, TalentLevel:number }[]
function XTheatre4DailySettleResult:GetCrossColorInfoList()
    local colorDataList = {}
    for _, colorId in pairs(XEnumConst.Theatre4.ColorType) do
        local prosperity = self:CalculateProsperity(colorId)
        local talentLevel = self.ColorDataAfter[colorId].TalentLevel or 0
        colorDataList[colorId] = { Id = colorId, Level = 0, Resource = prosperity, TalentLevel = talentLevel, }
    end
    return colorDataList
end

-- 获取藏品Id列表
---@return table<number, { UId:number, ItemId:number, IsPlay:boolean }>
function XTheatre4DailySettleResult:GetItemDataList()
    table.sort(self.ItemDataList, function(a, b)
        if a.IsPlay ~= b.IsPlay then
            return a.IsPlay
        end
        if a.ItemId ~= b.ItemId then
            return a.ItemId < b.ItemId
        end
        return a.UId < b.UId
    end)
    return self.ItemDataList
end

-- 获取藏品效果信息
---@param uid number 藏品唯一Id
---@return table<number, { ColorLevel:number, ColorResource:number, MarkupRate:number }>
function XTheatre4DailySettleResult:GetItemEffectData(uid)
    return self.ItemEffectData[uid] or nil
end

-- 计算繁荣度 颜色等级 * 颜色资源 * 倍率
---@param colorId number 颜色Id
---@return number 繁荣度 四舍五入
function XTheatre4DailySettleResult:CalculateProsperity(colorId)
    local colorLevel = self.ColorLevel[colorId] or 0
    local colorResource = self.ColorResource[colorId] or 0
    local markupRate = self.ColorExtra
    return math.round(colorLevel * colorResource * markupRate)
end

return XTheatre4DailySettleResult
