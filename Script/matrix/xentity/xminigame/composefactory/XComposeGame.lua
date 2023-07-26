-- 合成小游戏Game对象
local XComposeGame = XClass(nil, "XComposeGame")
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

--==========构造函数，初始化，实体操作==========

--==================
--构造函数
--@param ComposeGameDataDb:NotifyComposeActivityInfo通知活动信息
--==================
function XComposeGame:Ctor(ComposeGameDataDb)
    self.GameConfig = XComposeGameConfig.GetGameConfigsByGameId(ComposeGameDataDb.ActId or 1)
    self:InitBag(ComposeGameDataDb)
    self:InitShop(ComposeGameDataDb)
    self:InitTreasure(ComposeGameDataDb)
    self:SetRefreshStatus(ComposeGameDataDb)
end
--==================
--初始化此活动背包
--@param ComposeGameDataDb:NotifyComposeActivityInfo通知活动信息
--==================
function XComposeGame:InitBag(ComposeGameDataDb)
    local XItemBag = require("XEntity/XMiniGame/ComposeFactory/XComposeGameItemBag")
    self.Bag = XItemBag.New(self, ComposeGameDataDb)
end
--==================
--初始化此活动商店
--@param ComposeGameDataDb:NotifyComposeActivityInfo通知活动信息
--==================
function XComposeGame:InitShop(ComposeGameDataDb)
    local XShop = require("XEntity/XMiniGame/ComposeFactory/XComposeGameShop")
    self.Shop = XShop.New(self, ComposeGameDataDb)
end
--==================
--初始化此活动进度宝箱
--@param ComposeGameDataDb:NotifyComposeActivityInfo通知活动信息
--==================
function XComposeGame:InitTreasure(ComposeGameDataDb)
    local XTreasure = require("XEntity/XMiniGame/ComposeFactory/XComposeGameProgressTreasure")
    self.Treasure = XTreasure.New(self, ComposeGameDataDb)
end
--==================
--初始化此活动刷新
--@param ComposeGameDataDb:NotifyComposeActivityInfo通知活动信息
--==================
function XComposeGame:SetRefreshStatus(ComposeGameDataDb)
    if not ComposeGameDataDb then return end
    self.RefreshCount = ComposeGameDataDb.RefreshCount or 0
    self.RefreshTime = ComposeGameDataDb.RefreshTime or 0
    CsXGameEventManager.Instance:Notify(XEventId.EVENT_COMPOSEGAME_SHOP_REFRESH_TIME_CHANGE)
end
--==================
--根据通知活动信息刷新活动
--@param ComposeGameDataDb:NotifyComposeActivityInfo通知活动信息
--==================
function XComposeGame:RefreshComposeGameData(ComposeGameDataDb)
    self.Bag:RefreshComposeGameData(ComposeGameDataDb)
    self.Shop:RefreshComposeGameData(ComposeGameDataDb)
    self.Treasure:RefreshComposeGameData(ComposeGameDataDb)
    self:SetRefreshStatus(ComposeGameDataDb)
end
--==================
--根据通知活动信息刷新背包
--@param ComposeGoodsInfo:NotifyComposeGoodsInfo通知活动信息
--==================
function XComposeGame:RefreshBagGoodsList(ComposeGoodsInfo)
    self.Bag:RefreshComposeGameData(ComposeGoodsInfo)
end
--==================
--根据通知活动信息刷新商店
--@param ComposeGoodsInfo:NotifyComposeGoodsInfo通知活动信息
--==================
function XComposeGame:RefreshShopInfoList(ComposeShopInfos)
    self.Shop:RefreshShopByShopInfos(ComposeShopInfos)
end
--==================
--购买道具
--==================
function XComposeGame:BuyItem(itemId)
    self.Bag:BuyItem(itemId)
end
--==================
--根据道具ID合成道具
--@param itemId:要合成的道具
--==================
function XComposeGame:ComposeItem(item)
    self:RefreshBagGrids()
    CsXGameEventManager.Instance:Notify(XEventId.EVENT_COMPOSEGAME_ITEM_COMPOSE, item)
    self.Treasure:SetSchedule(item:GetGainSchedule())
end
--==================
--刷新背包格
--==================
function XComposeGame:RefreshBagGrids()
    self.Bag:RefreshGridsByItems()
end
--=================== END =====================

--=================对外接口(Get,Set,Check等接口)================
--==================
--获取活动ID
--==================
function XComposeGame:GetGameId()
    return self.GameConfig and self.GameConfig.Id or 0
end
--==================
--获取活动时间ID
--==================
function XComposeGame:GetTimeId()
    return self.GameConfig and self.GameConfig.TimeId or 0
end
--==================
--获取活动通用货币的道具ID
--==================
function XComposeGame:GetCoinId()
    return self.GameConfig and self.GameConfig.CoinId or 0
end
--==================
--获取活动刷新次数上限
--==================
function XComposeGame:GetRefreshCountLimit()
    return self.GameConfig and self.GameConfig.RefreshCountLimit or 0
