---@class XReform2ndBuff
local XReform2ndBuff = XClass(nil, "XReform2ndBuff")

function XReform2ndBuff:Ctor(id)
    self._Id = id
end

function XReform2ndBuff:GetId()
    return self._Id
end

function XReform2ndBuff:GetName()
end

function XReform2ndBuff:GetPressure()
end

function XReform2ndBuff:GetDesc()
end

function XReform2ndBuff:GetIcon()
end

---@param buff XReform2ndBuff
function XReform2ndBuff:Equals(buff)
    if not buff then
        return false
    end
    return self._Id == buff:GetId()
end

return XReform2ndBuff
