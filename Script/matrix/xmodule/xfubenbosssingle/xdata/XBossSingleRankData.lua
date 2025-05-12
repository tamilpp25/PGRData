local XBossSingleRankShowData = require("XModule/XFubenBossSingle/XData/XBossSingleRankShowData")

---@class XBossSingleRankData
local XBossSingleRankData = XClass(nil, "XBossSingleRankData")

function XBossSingleRankData:Ctor(data)
    self:SetData(data)
end

function XBossSingleRankData:SetData(data)
    if data then
        local maxCount = XMVCA.XFubenBossSingle:GetMaxRankCount()
        
        self._LeftTime = data.LeftTime
        self._RankNumber = data.RankNum
        self._Score = data.Score
        self._HistoryNumber = data.HistoryNum
        self._TotalCount = data.TotalCount
        ---@type XBossSingleRankShowData[]
        self._RankList = self._RankList or {}

        for i, rank in pairs(data.RankList) do
            if i > maxCount then
                break
            end
            
            local rankShow = self._RankList[i]

            if rankShow then
                rankShow:SetData(rank)
            else
                self._RankList[i] = XBossSingleRankShowData.New(rank)
            end
        end
        for i = #data.RankList + 1, #self._RankList do
            self._RankList[i] = nil
        end
    end
end

function XBossSingleRankData:GetLeftTime()
    return self._LeftTime
end

function XBossSingleRankData:GetRankNumber()
    return self._RankNumber
end

function XBossSingleRankData:GetScore()
    return self._Score
end

function XBossSingleRankData:GetHistoryNumber()
    return self._HistoryNumber
end

function XBossSingleRankData:GetTotalCount()
    return self._TotalCount
end

---@return XBossSingleRankShowData[]
function XBossSingleRankData:GetRankList()
    return self._RankList
end

---@return XBossSingleRankShowData
function XBossSingleRankData:GetRankByIndex(index)
    return self._RankList[index]
end

function XBossSingleRankData:GetRankListCount()
    return #self._RankList
end

function XBossSingleRankData:GetIsRankEmpty()
    return self:GetRankListCount() == 0
end

return XBossSingleRankData