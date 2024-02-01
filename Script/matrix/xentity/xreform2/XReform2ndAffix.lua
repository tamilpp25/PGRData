--词缀, 其实就是给mob的buff
---@class XReform2ndAffix
local XReform2ndAffix = XClass(nil, "XReform2ndAffix")

function XReform2ndAffix:Ctor(id)
    self._Id = id
end

function XReform2ndAffix:GetId()
    return self._Id
end

---@param affix XReform2ndAffix
function XReform2ndAffix:Equals(affix)
    return self._Id == affix:GetId()
end

return XReform2ndAffix