end
--==================
--获取活动商店刷新次数时长
--==================
function XComposeGame:GetRefreshTimeSec()
    return self.GameConfig and self.GameConfig.RefreshTimeSec or 0
end
--==================
--获取活动最大进度
--==================
function XComposeGame:GetMaxSchedule()
    return self.GameConfig and self.GameConfig.MaxSchedule or 0
end
--==================
--获取当前活动进度
--==================
function XComposeGame:GetCurrentSchedule()
    return self.Treasure and self.Treasure:GetCurrentSchedule() or 0
end
--==================
--获取活动商店随机数量
--==================
function XComposeGame:GetShopRandCount()
    return self.GameConfig and self.GameConfig.ShopRandCount or 0
end
--==================
--获取活动进度刻度列表
--==================
function XComposeGame:GetSchedule()
    return self.GameConfig and self.GameConfig.Schedule or {}
end
--==================
--获取活动奖励ID列表
--==================
function XComposeGame:GetRewardId()
    return self.GameConfig and self.GameConfig.RewardId or {}
end
--==================
--获取活动商店现在可刷新次数
--==================
function XComposeGame:GetRefreshCount()
    return self.RefreshCount
end
--==================
--获取活动下一次增加刷新次数的时间戳
--==================
function XComposeGame:GetRefreshTime()
    return self.RefreshTime
end
--==================
--获取活动代币刷新次数的价格
--==================
function XComposeGame:GetRefreshPrice()
    return self.GameConfig and self.GameConfig.RefreshPrice or 1
end

function XComposeGame:GetRefreshTimeIsMax()
    return self:GetRefreshCount() >= self:GetRefreshCountLimit()
end

function XComposeGame:CheckCanRefresh()
    local count = self:GetRefreshCount()
    return count > 0
end

function XComposeGame:CheckCanBuyRefresh()
    return false --self:CheckEnoughCoin(self:GetRefreshPrice())
end
--==================
--根据道具ID获取背包中该ID的道具数量
--@param itemId:玩法道具ID
--==================
function XComposeGame:GetItemCount(itemId)
    return self.Bag:GetItemCount(itemId)
end
--==================
--根据道具ID获取背包中该ID是否新获得
--@param itemId:玩法道具ID
--==================
function XComposeGame:GetItemIsNew(itemId)
    return self.Bag:GetItemIsNew(itemId)
end
--================
--获取当前刷新次数展示字符串
--================
function XComposeGame:GetRefreshStr()
    return string.format("%d/%d", self:GetRefreshCount(), self:GetRefreshCountLimit())
end

function XComposeGame:GetBeginStoryId()
    local GameCfg = XComposeGameConfig.GetClientConfigByGameId(self:GetGameId())
    if not GameCfg then return end
    local storyId = GameCfg.BeginStoryId or GameCfg.DebugStartTime --因为要热更更新，不能更改C#的XTable，暂时用已有字段DebugStartTime项代用，以后使用BeginStoryId
    return storyId or ""
end
--==================
--获取活动是否开启时间
--==================
function XComposeGame:CheckIsOpenTime()
    local timeNow = XTime.GetServerNowTimestamp()
    local isEnd = timeNow >= self:GetEndTime()
    local isStart = timeNow >= self:GetStartTime()
    local inTime = (not isEnd) and (isStart)
    return inTime, (timeNow < self:GetStartTime())
end
--==================
--获取活动结束时间
--==================
function XComposeGame:GetEndTime()
    return XFunctionManager.GetEndTimeByTimeId(self:GetTimeId()) or 0
end
--==================
--获取活动开始时间
--==================
function XComposeGame:GetStartTime()
    return XFunctionManager.GetStartTimeByTimeId(self:GetTimeId()) or 0
end
--==================
--获取现有代币数量
--==================
function XComposeGame:GetCoinNum()
    return XDataCenter.ItemManager.GetCount(self:GetCoinId()) or 0
end
--==================
--获取商店格列表
--==================
function XComposeGame:GetShopGrids()
    return self.Shop:GetShopGrids()
end
--==================
--获取背包格列表
--==================
function XComposeGame:GetBagGrids()
    return self.Bag:GetGrids()
end
--==================
--获取进度宝箱列表
--==================
function XComposeGame:GetTreasureBoxes()
    return self.Treasure and self.Treasure:GetTreasureBoxes() or {}
end
--==================
--获取活动开始时间
--==================
function XComposeGame:CheckCanBuyItem(item)
    if not self:CheckEnoughCoin(item:GetCostCoinNum()) then
        return false, CS.XTextManager.GetText("ComposeGameCoinNotEnough")
    end
    if not self:CheckEnoughGrids() then
        return false, CS.XTextManager.GetText("ComposeGameGridsNotEnough")
    end
    return true
end
--==================
--检查是否有足够代币
--==================
function XComposeGame:CheckEnoughCoin(checkNum)
    local coinNum = self:GetCoinNum()
    return coinNum >= checkNum
end
--==================
--检查是否背包有空位
--==================
function XComposeGame:CheckEnoughGrids()
    return not self.Bag:CheckIsFull()
end
--=================== END =====================
return XComposeGame