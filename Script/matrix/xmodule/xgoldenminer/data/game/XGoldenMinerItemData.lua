local XGoldenMinerItemBase = require("XModule/XGoldenMiner/Data/Base/XGoldenMinerItemBase")

---黄金矿工不可叠加的道具数据
---@class XGoldenMinerItemData:XGoldenMinerItemBase
local XGoldenMinerItemData = XClass(XGoldenMinerItemBase, "XGoldenMinerItemData")

function XGoldenMinerItemData:Ctor(itemId)
    self._Status = XEnumConst.GOLDEN_MINER.ITEM_CHANGE_TYPE.ON_GET
    self._ClientItemId = 0      --前端缓存的道具Id，玩法内随意变更，用于和后端传来的道具Id来判断是否有变更
    self._RemainingTimes = 0    --最后的生效次数
    self._GridIndex = 0         --格子位置
    self:SetClientItemId(itemId)
end

function XGoldenMinerItemData:UpdateData(data)
    self._RemainingTimes = data.RemainingTimes
end

function XGoldenMinerItemData:SetClientItemId(itemId)
    self._ClientItemId = itemId
end

function XGoldenMinerItemData:SetStatus(status)
    self._Status = status
end

function XGoldenMinerItemData:SetGridIndex(gridIndex)
    self._GridIndex = gridIndex
end

function XGoldenMinerItemData:GetRemainingTimes()
    return self._RemainingTimes
end

function XGoldenMinerItemData:GetStatus()
    return self._Status
end

function XGoldenMinerItemData:GetGridIndex()
    return self._GridIndex
end

function XGoldenMinerItemData:GetClientItemId()
    return self._ClientItemId
end

function XGoldenMinerItemData:GetBuffId()
    local itemId = self:GetClientItemId()
    return XTool.IsNumberValid(itemId) and XMVCA.XGoldenMiner:GetCfgItemBuffId(itemId) or 0
end

function XGoldenMinerItemData:GetItemType()
    local itemId = self:GetClientItemId()
    return XTool.IsNumberValid(itemId) and XMVCA.XGoldenMiner:GetCfgItemType(itemId) or 0
end

return XGoldenMinerItemData