--######################## XAShopItem ########################
local XAShopItem = XClass(nil, "XAShopItem")

--[[
    public int Uid;

    //招募券，道具, XBiancaTheatreConfigs.XBiancaTheatreNodeShopItemType
    public int ItemType;

    //道具ID
    public int ItemId;

    //招募券ID
    public int TicketId;

    //原价
    public int Price;

    //是否已购买
    public int IsBuy;

    //0、已解锁；1、还没解锁；2、随机不出物品
    public int IsLock;

    //打折后价格
    public int DiscountPrice;
]]
function XAShopItem:Ctor(data)
    self.Data = data
end

function XAShopItem:GetIsLock()
    return XTool.IsNumberValid(self.Data.IsLock)
end

function XAShopItem:GetIsSellOut()
    return self.Data.IsLock == 2
end

function XAShopItem:GetIsCanBuy()
    return self.Data.IsBuy <= 0
end

function XAShopItem:FinishBuy()
    self.Data.IsBuy = 1
end

function XAShopItem:GetIcon()
    return XBiancaTheatreConfigs.GetRewardTypeIcon(self:GetItemType())
end

function XAShopItem:GetItemType()
    return self.Data.ItemType
end

function XAShopItem:GetDiscountPrice()
    return self.Data.DiscountPrice
end

function XAShopItem:GetPrice()
    return self.Data.Price
end

function XAShopItem:IsShowDiscountRate()
    return self:GetDiscountPrice() ~= self:GetPrice()
end

function XAShopItem:GetCount()
    return 1
end

function XAShopItem:GetItemId()
    local itemType = self:GetItemType()
    if itemType == XBiancaTheatreConfigs.XBiancaTheatreNodeShopItemType.Item then
        return self.Data.ItemId
    elseif itemType == XBiancaTheatreConfigs.XBiancaTheatreNodeShopItemType.Ticket then
        return self.Data.TicketId
    end
    return nil
end

function XAShopItem:GetName()
    local itemId = self:GetItemId()
    local itemType = self:GetItemType()
    if itemType == XBiancaTheatreConfigs.XBiancaTheatreNodeShopItemType.Item then
        return XBiancaTheatreConfigs.GetItemName(itemId)
    elseif itemType == XBiancaTheatreConfigs.XBiancaTheatreNodeShopItemType.Ticket then
        return XBiancaTheatreConfigs.GetRecruitTicketName(itemId)
    end
end

function XAShopItem:GetDesc()
    local itemId = self:GetItemId()
    local itemType = self:GetItemType()
    if itemType == XBiancaTheatreConfigs.XBiancaTheatreNodeShopItemType.Item then
        return XBiancaTheatreConfigs.GetItemDescription(itemId)
    elseif itemType == XBiancaTheatreConfigs.XBiancaTheatreNodeShopItemType.Ticket then
        return XBiancaTheatreConfigs.GetRecruitTicketDesc(itemId)
    end
end

function XAShopItem:GetItemIcon()
    local itemId = self:GetItemId()
    local itemType = self:GetItemType()
    if itemType == XBiancaTheatreConfigs.XBiancaTheatreNodeShopItemType.Item then
        return XBiancaTheatreConfigs.GetItemIcon(itemId)
    elseif itemType == XBiancaTheatreConfigs.XBiancaTheatreNodeShopItemType.Ticket then
        return XBiancaTheatreConfigs.GetRecruitTicketIcon(itemId)
    end
end

function XAShopItem:GetQuality()
    local itemId = self:GetItemId()
    local itemType = self:GetItemType()
    if itemType == XBiancaTheatreConfigs.XBiancaTheatreNodeShopItemType.Item then
        return XBiancaTheatreConfigs.GetTheatreItemQuality(itemId)
    elseif itemType == XBiancaTheatreConfigs.XBiancaTheatreNodeShopItemType.Ticket then
        return XBiancaTheatreConfigs.GetRecruitTicketQuality(itemId)
    end
end

function XAShopItem:IsShowTag()
    local itemType = self:GetItemType()
    if itemType == XBiancaTheatreConfigs.XBiancaTheatreNodeShopItemType.Ticket then
        return XBiancaTheatreConfigs.IsShowRecruitTicketSpecialTag(self:GetItemId())
    end
    return false
