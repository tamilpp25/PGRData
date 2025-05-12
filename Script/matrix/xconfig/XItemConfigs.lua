local tableInsert = table.insert
local tableSort = table.sort

XItemConfigs = XItemConfigs or {}

local XItemTemplate = require("XEntity/XItem/XItemTemplate")
local XCharacterExpTemplate = require("XEntity/XItem/XCharacterExpTemplate")
local XEquipExpTemplate = require("XEntity/XItem/XEquipExpTemplate")
local XGiftTemplate = require("XEntity/XItem/XGiftTemplate")
local XPartnerExpTemplate = require("XEntity/XItem/XPartnerExpTemplate")

local TABLE_ITEM_PATH = "Share/Item/Item.tab"
local TABLE_BUY_ASSET_PATH = "Share/Item/BuyAsset.tab"
local TABLE_BUY_ASSET_CONFIG_PATH = "Share/Item/BuyAssetConfig.tab"
local TABLE_UI_BUY_ASSET_PATH = "Share/Item/UiBuyAsset.tab"
local TABLE_ITEM_COLLECTION_PATH = "Share/ItemCollection/ItemCollection.tab"

local BuyAssetTemplates = {}                    -- 购买资源配置表
local BuyAssetDailyLimit = {}                   -- 购买资源每日限制
local ItemTemplates = {}
local BuyAssetType = {}                         --购买资源的类型
local BuyAssetCanMutiply = {}                   --是否可以批量购买
local BuyAssetAutoClose = {}
local BuyAssetUis = {}                          -- 可以开启快捷购买的上一级Ui名
local BuyAssetTotalLimit = {}                   -- 最大购买数量限制
local BuyAssetBuyLimit = {}                     -- 单次购买数量限制
local BuyAssetTimeId = {}                       -- 购买时间限制
local BuyAssetIsRestrictFreeBuy = {}            -- 是否限制免费购买
-- local BuyAssetDiscountShow = {}                 -- 购买打折展示
local ItemCollectionTemplates = {}              -- 道具收藏配置表
local ItemCollectionDefaultCollect = {}         -- 默认解锁收藏道具

XItemConfigs.SuitAllType = {
    DefaultAll = 0,
    All = 1,
}

XItemConfigs.Quality = {
    One = 1,
    Two = 2,
    Three = 3,
    Four = 4,
    Five = 5,
    Six = 6,
}

XItemConfigs.FastTrading = {
    NotFastTrading = 0,
    CanFastTrading = 1,
}

XItemConfigs.ItemType = {
    Assert = 1 << 0, -- 资源
    Money = 1 << 1 | 1 << 0, -- 货币，包括金币和钻石
    Material = 1 << 2, -- 材料
    Fragment = 1 << 3, -- 碎片
    Gift = 1 << 4, -- 礼包
    WeaponFashion = 1 << 5, -- 武器时装增加时限道具
    DlcMaterial = 1 << 6, -- DlcHunt相关
    CardExp = 1 << 11 | 1 << 2, -- 卡牌exp
    EquipExp = 1 << 12 | 1 << 2, -- 装备exp 4100
    EquipExpNotInBag = 1 << 12 | 1 << 3, -- 装备exp(不显示在背包中) 4104
    EquipResonanace = 1 << 13 | 1 << 2, -- 装备共鸣道具
    FurnitureItem = 1 << 14 | 1 << 2, -- 家具图纸
    

    ExchangeMoney = 1 << 16 | 1 << 2, -- 兑换货币
    SpExchangeMoney = 1 << 17 | 1 << 2, -- 特殊兑换货币
    UnShow = 1 << 18 | 1 << 2, -- 不显示物品
    FavorGift = 1 << 19 | 1 << 2, -- 好感度礼物
    ActiveMoney = 1 << 20 | 1 << 2, -- 活动货币
    PlayingMoney = 1 << 21 | 1 << 2, -- 玩法货币
    PlayingItem = 1 << 22 | 1 << 2, -- 玩法系统道具
    TRPGItem = 1 << 23 | 1 << 2, --跑图系统道具
    PartnerExp = 1 << 25 | 1 << 2, -- 宠物exp
    DlcItem = 1 << 6 | 1 << 0, -- Dlc道具
}

