---@class XRogueSimCommoditySellResult
local XRogueSimCommoditySellResult = XClass(nil, "XRogueSimCommoditySellResult")

function XRogueSimCommoditySellResult:Ctor()
    self.TurnNumber = 0
    ---@type XRogueSimCommoditySellResultItem[]
    self.Datas = {}
end

function XRogueSimCommoditySellResult:UpdateSellResultData(data)
    self.TurnNumber = data.TurnNumber or 0
    self.Datas = {}
    self:UpdateSellResultItem(data.Datas)
end

function XRogueSimCommoditySellResult:UpdateSellResultItem(data)
    if not data then
        return
    end
    for _, v in pairs(data) do
        self:AddSellResultItem(v)
    end
end

function XRogueSimCommoditySellResult:AddSellResultItem(data)
    if not data then
        return
    end
    local item = self.Datas[data.CommodityId]
    if not item then
        item = require("XModule/XRogueSim/XEntity/XRogueSimCommoditySellResultItem").New()
        self.Datas[data.CommodityId] = item
    end
    item:UpdateSellResultItem(data)
end

-- 获取回合数
function XRogueSimCommoditySellResult:GetTurnNumber()
    return self.TurnNumber
end

-- 获取数据
---@return XRogueSimCommoditySellResultItem[]
function XRogueSimCommoditySellResult:GetDatas()
    local tempData = {}
    for _, id in ipairs(XEnumConst.RogueSim.CommodityIds) do
        local data = self:GetDataById(id)
        if data and data:GetSellCount() > 0 then
            table.insert(tempData, data)
        end
    end
    return tempData
end

function XRogueSimCommoditySellResult:GetDataById(id)
    return self.Datas[id] or nil
end

-- 获取货物总价格
function XRogueSimCommoditySellResult:GetTotalPrice()
    local total = 0
    for _, v in pairs(self.Datas) do
        total = total + v:GetSellAwardCount()
    end
    return total
end

return XRogueSimCommoditySellResult
