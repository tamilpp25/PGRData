local XTRPGShopInfo = require("XEntity/XTRPG/XTRPGShopInfo")

local type = type

local XTRPGClientShopInfo = XClass(XTRPGShopInfo, "XTRPGShopInfo")

local DefaultMain = {
    __DisCount = 100,     --打折
    __AddBuyCount = 0,  --增加购买上限
}

function XTRPGClientShopInfo:Ctor()
    for key, value in pairs(DefaultMain) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end
end

function XTRPGClientShopInfo:UpdateData(data)
    if not data then return end
    if data.DisCount then
        self.__DisCount = data.DisCount
    end
    if data.AddBuyCount then
        self.__AddBuyCount = data.AddBuyCount
    end
    self:UpdateDataItemInfo(data)
end

function XTRPGClientShopInfo:GetDisCount()
    return self.__DisCount
end

function XTRPGClientShopInfo:GetAddBuyCount()
    return self.__AddBuyCount
end

return XTRPGClientShopInfo