-- 背包显示的材料
XItemConfigs.Materials = {
    XItemConfigs.ItemType.Gift,
    XItemConfigs.ItemType.CardExp,
    XItemConfigs.ItemType.EquipExp,
    XItemConfigs.ItemType.Material,
    XItemConfigs.ItemType.EquipResonanace,
    XItemConfigs.ItemType.ExchangeMoney,
    XItemConfigs.ItemType.SpExchangeMoney,
    XItemConfigs.ItemType.FavorGift,
    XItemConfigs.ItemType.ActiveMoney,
    XItemConfigs.ItemType.PlayingItem,
    XItemConfigs.ItemType.PartnerExp,
}

--背包页签类型
XItemConfigs.PageType = {
    Equip = 1, --武器
    SuitCover = 2, --意识套装封面
    Material = 3, --材料
    Fragment = 4, --碎片
    Awareness = 5, --意识
    Partner = 6, --伙伴
}

--收藏道具类型
XItemConfigs.ItemCollectionType = {
    --默认收藏
    DefaultCollect = 1,

    --奖励收藏
    RewardCollect = 2,
}

function XItemConfigs.Init()
    local itemTable = XTableManager.ReadByIntKey(TABLE_ITEM_PATH, XTable.XTableItem, "Id")

    for k, item in pairs(itemTable) do
        ItemTemplates[k] = XItemConfigs.CreateItemTemplate(item)
    end

    local bATemplates = XTableManager.ReadByIntKey(TABLE_BUY_ASSET_PATH, XTable.XTableBuyAsset, "Id")
    local bACTemplates = XTableManager.ReadByIntKey(TABLE_BUY_ASSET_CONFIG_PATH, XTable.XTableBuyAssetConfig, "Id")
    BuyAssetUis = XTableManager.ReadByIntKey(TABLE_UI_BUY_ASSET_PATH, XTable.XTableUiBuyAsset, "Id")

    for id, tab in pairs(bATemplates) do
        BuyAssetDailyLimit[id] = tab.DailyLimit
        BuyAssetType[id] = tab.ExchangeType
        BuyAssetCanMutiply[id] = tab.CanMutiply
        BuyAssetAutoClose[id] = tab.AutoClose
        BuyAssetTotalLimit[id] = tab.TotalLimit
        BuyAssetBuyLimit[id] = tab.BuyLimit
        BuyAssetTimeId[id] = tab.TimeId
        BuyAssetIsRestrictFreeBuy[id] = tab.IsRestrictFreeBuy
        -- BuyAssetDiscountShow[id] = tab.DiscountShow

        local configs = {}
        for _, config in pairs(tab.Config) do
            local buyConfig = bACTemplates[config]
            if not buyConfig then
                XLog.ErrorTableDataNotFound("XItemConfigs.Init", "BuyAssetConfig",
                TABLE_BUY_ASSET_CONFIG_PATH, "Id", tostring(config) .. "来自关联表" .. TABLE_BUY_ASSET_PATH .. "Id :" .. tostring(id) .. " 的Config")
                return
            end

            for _, consume in pairs(buyConfig.ConsumeId) do
                if not ItemTemplates[consume] then
                    local tmpStr = tostring(buyConfig.ConsumeId) .. "来自关联表" .. TABLE_BUY_ASSET_CONFIG_PATH .. "Id :" .. tostring(consume) .. " 的ConsumeId"
                    XLog.ErrorTableDataNotFound("XItemConfigs.Init", "Item", TABLE_ITEM_PATH, "Id", tmpStr)
                    return
                end
            end

            tableInsert(configs, bACTemplates[config])
        end

        tableSort(configs, function(a, b)
            return a.Times < b.Times
        end)

        BuyAssetTemplates[id] = configs
    end

    ItemCollectionDefaultCollect = {}
    ItemCollectionTemplates = XTableManager.ReadByIntKey(TABLE_ITEM_COLLECTION_PATH, XTable.XTableItemCollection, "Id")
    for id, template in pairs(ItemCollectionTemplates) do
        if template.Type == XItemConfigs.ItemCollectionType.DefaultCollect then
            tableInsert(ItemCollectionDefaultCollect, id)
        end
    end
