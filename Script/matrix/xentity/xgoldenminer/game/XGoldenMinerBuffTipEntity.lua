--地图抓取物数据
---@class XGoldenMinerBuffTipEntity
local XGoldenMinerBuffTipEntity = XClass(nil, "XGoldenMinerBuffTipEntity")

function XGoldenMinerBuffTipEntity:Ctor(itemId)
    self.ItemId = itemId
    self.IsDie = false
    self.CurTime = 3
    self.ShowParam = 0
end

function XGoldenMinerBuffTipEntity:ResetStatus()
    self.IsDie = false
    self.CurTime = 3
end

function XGoldenMinerBuffTipEntity:GetTipType()
    return XGoldenMinerConfigs.GetItemTipsType(self.ItemId)
end

function XGoldenMinerBuffTipEntity:GetBuffId()
    return XGoldenMinerConfigs.GetItemBuffId(self.ItemId)
end

function XGoldenMinerBuffTipEntity:GetBuffType()
    return XGoldenMinerConfigs.GetBuffType(self:GetBuffId())
end

function XGoldenMinerBuffTipEntity:GetBuffTipTxt()
    local txt = XGoldenMinerConfigs.GetItemTipsTxt(self.ItemId)
    if string.IsNilOrEmpty(txt) then
        return XGoldenMinerConfigs.GetItemDescribe(self.ItemId)
    end
    self.ShowParam = math.ceil(self.ShowParam)
    if self:GetTipType() == XGoldenMinerConfigs.BuffTipType.Once then
        return string.format(txt, self.ShowParam)
    elseif self:GetTipType() == XGoldenMinerConfigs.BuffTipType.UntilDie then
        local buffTimeType = XGoldenMinerConfigs.GetBuffTimeType(self:GetBuffId())
        if buffTimeType == XGoldenMinerConfigs.BuffTimeType.Time then
            return string.format(txt, self.ShowParam)
        elseif buffTimeType == XGoldenMinerConfigs.BuffTimeType.Count then
            return string.format(txt, self.ShowParam)
        end
    end
    return XGoldenMinerConfigs.GetBuffType(self:GetBuffId())
end

return XGoldenMinerBuffTipEntity