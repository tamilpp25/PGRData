---@class XPcgEffectSettle
local XPcgEffectSettle = XClass(nil, "XPcgEffectSettle")

function XPcgEffectSettle:Ctor()
    -- 效果配表Id
    ---@type number
    self.EffectId = 0
    -- 效果结算类型
    ---@type number
    self.EffectSettleType = 0
    
    self.Param1 = 0
    self.Param2 = 0
    self.Param3 = 0
    self.Param4 = 0
    self.Param5 = 0
end

function XPcgEffectSettle:RefreshData(data)
    self.EffectId = data.EffectId or 0
    self.EffectSettleType = data.EffectSettleType or 0
    self.Param1 = data.Param1 or 0
    self.Param2 = data.Param2 or 0
    self.Param3 = data.Param3 or 0
    self.Param4 = data.Param4 or 0
    self.Param5 = data.Param5 or 0
    self.Param6 = data.Param6 or 0
    self.Param7 = data.Param7 or 0
    self.CardList = data.CardList or {}
    self.CardIdxList = data.CardIdxList or {}
end

function XPcgEffectSettle:GetEffectId()
    return self.EffectId
end

function XPcgEffectSettle:GetEffectSettleType()
    return self.EffectSettleType
end

function XPcgEffectSettle:GetParams()
    return {self.Param1, self.Param2, self.Param3, self.Param4, self.Param5, self.Param6, self.Param7}
end

function XPcgEffectSettle:GetParam1()
    return self.Param1
end

function XPcgEffectSettle:GetParam2()
    return self.Param2
end

function XPcgEffectSettle:GetParam3()
    return self.Param3
end

function XPcgEffectSettle:GetParam4()
    return self.Param4
end

function XPcgEffectSettle:GetParam5()
    return self.Param5
end

function XPcgEffectSettle:GetParam6()
    return self.Param6
end

function XPcgEffectSettle:GetParam7()
    return self.Param7
end

function XPcgEffectSettle:GetCardList()
    return self.CardList
end

function XPcgEffectSettle:GetCardIdxList()
    return self.CardIdxList
end

function XPcgEffectSettle:ToString()
    return string.format("EffectId = %s, EffectSettleType = %s, Param1 = %s, Param2 = %s, Param3 = %s, Param4 = %s, Param5 = %s, Param6 = %s, Param7 = %s, CardList = %s, CardIdxList = %s", 
            self.EffectId, self.EffectSettleType, self.Param1, self.Param2, self.Param3, self.Param4, self.Param5, self.Param6, self.Param7, XLog.Dump(self.CardList), XLog.Dump(self.CardIdxList))
end

return XPcgEffectSettle