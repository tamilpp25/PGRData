-- 组合小游戏背包对象
local XComposeGameItemBag = XClass(nil, "XComposeGameItemBag")
--=============数据结构================
--======活动信息ComposeGameDataDb=============
-- 活动Id
-- int ActId
-- 当前进度
-- int Schedule
-- 刷新次数
-- int RefreshCount
-- 增加刷新次数时间戳(为 0 表示已达上限)
-- int RefreshTime
-- 商品列表
-- List<int> GoodsList
-- 商店列表
-- List<ComposeShopInfo> ShopInfos
-- 已领取奖励列表
-- List<int> RecvSchedule
--=============================================

--==========商品信息ComposeShopInfo=============
-- 标志Id
-- int Id
-- 商品Id
-- int Goods
-- 是否已出售
-- bool IsSell
--=============================================
--=================== END =====================

--================== 本地方法 ==================
--==================
--背包格排序方法
--==================
local SortGrids = function(gridA, gridB)
    if (not gridA) or (gridA:GetItem():CheckIsEmpty()) then return false end
    if (not gridB) or (gridB:GetItem():CheckIsEmpty()) then return true end
    if gridA:GetItemStar() ~= gridB:GetItemStar() then
        return gridA:GetItemStar() > gridB:GetItemStar()
    else
        return gridA:GetOrderId() >= gridB:GetOrderId()
    end
end
--=================== END =====================

--==========构造函数，初始化，实体操作==========
--==================
--构造函数
--@param Game:所属的活动对象
--@param ComposeGameDataDb:NotifyComposeActivityInfo通知活动信息
--==================
function XComposeGameItemBag:Ctor(Game, ComposeGameDataDb)
    self.Game = Game
    self:InitItemGrids()
    self:InitGoods(ComposeGameDataDb.GoodsList)
end
--==================
--初始化背包格子
--==================
function XComposeGameItemBag:InitItemGrids()
    self.Grids = {}
    local BAG_GRIDS_NUM = XDataCenter.ComposeGameManager.BAG_GRIDS_NUM
    local XItemGrid = require("XEntity/XMiniGame/ComposeFactory/XComposeGameItemGrid")
    for i = 1, BAG_GRIDS_NUM do
        self.Grids[i] = XItemGrid.New(self)
    end
end
--==================
--初始化背包格子
--@param GoodsIdList:背包物品ID列表
--==================
function XComposeGameItemBag:InitGoods(GoodsIdList)
    self.Items = {}
    if not GoodsIdList then return end
    local XItem = require("XEntity/XMiniGame/ComposeFactory/XComposeGameItem")
    for i = 1, #GoodsIdList do
        if not self.Items[GoodsIdList[i]] then
            self.Items[GoodsIdList[i]] = XItem.New(GoodsIdList[i], false)
        end
        self.Items[GoodsIdList[i]]:AddNum(true)
    end
    for i = 1, #self.Grids do
        if GoodsIdList[i] then
            self.Grids[i]:AddItem(GoodsIdList[i])
        end
    end
end
--==================
--根据通知活动信息刷新背包
--@param ComposeGameDataDb:NotifyComposeActivityInfo通知活动信息
--==================
function XComposeGameItemBag:RefreshComposeGameData(ComposeGameDataDb)
    self:RefreshItems(ComposeGameDataDb.GoodsList)
    CsXGameEventManager.Instance:Notify(XEventId.EVENT_COMPOSEGAME_BAGITEM_REFRESH)
end
--==================
--根据背包物品刷新背包格
--@param GoodsIdList:背包物品ID列表
--==================
function XComposeGameItemBag:RefreshGridsByItems()
    local itemIdList = {}
    for _, item in pairs(self.Items) do
        for i = 1, item:GetNum() do
            table.insert(itemIdList, item:GetId())
        end
    end
    self:RefreshGrids(itemIdList)
end
--==================
--刷新背包物品
--@param GoodsIdList:背包物品ID列表
--==================
function XComposeGameItemBag:RefreshItems(GoodsIdList)
    self:EmptyItems()
    if not GoodsIdList then return end
    local XItem = require("XEntity/XMiniGame/ComposeFactory/XComposeGameItem")
    for i = 1, #GoodsIdList do
        if not self.Items[GoodsIdList[i]] then
            self.Items[GoodsIdList[i]] = XItem.New(GoodsIdList[i], false)
        end
        self.Items[GoodsIdList[i]]:AddNum()
    end
    self:RefreshGrids(GoodsIdList)
end
--==================
--刷新背包格子
--@param GoodsIdList:背包物品ID列表
--==================
function XComposeGameItemBag:RefreshGrids(GoodsIdList)
    self:EmptyGrids()
    for i = 1, #self.Grids do
        self.Grids[i]:AddItem(GoodsIdList[i])
    end
    table.sort(self.Grids, SortGrids)
end
--==================
--清空所有背包道具信息
--==================
function XComposeGameItemBag:EmptyItems()
    for _, item in pairs(self.Items) do
        item:Empty()
    end
end
--==================
--清空所有背包格子的道具信息
--==================
function XComposeGameItemBag:EmptyGrids()
    for _, grid in pairs(self.Grids) do
        grid:Empty()
    end
end
--==================
--清空拥有指定道具ID的背包格子
--@param itemId:道具ID
--==================
function XComposeGameItemBag:EmptyGridsByItemId(itemId)
    for _, grid in pairs(self.Grids) do
        grid:EmptyByItemId(itemId)
    end
    table.sort(self.Grids, SortGrids)
end
--==================
--根据物品ID增加道具
--@param itemId:道具ID
--==================
function XComposeGameItemBag:AddItemByItemId(itemId)
    if not self.Items[itemId] then
        local XItem = require("XEntity/XMiniGame/ComposeFactory/XComposeGameItem")
        self.Items[itemId] = XItem.New(itemId, false)
    end
    self.Items[itemId]:AddNum()
end
--==================== END ========================

--=================对外接口(Get,Set,Check等接口)================
--==================
--获取背包格子列表
--==================
function XComposeGameItemBag:GetGrids()
    return self.Grids
end
--==================
--根据道具ID获取背包中该ID的道具数量
--@param itemId:玩法道具ID
--==================
function XComposeGameItemBag:GetItemCount(itemId)
    local item = self.Items[itemId]
    if not item then return 0 end
    return item:GetNum()
end
--==================
--检查能否增加道具进背包格
--==================
function XComposeGameItemBag:CheckIsFull()
    local totalNum = 0
    for _, item in pairs(self.Items) do
        totalNum = totalNum + item:GetNum()
    end
    return totalNum >= XDataCenter.ComposeGameManager.BAG_GRIDS_NUM
end

function XComposeGameItemBag:CheckIsFinalItem(itemId)
    return self.Items[itemId] and self.Items[itemId]:GetComposeNeedNum()
end
--==================
--购买道具处理
--@param itemId:购买道具的Id
--==================
function XComposeGameItemBag:BuyItem(itemId)
    self:AddItemByItemId(itemId)
    self:RefreshGridsByItems()
end
--==================
--获取指定ID道具是否为新道具
--@param itemId:活动道具Id
--==================
function XComposeGameItemBag:GetItemIsNew(itemId)
    return self.Items[itemId] and self.Items[itemId]:GetIsNewItem() or false
end
--==================== END ========================
return XComposeGameItemBag