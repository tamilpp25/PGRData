local Default = {
    _Type = 0, --属性类型（1-健康，2-饱腹，3-精神）
    _Value = 0, --属性值
    _Threshold = 0 --临界值（大于等于此值每日属性增加，否则减少）
}

--末日生存玩法-居民属性
local XDoomsdayAttribute = XClass(XDataEntityBase, "XDoomsdayAttribute")

function XDoomsdayAttribute:Ctor(attrType)
    self:Init(Default)

    self._Type = attrType
end

function XDoomsdayAttribute:SetProperty(name, value)
    if name == "_Value" then
        value = math.floor(value)
    end
    XDoomsdayAttribute.Super.SetProperty(self, name, value)
end

--是否处于不健康状态
function XDoomsdayAttribute:IsBad()
    --if self._Type == XDoomsdayConfigs.ATTRUBUTE_TYPE.SAN then
    --    return false
    --end
    return self._Value <= self._Threshold
end

return XDoomsdayAttribute
