---@class XRogueSimCommodityProduceResult
local XRogueSimCommodityProduceResult = XClass(nil, "XRogueSimCommodityProduceResult")

function XRogueSimCommodityProduceResult:Ctor()
    self.TurnNumber = 0
    ---@type XRogueSimCommodityProduceResultItem[]
    self.Datas = {}
end

function XRogueSimCommodityProduceResult:UpdateProduceResultData(data)
    self.TurnNumber = data.TurnNumber or 0
    self.Datas = {}
    self:UpdateProduceResultItem(data.Datas)
end

function XRogueSimCommodityProduceResult:UpdateProduceResultItem(data)
    if not data then
        return
    end
    for _, v in pairs(data) do
        self:AddProduceResultItem(v)
    end
end

function XRogueSimCommodityProduceResult:AddProduceResultItem(data)
    if not data then
        return
    end
    local item = self.Datas[data.CommodityId]
    if not item then
        item = require("XModule/XRogueSim/XEntity/XRogueSimCommodityProduceResultItem").New()
        self.Datas[data.CommodityId] = item
    end
    item:UpdateProduceResultItem(data)
end

-- 获取回合数
function XRogueSimCommodityProduceResult:GetTurnNumber()
    return self.TurnNumber
end

-- 获取数据通过id
---@param id number 货物id
function XRogueSimCommodityProduceResult:GetDataById(id)
    return self.Datas[id] or nil
end

-- 获取有序数据(生产数量大于0)
---@return XRogueSimCommodityProduceResultItem[]
function XRogueSimCommodityProduceResult:GetDatas()
    local tempData = {}
    for _, id in ipairs(XEnumConst.RogueSim.CommodityIds) do
        local data = self:GetDataById(id)
        if data and data:GetProduceCount() > 0 then
            table.insert(tempData, data)
        end
    end
    return tempData
end

-- 获取货物的生产数量
---@param id number 货物id
function XRogueSimCommodityProduceResult:GetProduceCountById(id)
    local data = self:GetDataById(id)
    if not data then
        return 0
    end
    return data:GetProduceCount()
end

-- 获取货物总的生产数量
function XRogueSimCommodityProduceResult:GetTotalProduceCount()
    local count = 0
    for _, data in pairs(self.Datas) do
        count = count + data:GetProduceCount()
    end
    return count
end

-- 获取货物生产数量
---@return table<number, number>[] 货物id对应生产数量
function XRogueSimCommodityProduceResult:GetProduceCountDic()
    local dic = {}
    for _, data in pairs(self.Datas) do
        dic[data:GetCommodityId()] = data:GetProduceCount()
    end
    return dic
end

-- 获取货物生产暴击次数
---@param id number 货物id 0表示所有货物
function XRogueSimCommodityProduceResult:GetProduceCriticalCount(id)
    local count = 0
    for _, data in pairs(self.Datas) do
        if (id == 0 or data:GetCommodityId() == id) and data:GetIsCritical() then
            count = count + 1
        end
    end
    return count
end

-- 检查货物生产是否有暴击
function XRogueSimCommodityProduceResult:CheckProduceCritical()
    for _, data in pairs(self.Datas) do
        if data:GetIsCritical() then
            return true
        end
    end
    return false
end

return XRogueSimCommodityProduceResult
