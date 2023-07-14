local type = type

local XTRPGShopItemInfo = XClass(nil, "XTRPGShopItemInfo")

local Default = {
    __Id = 0,   --道具Id
    __Count = 0,    --已购买的数量 
}

function XTRPGShopItemInfo:Ctor(data)
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end
end

function XTRPGShopItemInfo:UpdateData(data)
    if not data then return end
    self.__Id = data.Id
    self.__Count = data.Count
end

function XTRPGShopItemInfo:GetId()
    return self.__Id
end

function XTRPGShopItemInfo:AddCount(count)
    self.__Count = self.__Count + count
end

function XTRPGShopItemInfo:GetCount()
    return self.__Count
end

return XTRPGShopItemInfo