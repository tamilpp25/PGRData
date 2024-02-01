--地图抓取物数据
---@class XGoldenMinerBuffTipData
local XGoldenMinerBuffTipData = XClass(nil, "XGoldenMinerBuffTipData")

function XGoldenMinerBuffTipData:Ctor(itemId)
    self.ItemId = itemId
    self.IsDie = false
    self.CurTime = 3
    self.ShowParam = 0
end

function XGoldenMinerBuffTipData:ResetStatus()
    self.IsDie = false
    self.CurTime = 3
end

---@param control XGoldenMinerControl
function XGoldenMinerBuffTipData:GetTipType(control)
    return control:GetCfgItemTipsType(self.ItemId)
end

---@param control XGoldenMinerControl
function XGoldenMinerBuffTipData:GetBuffId(control)
    return control:GetCfgItemBuffId(self.ItemId)
end

---@param control XGoldenMinerControl
function XGoldenMinerBuffTipData:GetBuffType(control)
    return control:GetCfgBuffType(self:GetBuffId(control))
end

---@param control XGoldenMinerControl
function XGoldenMinerBuffTipData:GetBuffTipTxt(control)
    local txt = control:GetCfgItemTipsTxt(self.ItemId)
    if string.IsNilOrEmpty(txt) then
        return control:GetCfgItemDescribe(self.ItemId)
    end
    self.ShowParam = math.ceil(self.ShowParam)
    if self:GetTipType(control) == XEnumConst.GOLDEN_MINER.BUFF_TIP_TYPE.ONCE then
        return string.format(txt, self.ShowParam)
    elseif self:GetTipType(control) == XEnumConst.GOLDEN_MINER.BUFF_TIP_TYPE.UNTIL_DIE then
        local buffTimeType = control:GetCfgBuffTimeType(self:GetBuffId(control))
        if buffTimeType == XEnumConst.GOLDEN_MINER.BUFF_TIME_TYPE.TIME then
            return string.format(txt, self.ShowParam)
        elseif buffTimeType == XEnumConst.GOLDEN_MINER.BUFF_TIME_TYPE.COUNT then
            return string.format(txt, self.ShowParam)
        end
    end
    return control:GetCfgBuffType(self:GetBuffId(control))
end

return XGoldenMinerBuffTipData