end

function XItemConfigs.CreateItemTemplate(item)
    local template = XItemTemplate.New(item)

    if item.ItemType == XItemConfigs.ItemType.CardExp then
        template = XCharacterExpTemplate.New(template)
    elseif item.ItemType == XItemConfigs.ItemType.EquipExp or item.ItemType == XItemConfigs.ItemType.EquipExpNotInBag then
        template = XEquipExpTemplate.New(template)
    elseif item.ItemType == XItemConfigs.ItemType.Gift then
        template = XGiftTemplate.New(template)
    elseif item.ItemType == XItemConfigs.ItemType.PartnerExp then
        template = XPartnerExpTemplate.New(template)
    end

    return template
end

function XItemConfigs.GetItemTemplatePath()
    return TABLE_ITEM_PATH
end

function XItemConfigs.GetItemTemplates()
    return ItemTemplates
end

function XItemConfigs.GetBuyAssetDailyLimit()
    return BuyAssetDailyLimit
end

function XItemConfigs.GetBuyAssetTemplates()
    return BuyAssetTemplates
end

function XItemConfigs.GetBuyAssetTemplateById(id)
    return BuyAssetTemplates[id]
end

function XItemConfigs.GetBuyAssetType(id)
    return BuyAssetType[id]
end

function XItemConfigs.GetBuyAssetCanMutiply(id)
    return BuyAssetCanMutiply[id]
end

function XItemConfigs.GetBuyAssetLimit(id)
    return BuyAssetDailyLimit[id]
end

function XItemConfigs.GetBuyAssetAutoClose(id)
    return BuyAssetAutoClose[id]
end

function XItemConfigs.GetFastTrading(id)
    if not ItemTemplates[id] then
        return nil
    end

    return ItemTemplates[id].FastTrading
end

function XItemConfigs.GetUiBuyAsset()
    return BuyAssetUis
end

function XItemConfigs.GetItemNameById(id)
    if not ItemTemplates[id] then
        return ""
    end

    return ItemTemplates[id].Name
end

function XItemConfigs.GetItemIconById(id)
    if not ItemTemplates[id] then
        return nil
    end

    return ItemTemplates[id].Icon
end

function XItemConfigs.GetQualityById(id)
    if not ItemTemplates[id] then
        return nil
    end

    return ItemTemplates[id].Quality
end

function XItemConfigs.GetItemSubTypeParams(id)
    if not ItemTemplates[id] then
        return nil
    end

    return ItemTemplates[id].SubTypeParams
end

function XItemConfigs.GetBuyAssetTotalLimit(id)
    return BuyAssetTotalLimit[id] or 0
end

function XItemConfigs.GetBuyAssetBuyLimit(id)
    return BuyAssetBuyLimit[id] or 0
end

function XItemConfigs.GetBuyAssetTimeId(id) 
    return BuyAssetTimeId[id] or 0
end

function XItemConfigs.GetBuyAssetIsRestrictFreeBuy(id)
    return BuyAssetIsRestrictFreeBuy[id] or 0
end

-- function XItemConfigs.GetDiscountShow(id)
--     return BuyAssetDiscountShow[id] or 0
-- end

function XItemConfigs.GetDefaultCollectList()
    return ItemCollectionDefaultCollect
end 

function XItemConfigs.GetItemCollectTemplate(id)
    local template = ItemCollectionTemplates[id]
    if not template then
        XLog.ErrorTableDataNotFound("XItemConfigs.GetItemCollectTemplate", 
                "ItemCollection", TABLE_ITEM_COLLECTION_PATH, "Id", id)
        return {}
    end
    return template
end 