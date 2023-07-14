-- 组合小游戏玩法道具对象
local XComposeGameItem = XClass(nil, "XComposeGameItem")
--==========构造函数，初始化，实体操作==========
--==================
--获取背包格的道具
--==================
function XComposeGameItem:Ctor(itemId, forDisplay)
    self.ForDisplay = forDisplay
    self:Reset()
    if itemId then self:RefreshItem(itemId) end
end
--==================
--获取背包格的道具
--==================
function XComposeGameItem:Reset()
    self.Num = 0
end
--==================== END ========================

--=================对外接口(Get,Set,Check等接口)================
--==================
--根据道具ID刷新道具实体
--@param itemId:活动道具ID
--==================
function XComposeGameItem:RefreshItem(itemId)
    self.ItemCfg = XComposeGameConfig.GetItemConfigByItemId(itemId)
end
--==================
--获取道具ID
--==================
function XComposeGameItem:GetId()
    return self.ItemCfg and self.ItemCfg.Id
end
--==================
--获取道具的排序ID
--==================
function XComposeGameItem:GetOrderId()
    return self.ItemCfg and self.ItemCfg.OrderId or 1
end
--==================
--获取道具所属活动ID
--==================
function XComposeGameItem:GetGameId()
    return self.ItemCfg and self.ItemCfg.ActId
end
--==================
--获取道具名称
--==================
function XComposeGameItem:GetName()
    return self.ItemCfg and self.ItemCfg.Name or ""
end
--===============
--获取物品的大图标
--===============
function XComposeGameItem:GetBigIcon()
    return self.ItemCfg and self.ItemCfg.BigIcon or ""
end
--===============
--获取物品的小图标
--===============
function XComposeGameItem:GetSmallIcon()
    return self.ItemCfg and self.ItemCfg.SmallIcon or ""
end
--===============
--获取物品的星数
--===============
function XComposeGameItem:GetStar()
    return self.ItemCfg and self.ItemCfg.Star or 1
end
--==================
--获取道具合成后变成的道具ID
--==================
function XComposeGameItem:GetComposeId()
    return self.ItemCfg and self.ItemCfg.ComposeId or 0
end
--==================
--获取道具需要多少个进行合成
--==================
function XComposeGameItem:GetComposeNeedNum()
    return self.ItemCfg and self.ItemCfg.ComposeNeedNum
end
--==================
--获取花费代币量
--==================
function XComposeGameItem:GetCostCoinNum()
    return self.ItemCfg and self.ItemCfg.CostCoinNum or 1
end
--==================
--获取该道具推进的活动进度值
--==================
function XComposeGameItem:GetGainSchedule()
    return self.ItemCfg and self.ItemCfg.GainSchedule
end
--===============
--获取最终产物Id
--===============
function XComposeGameItem:GetFinalSchedule()
    return self.ItemCfg and self.ItemCfg.FinalSchedule
end
--===============
--获取物品的质量
--===============
function XComposeGameItem:GetQuality()
    return self.ItemCfg and self.ItemCfg.Quality or 1
end
--===============
--获取物品的世界观描述
--===============
function XComposeGameItem:GetWorldDesc()
    local GameCfg = XComposeGameConfig.GetClientConfigByGameId(self:GetGameId())
    if not GameCfg then return end
    local str = GameCfg.ItemDefaultWorldDesc
    str = string.gsub(str, "\\n", "\n")
    str = string.format(str, self:GetName(), self:GetName(), self:GetName(), self:GetName())
    return str
end
--===============
--获取物品的描述
--===============
function XComposeGameItem:GetDescription()
    local GameCfg = XComposeGameConfig.GetClientConfigByGameId(self:GetGameId())
    if not GameCfg then return end
    local str = GameCfg.ItemDefaultDescription
    str = string.gsub(str, "\\n", "\n")
    str = string.format(str, self:GetFinalSchedule())
    return str
end
--===============
--获取物品的临时展示信息(用于XUiTip)
--===============
function XComposeGameItem:GetTempItemData()
    local tempItemData = {
        IsTempItemData = true,
        Name = self:GetName(),
        Count = self:GetNum(),
        Icon = self:GetBigIcon(),
        Quality = self:GetQuality(),
        WorldDesc = self:GetWorldDesc(),
        Description = self:GetDescription()
    }
    return tempItemData
end
--==================
--获取该道具数量
--==================
function XComposeGameItem:GetNum()
    return self.Num
end
--==================
--设置该道具数量
--==================
function XComposeGameItem:SetNum(num)
    self.Num = num
    if self:CheckCanCompose(num) then
        self:Compose()
    end
end
--==================
--增加一个道具
--==================
function XComposeGameItem:AddNum(isInit)
    local tempNum = self:GetNum()
    local addNum = tempNum + 1
    self:SetNum(addNum)
    if not isInit then self.NewItem = self:GetNum() > 0 end
    if self:GetIsFinalItem() then
        local Game = XDataCenter.ComposeGameManager.GetGameById(self:GetGameId())
        if Game then
            Game:ComposeItem(self)
        end
    end
end
--==================
--检查这个道具是否新增的
--==================
function XComposeGameItem:GetIsNewItem()
    local result = self:GetIsFinalItem() or self.NewItem
    self.NewItem = false
    return result
end
--==================
--减少一个道具
--==================
function XComposeGameItem:MinusNum()
    local tempNum = self:GetNum()
    if tempNum <= 0 then
        tempNum = 0
    else
        tempNum = tempNum - 1
    end
    self:SetNum(tempNum)
end
--==================
--获取该道具是否终端产品
--==================
function XComposeGameItem:GetIsFinalItem()
    return self:GetComposeId() == nil or self:GetComposeId() == 0
end
--==================
--检查要设置的道具数量是否达到合成数量
--@param setNum:要设置的道具数量
--==================
function XComposeGameItem:CheckCanCompose(setNum)
    return not self:GetIsFinalItem() and setNum >= self:GetComposeNeedNum()
end
--==================
--合成道具
--==================
function XComposeGameItem:Compose()
    if not self:GetIsFinalItem() then
        self:SetNum(self:GetNum() - self:GetComposeNeedNum())
        local Game = XDataCenter.ComposeGameManager.GetGameById(self:GetGameId())
        if Game then
            Game:BuyItem(self:GetComposeId())
        end
    end
end
--==================
--清空道具
--==================
function XComposeGameItem:Empty()
    if self.ForDisplay then
        self.ItemCfg = nil
    else
        self.Num = 0
        local Game = XDataCenter.ComposeGameManager.GetGameById(self:GetGameId())
        if Game then
            Game:RefreshBagGrids()
        end
    end
end
--==================
--检查道具是否为空(没有数据或数量为0)
--==================
function XComposeGameItem:CheckIsEmpty()
    if self.ForDisplay then
        return self.ItemCfg == nil
    else
        return self.Num == 0
    end
end
--==================
--检查道具是否差一个升星
--==================
function XComposeGameItem:CheckIsLevelUp()
    if self:GetIsFinalItem() then return false end
    if self.ForDisplay then
        local Game = XDataCenter.ComposeGameManager.GetGameById(self:GetGameId())
        if Game then
            local count = Game:GetItemCount(self:GetId())
            return count == self:GetComposeNeedNum() - 1
        end
    else
        return self:GetNum() == self:GetComposeNeedNum() - 1
    end
    return false
end
--==================== END ========================
return XComposeGameItem