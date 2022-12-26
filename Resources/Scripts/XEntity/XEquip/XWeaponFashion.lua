--[[
public sealed class XWeaponFashionData
{
    public int Id;
    public long ExpireTime;
    public List<int> UseCharacterList = new List<int>();
}
]]

local Default = {
    Id = 0,
    ExpireTime = 0,
    UseCharacterIdCheckTable = {},
}

local XWeaponFashion = XClass(nil, "XWeaponFashion")

function XWeaponFashion:Ctor(data)
    for key, v in pairs(Default) do
        self[key] = v
    end

    self:UpdateData(data)
end

function XWeaponFashion:UpdateData(data)
    self.Id = data.Id or self.Id
    self.ExpireTime = data.ExpireTime or self.ExpireTime

    self.UseCharacterIdCheckTable = {}
    for _, characterId in pairs(data.UseCharacterList) do
        self.UseCharacterIdCheckTable[characterId] = characterId
    end
end

function XWeaponFashion:GetId()
    return self.Id
end

function XWeaponFashion:GetLeftTime()
    local nowTime = XTime.GetServerNowTimestamp()
    local endTime = self.ExpireTime
    local leftTime = endTime - nowTime
    leftTime = leftTime > 0 and leftTime or 0
    return leftTime
end

function XWeaponFashion:Dress(characterId)
    self.UseCharacterIdCheckTable[characterId] = characterId
end

function XWeaponFashion:TakeOff(characterId)
    self.UseCharacterIdCheckTable[characterId] = nil
end

function XWeaponFashion:IsDressed(characterId)
    return self.UseCharacterIdCheckTable[characterId]
end

function XWeaponFashion:IsTimeLimit()
    return self.ExpireTime > 0
end

return XWeaponFashion