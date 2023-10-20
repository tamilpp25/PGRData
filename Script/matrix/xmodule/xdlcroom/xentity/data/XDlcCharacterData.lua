---@class XDlcCharacterData
local XDlcCharacterData = XClass(nil, "XDlcCharacterData")

function XDlcCharacterData:Ctor(data)
    self._Id = nil
    self._CharacterId = nil
    self:SetData(data)
end

function XDlcCharacterData:SetData(data)
    self:_Init(data)
end

---@param other XDlcCharacterData
function XDlcCharacterData:Clone(other)
    self._Id = other._Id
    self._CharacterId = other._CharacterId
end

function XDlcCharacterData:GetCharacterId()
    return self._CharacterId
end

function XDlcCharacterData:GetId()
    return self._Id
end

function XDlcCharacterData:_Init(data)
    if data then
        self._Id = data.Id
        self._CharacterId = data.Character.Id
    end
end

return XDlcCharacterData