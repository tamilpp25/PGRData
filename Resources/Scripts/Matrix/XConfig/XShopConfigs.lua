XShopConfigs = {}

local ShopGroupTemplate = {}
local ShopTypeNameTemplate = {}
local ScreenGroupTemplate = {}
local ShowTypeTemplate = {}
local ShopBuyLimitLabel = {}

local TABLE_SHOP_GROUP = "Client/Shop/ShopGroup.tab"
local TABLE_SHOP_TYPENAME = "Client/Shop/ShopTypeName.tab"
local TABLE_SHOP_SCREENGROUP = "Client/Shop/ScreenGroup.tab"
local TABLE_SHOP_SHOWTYPE = "Client/Shop/ShopShowType.tab"
local TABLE_SHOP_BUY_LIMIT_LABEL = "Client/Shop/ShopBuyLimitLabel.tab"

XShopConfigs.ShowType = {
    Normal = 0, --通常
    Fashion = 1 --时装
}

XShopConfigs.BuyType = {
    Shop = 1, --商店进入
    Purchase = 2 --礼包界面进入
}

function XShopConfigs.Init()
    ShopGroupTemplate = XTableManager.ReadByIntKey(TABLE_SHOP_GROUP, XTable.XTableShopGroup, "Id")
    ShopTypeNameTemplate = XTableManager.ReadByIntKey(TABLE_SHOP_TYPENAME, XTable.XTableShopTypeName, "Id")
    ScreenGroupTemplate = XTableManager.ReadByIntKey(TABLE_SHOP_SCREENGROUP, XTable.XTableShopScreenGroup, "Id")
    ShowTypeTemplate = XTableManager.ReadByIntKey(TABLE_SHOP_SHOWTYPE, XTable.XTableShopShowType, "Id")
    ShopBuyLimitLabel = XTableManager.ReadByIntKey(TABLE_SHOP_BUY_LIMIT_LABEL, XTable.XTableShopBuyLimitLabel, "ClockId")
end

function XShopConfigs.GetShopGroupTemplate()
    return ShopGroupTemplate
end

function XShopConfigs.GetShopTypeNameTemplate()
    return ShopTypeNameTemplate
end

function XShopConfigs.GetShopScreenGroupTemplate()
    return ScreenGroupTemplate
end

function XShopConfigs.GetShopShowTypeTemplateById(id)
    return ShowTypeTemplate[id]
end

---
--- 获取商店中商品的限购提示
function XShopConfigs.GetBuyLimitLabel(clockId)
    local id = clockId or 0
    local cfg = ShopBuyLimitLabel[id]

    if not cfg then
        XLog.ErrorTableDataNotFound("XShopConfigs.GetBuyLimitLabel", "限购描述", TABLE_SHOP_BUY_LIMIT_LABEL, "ClockId", tostring(clockId))
        cfg = ShopBuyLimitLabel[0]
    end
    return cfg.TextLimitLabel
end