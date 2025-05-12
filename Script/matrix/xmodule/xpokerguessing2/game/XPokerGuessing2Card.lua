---@class XPokerGuessing2Card
local XPokerGuessing2Card = XClass(nil, "XPokerGuessing2Card")

function XPokerGuessing2Card:Ctor(uid, id)
    self._Uid = uid
    self._Id = id or 0
    self._IsSelected = false
end

function XPokerGuessing2Card:GetId()
    return self._Id
end

function XPokerGuessing2Card:Set(id)
    self._Id = id
end

function XPokerGuessing2Card:SetSelected(value)
    self._IsSelected = value
end

function XPokerGuessing2Card:Reset()
    self._Id = 0
end

---@param model XPokerGuessing2Model
function XPokerGuessing2Card:GetUiData(model, smallIcon)
    local icon
    if smallIcon then
        icon = model:GetPokerGuessing2CardSmallAssetPathById(self._Id)
    else
        icon = model:GetPokerGuessing2CardFrontAssetPathById(self._Id)
    end
    ---@class XUiPokerGuessing2CardData
    local data = {
        Id = self._Id,
        Icon = icon,
        Uid = self._Uid
    }
    return data
end

---@param model XPokerGuessing2Model
function XPokerGuessing2Card:GetName(model)
    local config = model:GetPokerGuessing2CardConfigById(self._Id)
    if config then
        return config.Name
    end
end

function XPokerGuessing2Card:GetUid()
    return self._Uid
end

function XPokerGuessing2Card:IsEmpty()
    return self._Id == 0
end

function XPokerGuessing2Card:IsSelected()
    return self._IsSelected
end

return XPokerGuessing2Card