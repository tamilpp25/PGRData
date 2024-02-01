---@class XBossSingleSelfRankInfo
local XBossSingleSelfRankInfo = XClass(nil, "XBossSingleSelfRankInfo")

function XBossSingleSelfRankInfo:Ctor(data)
    self._IsEmpty = true
    self:SetData(data)
end

function XBossSingleSelfRankInfo:SetData(data)
    if data then
        self._IsEmpty = false
        self._Rank = data.Rank
        self._TotalRank = data.TotalRank
    end
end

function XBossSingleSelfRankInfo:SetRank(value)
    self._Rank = value
end

function XBossSingleSelfRankInfo:GetRank()
    return self._Rank
end

function XBossSingleSelfRankInfo:SetTotalRank(value)
    self._TotalRank = value
end

function XBossSingleSelfRankInfo:GetTotalRank()
    return self._TotalRank
end

function XBossSingleSelfRankInfo:GetIsEmpty()
    return self._IsEmpty
end

return XBossSingleSelfRankInfo