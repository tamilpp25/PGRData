---@class XBossSingleStageHistory
local XBossSingleStageHistory = XClass(nil, "XBossSingleStageHistory")

function XBossSingleStageHistory:Ctor(data)
    self:SetData(data)
end

function XBossSingleStageHistory:SetData(data)
    if data then
        self._StageId = data.StageId
        self._Score = data.Score
        self._Characters = data.Characters
        self._Partners = data.Partners
    end
end

function XBossSingleStageHistory:GetStageId()
    return self._StageId
end

function XBossSingleStageHistory:GetScore()
    return self._Score
end

function XBossSingleStageHistory:GetCharacterList()
    return self._Characters
end 

function XBossSingleStageHistory:GetPartnerList()
    return self._Partners
end

return XBossSingleStageHistory