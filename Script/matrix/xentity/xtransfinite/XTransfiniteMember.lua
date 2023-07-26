---@class XTransfiniteMember
local XTransfiniteMember = XClass(nil, "XTransfiniteMember")

function XTransfiniteMember:Ctor()
    self._Id = 0
    self._Hp = 0
    self._Sp = 0
    self:SetDefault()
end

function XTransfiniteMember:SetDefault()
    self._Hp = 100
    self._Sp = 0
end

function XTransfiniteMember:IsValid()
    return self._Id and self._Id > 0
end

function XTransfiniteMember:IsDead()
    return self._Hp <= 0
end

function XTransfiniteMember:SetId(value)
    self._Id = value
end

function XTransfiniteMember:GetId()
    return self._Id
end

function XTransfiniteMember:GetHp()
    return self._Hp
end

function XTransfiniteMember:GetSp()
    return self._Sp
end

function XTransfiniteMember:SetHp(value)
    self._Hp = value
end

function XTransfiniteMember:SetSp(value)
    self._Sp = value
end

return XTransfiniteMember
