---@class XTransfiniteEvent
local XTransfiniteEvent = XClass(nil, "XTransfiniteEvent")

function XTransfiniteEvent:Ctor(id)
    self._Id = id
end

---@param event XTransfiniteEvent
function XTransfiniteEvent:Equals(event)
    if not event then
        return false
    end
    return self:GetId() == event:GetId()
end

function XTransfiniteEvent:GetId()
    return self._Id
end

function XTransfiniteEvent:GetName()
    return XTransfiniteConfigs.GetStrengthenTitle(self._Id)
end

function XTransfiniteEvent:GetDesc()
    return XTransfiniteConfigs.GetStrengthenDes(self._Id)
end

function XTransfiniteEvent:GetIcon()
    return XTransfiniteConfigs.GetStrengthenImg(self._Id)
end

return XTransfiniteEvent
