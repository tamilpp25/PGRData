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

-- 获取数据通过id
---@param id number 货物id
function XRogueSimCommoditySellResult:GetDataById(id)
    return self.Datas[id] or nil
end

-- 获取有序数据(出售数量大于0)
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

-- 获取货物出售价格
---@param id number 货物id
function XRogueSimCommoditySellResult:GetSellAwardCountById(id)
    local data = self:GetDataById(id)
    if not data then
        return 0
    end
    return data:GetSellAwardCount()
end

-- 获取货物总的出售价格
function XRogueSimCommoditySellResult:GetTotalSellAwardCount()
    local count = 0
    for _, data in pairs(self.Datas) do
        count = count + data:GetSellAwardCount()
    end
    return count
end

-- 获取货物出售价格
---@return table<number, number>[] 货物id对应的价格
function XRogueSimCommoditySellResult:GetSellAwardCountDic()
    local dic = {}
    for _, data in pairs(self.Datas) do
        dic[data:GetCommodityId()] = data:GetSellAwardCount()
    end
    return dic
end

-- 获取货物出售暴击次数
---@param id number 货物id 0表示所有货物
function XRogueSimCommoditySellResult:GetSellCriticalCount(id)
    local count = 0
    for _, data in pairs(self.Datas) do
        if (id == 0 or data:GetCommodityId() == id) and data:GetIsCritical() then
            count = count + 1
        end
    end
    return count
end

-- 检查货物出售是否有暴击
function XRogueSimCommoditySellResult:CheckSellCritical()
    for _, data in pairs(self.Datas) do
        if data:GetIsCritical() then
            return true
        end
    end
    return false
end

return XRogueSimCommoditySellResult
