---@class XBossSingleRankCharacter
local XBossSingleRankCharacter = XClass(nil, "XBossSingleRankCharacter")

function XBossSingleRankCharacter:Ctor(data)
    self:SetData(data)
end

function XBossSingleRankCharacter:SetData(data)
    if data then
        self._Id = data.Id
        self._LiberateLv = data.LiberateLv

        if data.CharacterHeadInfo then
            self._HeadFashionId = data.CharacterHeadInfo.HeadFashionId
            self._HeadFashionType = data.CharacterHeadInfo.HeadFashionType
        else
            self._HeadFashionId = 0
            self._HeadFashionType = nil
        end
    end
end

function XBossSingleRankCharacter:GetId()
    return self._Id
end

function XBossSingleRankCharacter:GetLiberateLv()
    return self._LiberateLv
end

function XBossSingleRankCharacter:GetHeadFashionId()
    return self._HeadFashionId
end

function XBossSingleRankCharacter:GetHeadFashionType()
    return self._HeadFashionType
end

return XBossSingleRankCharacter
