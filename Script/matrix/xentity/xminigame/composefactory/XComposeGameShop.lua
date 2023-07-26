-- 组合小游戏商店
local XComposeGameShop = XClass(nil, "XComposeGameShop")
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

function XComposeGameShop:Ctor(Game, ComposeGameDataDb)
    self.Game = Game
    self:InitShop(ComposeGameDataDb.ShopInfos)
end

function XComposeGameShop:InitShop(shopInfos)
    self.Grids = {}
    local XShopGrid = require("XEntity/XMiniGame/ComposeFactory/XComposeGameShopGrid")
    for index, info in pairs(shopInfos) do
        self.Grids[index] = XShopGrid.New(self, info)
    end
end

function XComposeGameShop:RefreshShopByShopInfos(shopInfos)
    local XShopGrid = require("XEntity/XMiniGame/ComposeFactory/XComposeGameShopGrid")
    for index, info in pairs(shopInfos) do
        if self.Grids[index] then
            self.Grids[index]:RefreshInfo(info)
        else
            self.Grids[index] = XShopGrid.New(self, info)
        end
    end
end

function XComposeGameShop:GetShopGrids()
    return self.Grids
end

return XComposeGameShop