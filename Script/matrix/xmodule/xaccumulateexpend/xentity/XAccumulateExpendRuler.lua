---@class XAccumulateExpendRuler
local XAccumulateExpendRuler = XClass(nil, "XAccumulateExpendRuler")

function XAccumulateExpendRuler:Ctor(title, desc)
    self:SetData(title, desc)
end

function XAccumulateExpendRuler:SetData(title, desc)
    self._Title = title or ""
    self._Desc = desc or ""
end

function XAccumulateExpendRuler:GetTitle()
    return self._Title
end

function XAccumulateExpendRuler:GetDesc()
    return self._Desc
end

return XAccumulateExpendRuler