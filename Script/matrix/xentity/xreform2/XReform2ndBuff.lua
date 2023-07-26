---@class XReform2ndBuff
local XReform2ndBuff = XClass(nil, "XReform2ndBuff")

function XReform2ndBuff:Ctor(id)
    self._Id = id
end

function XReform2ndBuff:GetId()
    return self._Id
end

function XReform2ndBuff:GetName()
    return XReform2ndConfigs.GetBuffName(self._Id)
end

function XReform2ndBuff:GetPressure()
    return XReform2ndConfigs.GetBuffPressure(self._Id)
end

function XReform2ndBuff:GetDesc()
    return XReform2ndConfigs.GetBuffDesc(self._Id)
end

function XReform2ndBuff:GetIcon()
    return XReform2ndConfigs.GetBuffIcon(self._Id)
end

---@param buff XReform2ndBuff
function XReform2ndBuff:Equals(buff)
    if not buff then
        return false
    end
    return self._Id == buff:GetId()
end

return XReform2ndBuff
