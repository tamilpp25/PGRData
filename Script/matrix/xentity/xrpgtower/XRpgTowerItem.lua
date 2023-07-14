-- 兵法蓝图玩法道具
local XRpgTowerItem = XClass(nil, "XRpgTowerItem")

function XRpgTowerItem:Ctor(rItemId)
    self.ItemCfg = XRpgTowerConfig.GetRItemConfigByRItemId(rItemId)
    self.Count = 0
end
--===============
--增加物品数量
--@param addNum:增加的数量
--===============
function XRpgTowerItem:AddNum(addNum)
    self.Count = self.Count + addNum
end
--===============
--减少物品数量
--@param minusNum:减少的数量
--===============
function XRpgTowerItem:MinusNum(minusNum)
    self.Count = self.Count - minusNum
    if self.Count < 0 then self.Count = 0 end
end
--===============
--设置物品数量
--@param num:设置数量
--===============
function XRpgTowerItem:SetNum(num)
    self.Count = num
end
--===============
--检查是否有足够物品数量
--@param checkNum:检查的数量
--===============
function XRpgTowerItem:IsEnoughNum(checkNum)
    return self.Count >= checkNum
end
--===============
--获取当前物品数量
--===============
function XRpgTowerItem:GetNum()
    return self.Count
end
--===============
--获取图标地址
--===============
function XRpgTowerItem:GetIcon()
    return self.ItemCfg.Icon
end
--===============
--获取物品的临时展示信息(用于XUiTip)
--===============
function XRpgTowerItem:GetTempItemData()
    local tempItemData = {
        IsTempItemData = true,
        Name = self.ItemCfg.Name,
        Count = self:GetNum(),
        Icon = self.ItemCfg.Icon,
        Quality = self.ItemCfg.Quality > 0 and self.ItemCfg.Quality or 1,
        WorldDesc = self.ItemCfg.WorldDesc,
        Description = self.ItemCfg.Description
        }
    return tempItemData
end
return XRpgTowerItem