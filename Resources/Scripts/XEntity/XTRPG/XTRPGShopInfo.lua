local XTRPGShopItemInfo = require("XEntity/XTRPG/XTRPGShopItemInfo")

local type = type

local XTRPGShopInfo = XClass(nil, "XTRPGShopInfo")

local Default = {
    __Id = 0,   --商店Id
    __ItemInfos = {}
}

function XTRPGShopInfo:Ctor()
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end
end

function XTRPGShopInfo:UpdateDataItemInfo(data)
    if not data then return end
    self.__Id = data.Id
    for _, v in pairs(data.ItemInfos or {}) do
        if not self.__ItemInfos[v.Id] then
            self.__ItemInfos[v.Id] = XTRPGShopItemInfo.New()
        end
        self.__ItemInfos[v.Id]:UpdateData(v)
    end
end

function XTRPGShopInfo:GetId()
    return self.__Id
end

function XTRPGShopInfo:GetItemInfos()
    return self.__ItemInfos
end

function XTRPGShopInfo:AddItemBuyCount(itemId, count)
    if not self.__ItemInfos[itemId] then
        local data = {Id = itemId, Count = count}
        self.__ItemInfos[itemId] = XTRPGShopItemInfo.New()
        self.__ItemInfos[itemId]:UpdateData(data)
    else
        self.__ItemInfos[itemId]:AddCount(count)
    end
end

function XTRPGShopInfo:GetItemCount(id)
    return self.__ItemInfos[id] and self.__ItemInfos[id]:GetCount() or 0
end

return XTRPGShopInfo