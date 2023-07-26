-- 组合小游戏商店格对象
local XComposeGameShopGrid = XClass(nil, "XComposeGameShopGrid")
--=============数据结构================
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
--@param Shop:对应商店对象
--@param ShopInfo:商品信息
--==================
function XComposeGameShopGrid:Ctor(Shop, ShopInfo)
    self.Shop = Shop
    self:Init()
    if ShopInfo then
        self:RefreshInfo(ShopInfo)
    end
end
--==================
--初始化
--==================
function XComposeGameShopGrid:Init()
    self:InitItem()
end
--==================
--初始化展示道具
--==================
function XComposeGameShopGrid:InitItem()
    local XItem = require("XEntity/XMiniGame/ComposeFactory/XComposeGameItem")
    self.Item = XItem.New(nil, true)
end
--==================
--刷新商品信息
--==================
function XComposeGameShopGrid:RefreshInfo(ShopInfo)
    self.BuyId = ShopInfo.Id
    self.IsSell = ShopInfo.IsSell
    local item = self:GetItem()
    item:RefreshItem(ShopInfo.Goods)
end
--==================== END ========================

--=================对外接口(Get,Set,Check等接口)================

function XComposeGameShopGrid:Buy()
    self.IsSell = true
    CsXGameEventManager.Instance:Notify(XEventId.EVENT_COMPOSEGAME_SHOP_ITEM_REFRESH)
end
--==================
--获取展示道具对象
--==================
function XComposeGameShopGrid:GetItem()
    if not self.Item then
        self:InitItem()
    end
    return self.Item
end
--==================
--获取商店购买ID(购买商品时使用)
--==================
function XComposeGameShopGrid:GetBuyId()
    return self.BuyId
end
--==================
--检查此商品是否已售
--==================
function XComposeGameShopGrid:CheckIsSell()
    return self.IsSell
end
--==================== END ========================
return XComposeGameShopGrid