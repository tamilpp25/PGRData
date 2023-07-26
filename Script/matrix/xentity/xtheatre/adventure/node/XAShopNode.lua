--######################## XAShopItem ########################
local XAShopItem = XClass(nil, "XAShopItem")

--[[
    {
        ["Skills"] = { },
        ["Count"] = 5,
        ["Price"] = 200,
        ["IsBuy"] = 0,
        ["ItemType"] = 4,
        ["PowerId"] = 0,
    }
]]
function XAShopItem:Ctor(data)
    self.Data = data
end

function XAShopItem:UpdatePowerId(value)
    self.Data.PowerId = value
end

function XAShopItem:GetPowerId()
    return self.Data.PowerId
end

function XAShopItem:UpdateSkills(value)
    self.Data.Skills = value
end

function XAShopItem:GetIsCanBuy()
    return self.Data.IsBuy <= 0
end

function XAShopItem:FinishBuy()
    self.Data.IsBuy = 1
end

function XAShopItem:GetIcon()
    return XTheatreConfigs.GetRewardTypeIcon(self.Data.ItemType, self.Data.PowerId)
end

function XAShopItem:GetItemType()
    return self.Data.ItemType
end

function XAShopItem:GetPrice()
    return self.Data.Price
end

function XAShopItem:GetCount()
    return self.Data.Count
end

function XAShopItem:GetSkillIds()
    return self.Data.Skills
end

function XAShopItem:GetItemId()
    if self.Data.ItemType == XTheatreConfigs.AdventureRewardType.Decoration then
        return XTheatreConfigs.TheatreDecorationCoin
    elseif self.Data.ItemType == XTheatreConfigs.AdventureRewardType.PowerFavor then
        return XTheatreConfigs.TheatreFavorCoin
    end
    return nil
end

function XAShopItem:GetName()
    return XTheatreConfigs.GetRewardTypeName(self.Data.ItemType, self.Data.PowerId)
end

function XAShopItem:GetDesc()
    return XTheatreConfigs.GetClientConfig("SpecialRewardDesc", self.Data.ItemType)
end

--######################## XAShopNode ########################
local XANode = require("XEntity/XTheatre/Adventure/Node/XANode")
local XAShopNode = XClass(XANode, "XAShopNode")

function XAShopNode:Ctor()
    self.ShopNodeConfig = nil
    self.ShopItems = nil
end

function XAShopNode:InitWithServerData(data)
    XAShopNode.Super.InitWithServerData(self, data)
    self.ShopItems = {}
    for _, data in ipairs(data.ShopItems) do
        table.insert(self.ShopItems, XAShopItem.New(data))
    end
    self.ShopNodeConfig = XTheatreConfigs.GetTheatreNodeShop(data.ConfigId)
end

-- 获取商品
function XAShopNode:GetShopItems()
    return self.ShopItems
end

-- 获取描述
function XAShopNode:GetDesc()
    return self.ShopNodeConfig.Desc
end

function XAShopNode:GetTitle()
    return self.ShopNodeConfig.Title
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

function XAShopNode:Trigger(callback)
    XAShopNode.Super.Trigger(self, function()
        local skillItem = nil
        for i, item in ipairs(self.ShopItems) do
            if item:GetItemType() == XTheatreConfigs.AdventureRewardType.SelectSkill then
                skillItem = item
                break
            end
        end
        if skillItem then
            XDataCenter.TheatreManager.GetCurrentAdventureManager():RequestOpenSkill(function(res)
                skillItem:UpdatePowerId(res.PowerId)
                skillItem:UpdateSkills(res.Skills)
                -- 打开页面
                XLuaUiManager.Open("UiTheatreOutpost")
            end)
        else
            XLuaUiManager.Open("UiTheatreOutpost")
        end
    end)
end

function XAShopNode:RequestBuyItem(shopItem, callback)
    local requestBody = {
        Type = shopItem:GetItemType(),
    }
    if not XEntityHelper.CheckItemCountIsEnough(XTheatreConfigs.TheatreCoin, shopItem:GetPrice()) then
        return
    end
    -- TheatreNodeShopBuyItemRequest
    XNetwork.CallWithAutoHandleErrorCode("TheatreNodeShopBuyItemRequest", requestBody, function(res)
        for _, item in ipairs(self.ShopItems) do
            if item:GetItemType() == shopItem:GetItemType() then
                item:FinishBuy()
                break
            end
        end
        if callback then callback() end
    end)
end

function XAShopNode:RequestEndBuy(callback)
    XNetwork.CallWithAutoHandleErrorCode("TheatreEndNodeRequest", {}, function(res)
        if callback then callback() end
    end)
end

return XAShopNode