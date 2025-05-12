local XGoldenMinerRankPlayerInfo = require("XModule/XGoldenMiner/Data/Rank/XGoldenMinerRankPlayerInfo")
--黄金矿工排行榜数据
---@class XGoldenMinerRankDb
local XGoldenMinerRankDb = XClass(nil, "XGoldenMinerRankDb")

function XGoldenMinerRankDb:Ctor()
    self._Ranking = 0           --自己排名
    self._TotalCount = 0        --排行榜总人数
    ---@type XGoldenMinerRankPlayerInfo[]
    self._RankPlayerInfos = {}  --排行榜列表
    ---@type XGoldenMinerRankPlayerInfo
    self._MyRankPlayInfo = XGoldenMinerRankPlayerInfo.New()
end

---@param mainDb XGoldenMinerDataDb
function XGoldenMinerRankDb:UpdateData(data, mainDb)
    self._Ranking = data.Ranking
    self._TotalCount = data.TotalCount
    self._MyRankPlayInfo:UpdateData({
        Id = XPlayer.Id,
        Name = XPlayer.Name,
        HeadPortraitId = XPlayer.CurrHeadPortraitId,
        HeadFrameId = XPlayer.CurrHeadFrameId,
        Score = mainDb:GetTotalMaxScores(),
        CharacterId = mainDb:GetTotalMaxScoresCharacter(),
        Hexes = mainDb:GetTotalMaxScoresHexes(),
        Rank = self._Ranking,
    })
    self:UpdateRankPlayerInfos(data.RankPlayerInfos)
end

function XGoldenMinerRankDb:UpdateRankPlayerInfos(rankPlayerInfos)
    self._RankPlayerInfos = {}
    for i, v in ipairs(rankPlayerInfos) do
        ---@type XGoldenMinerRankPlayerInfo
        local rankPlayerInfo = XGoldenMinerRankPlayerInfo.New()
        v.Rank = i
        rankPlayerInfo:UpdateData(v)
        self._RankPlayerInfos[i] = rankPlayerInfo
    end
end

function XGoldenMinerRankDb:GetRanking()
    return self._Ranking
end

function XGoldenMinerRankDb:GetTotalCount()
    return self._TotalCount
end

function XGoldenMinerRankDb:GetRankPlayerInfos()
    return self._RankPlayerInfos
end

function XGoldenMinerRankDb:GetMyRankPlayInfo()
    return self._MyRankPlayInfo
end

return XGoldenMinerRankDb