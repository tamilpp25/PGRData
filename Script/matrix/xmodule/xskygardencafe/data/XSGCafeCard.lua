---@class XSGCafeCard 卡牌数据
local XSGCafeCard = XClass(nil, "XSGCafeCard")

function XSGCafeCard:Ctor(id)
    self._Id = id
    self._Count = 0
    self._Unlock = false
end

function XSGCafeCard:Count()
    return self._Count
end

function XSGCafeCard:PreviewCount(count)
    return math.max(0, self._Count - count)
end

function XSGCafeCard:Remove()
    self._Count = self._Count - 1
end

function XSGCafeCard:Add()
    self._Count = self._Count + 1
    self:Unlock()
end

function XSGCafeCard:GetId()
    return self._Id
end

function XSGCafeCard:SetCount(count)
    self._Count = count
    self:Unlock()
end

function XSGCafeCard:Unlock()
    if self._Unlock then
        return
    end
    if self._Count <= 0 then
        return
    end
    self._Unlock = true
end

function XSGCafeCard:IsUnlock()
    return self._Unlock
end

---@return XSGCafeCard
function XSGCafeCard:Clone()
    ---@type XSGCafeCard
    local card = XSGCafeCard.New(self._Id)
    card:SetCount(self._Count)
    
    return card
end

---@param o XSGCafeCard
function XSGCafeCard:Equal(o)
    if not o then
        return false
    end
    if o:GetId() ~= self._Id then
        return false
    end
    return true
end

---@param o XSGCafeCard
function XSGCafeCard:Copy(o)
    if not self:Equal(o) then
        XLog.Error("无法复制，卡牌Id不一致！！")
        return
    end
    self:SetCount(o:Count())
end

return XSGCafeCard