end

function XAShopItem:GetItemUid()
    return self.Data.Uid
end

--######################## XAShopNode ########################
local XANode = require("XEntity/XBiancaTheatre/Adventure/Node/XANode")
local XAShopNode = XClass(XANode, "XAShopNode")

function XAShopNode:Ctor()
    self.ShopNodeConfig = nil
    self.ShopItems = nil
    -- 节点事件配置
    self.EventClientConfig = nil
end

function XAShopNode:InitWithServerData(data)
    XAShopNode.Super.InitWithServerData(self, data)
    self.ShopItems = {}
    for _, data in ipairs(data.ShopItems) do
        table.insert(self.ShopItems, XAShopItem.New(data))
    end
    self.ShopNodeConfig = XBiancaTheatreConfigs.GetBiancaTheatreNodeShop(data.ShopId, true)
    -- 节点事件配置
    self.EventClientConfig = XBiancaTheatreConfigs.GetBiancaTheatreShopNodeClient(data.ShopId)
end

-- 获取商品
function XAShopNode:GetShopItems()
    return self.ShopItems
end

-- 获取描述
function XAShopNode:GetDesc()
    return self.ShopNodeConfig.Desc
end

function XAShopNode:GetTitleContent()
    return self.ShopNodeConfig.TitleContent
end

function XAShopNode:GetRoleIcon()
    return self.ShopNodeConfig.RoleIcon
end

function XAShopNode:GetRoleName()
    return self.ShopNodeConfig.RoleName
end

function XAShopNode:GetRoleContent()
    return self.ShopNodeConfig.RoleContent
end

-- 获取结束描述
function XAShopNode:GetEndDesc()
    return self.ShopNodeConfig.EndDesc
end

function XAShopNode:GetEndComfirmText()
    return self.ShopNodeConfig.EndComfirmText
end

function XAShopNode:GetBgAsset()
    return self.ShopNodeConfig.BgAsset
end

function XAShopNode:GetDiscountRate()
    return self.ShopNodeConfig.DiscountRate
end

function XAShopNode:Trigger(callback)
    XAShopNode.Super.Trigger(self, function()
        XLuaUiManager.Open("UiBiancaTheatreOutpost")
    end)
end

--局内商店购买
function XAShopNode:RequestBuyItem(shopItem, callback)
    local requestBody = {
        ShopItemUid = shopItem:GetItemUid(),    --唯一ID
    }
    if not XEntityHelper.CheckItemCountIsEnough(XBiancaTheatreConfigs.TheatreInnerCoin, shopItem:GetDiscountPrice()) then
        return
    end
    -- TheatreNodeShopBuyItemRequest
    XNetwork.CallWithAutoHandleErrorCode("BiancaTheatreNodeShopBuyItemRequest", requestBody, function(res)
        for _, item in ipairs(self.ShopItems) do
            if item:GetItemUid() == shopItem:GetItemUid() then
                item:FinishBuy()
                break
            end
        end
        if callback then callback() end
    end)
end

--结束购买（结束节点，商店节点）
function XAShopNode:RequestEndBuy(callback)
    XNetwork.CallWithAutoHandleErrorCode("BiancaTheatreEndNodeRequest", {}, function(res)
        if callback then callback() end
    end)
end

function XAShopNode:GetNodeTypeIcon()
    if self.EventClientConfig and self.EventClientConfig.NodeTypeIcon then
        return self.EventClientConfig.NodeTypeIcon
    end
    return XAShopNode.Super.GetNodeTypeIcon(self)
end

function XAShopNode:GetNodeTypeDesc()
    if self.EventClientConfig and self.EventClientConfig.NodeTypeDesc then
        return self.EventClientConfig.NodeTypeDesc
    end
    return XAShopNode.Super.GetNodeTypeDesc(self)
end

function XAShopNode:GetNodeTypeName()
    if self.EventClientConfig and self.EventClientConfig.NodeTypeName then
        return self.EventClientConfig.NodeTypeName
    end
    return XAShopNode.Super.GetNodeTypeName(self)
end

function XAShopNode:GetNodeTypeSmallIcon()
    return self.EventClientConfig and self.EventClientConfig.SmallIcon or XAShopNode.Super.GetNodeTypeSmallIcon(self)
end

return XAShopNode