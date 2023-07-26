--词缀, 其实就是给mob的buff
---@class XReform2ndAffix
local XReform2ndAffix = XClass(nil, "XReform2ndAffix")

function XReform2ndAffix:Ctor(id)
    self._Id = id
end

function XReform2ndAffix:GetId()
    return self._Id
end

function XReform2ndAffix:GetName()
    return XReform2ndConfigs.GetAffixName(self._Id)
end

function XReform2ndAffix:GetPressure()
    return XReform2ndConfigs.GetAffixPressure(self._Id)
end

function XReform2ndAffix:GetIcon()
    return XReform2ndConfigs.GetAffixIcon(self._Id)
end

function XReform2ndAffix:GetSimpleDesc()
    return XReform2ndConfigs.GetAffixSimpleDesc(self._Id)
end

function XReform2ndAffix:GetDesc()
    return XReform2ndConfigs.GetAffixDesc(self._Id)
end

---@param affix XReform2ndAffix
function XReform2ndAffix:Equals(affix)
    return self._Id == affix:GetId()
end

function XReform2ndAffix:IsHardMode()
    return XReform2ndConfigs.GetAffixIsHardMode(self._Id)
end

return XReform2ndAffix
