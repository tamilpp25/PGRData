
---@class XSGCafeDeck 卡组
---@field _Cards table<number, XSGCafeCard>
---@field _CacheCards table<number, XSGCafeCard>
---@field _CardsList XSGCafeCard[]
local XSGCafeDeck = XClass(nil, "XSGCafeDeck")

local XSGCafeCard = require("XModule/XSkyGardenCafe/Data/XSGCafeCard")

local paris = pairs

function XSGCafeDeck:Ctor(id, zeroRemove)
    self._Id = id
    self._ZeroRemove = zeroRemove
    self._Cards = {}
    self._CacheCards = {}
    self._Dirty = false
    self._CardsList = false
end

function XSGCafeDeck:Sync()
    local dict = {}
    for k, _ in paris(self._CacheCards) do
        dict[k] = true
    end
    
    for k, v in paris(self._Cards) do
        local cache = self._CacheCards[k]
        if not v:Equal(cache) then
            cache = v:Clone()
        else
            cache:Copy(v)
        end
        self._CacheCards[k] = cache
        dict[k] = nil
    end
    if not XTool.IsTableEmpty(dict) then
        for k, _ in paris(dict) do
            self._CacheCards[k] = nil
        end
    end
end

function XSGCafeDeck:Restore()
    local dict = {}
    for k, _ in paris(self._Cards) do
        dict[k] = true
    end
    
    for k, v in paris(self._CacheCards) do
        local card = self._Cards[k]
        if not v:Equal(card) then
            card = v:Clone()
        else
            card:Copy(v)
        end
        self._Cards[k] = card
        dict[k] = nil
    end
    if not XTool.IsTableEmpty(dict) then
        for k, _ in paris(dict) do
            self._Cards[k] = nil
        end
    end
    self._Dirty = true
end

function XSGCafeDeck:UpdateCards(cardDict)
    if not cardDict then
        return
    end
    for id, count in paris(cardDict) do
        local card = self:GetOrAddCard(id)
        card:SetCount(count)
    end
    self:Sync()
end

function XSGCafeDeck:Insert(cardId)
    self._Dirty = true
    local card = self:GetOrAddCard(cardId)
    card:Add()
end

function XSGCafeDeck:RemoveAt(cardId)
    self._Dirty = true
    local card = self._Cards[cardId]
    if not card then
        return
    end
    card:Remove()
    if self._ZeroRemove and card:Count() <= 0 then
        self._Cards[cardId] = nil
    end
end

---@return XSGCafeCard[]
function XSGCafeDeck:GetCardList()
    if self._CardsList and not self._Dirty then
        return self._CardsList
    end
    local list = {}
    for _, card in paris(self._Cards) do
        if card:Count() > 0 then
            list[#list + 1] = card
        end
    end
    self._Dirty = false
    self._CardsList = list
    
    return list
end

function XSGCafeDeck:GetCardCount(cardId)
    local card = self._Cards[cardId]
    return card and card:Count() or 0
end

--- 获取卡组Id池, 多张卡牌时拆成单张
---@return number[]
--------------------------
function XSGCafeDeck:GetCardsPool()
    local list = {}
    for id, card in paris(self._Cards) do
        local count = card:Count()
        if count > 0 then
            for i = 1, count do
                list[#list + 1] = id
            end
        end
    end
    return list
end


--- 获取/添加卡牌
---@param cardId number  
---@return XSGCafeCard
--------------------------
function XSGCafeDeck:GetOrAddCard(cardId)
    local card = self._Cards[cardId]
    if not card then
        card = XSGCafeCard.New(cardId)
        self._Cards[cardId] = card
        self._Dirty = true
    end
    return card
end

function XSGCafeDeck:Total()
    local count = 0
    for _, card in paris(self._Cards) do
        count = count + card:Count()
    end
    return count
end

function XSGCafeDeck:IsSynced()
    for index, card in paris(self._Cards) do
        local cache = self._CacheCards[index]
        if not cache then
            return false
        end
        if cache:GetId() ~= card:GetId() then
            return false
        end

        if cache:Count() ~= card:Count() then
            return false
        end
    end
    return true
end

function XSGCafeDeck:IsEmpty()
    local count = self:Total()
    return count <= 0
end

function XSGCafeDeck:GetId()
    return self._Id
end

function XSGCafeDeck:Clear()
    self._Cards = {}
    self._Dirty = true
end

return XSGCafeDeck