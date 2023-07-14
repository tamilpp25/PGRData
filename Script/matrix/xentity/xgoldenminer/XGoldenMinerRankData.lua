local XGoldenMinerRankPlayerInfo = require("XEntity/XGoldenMiner/XGoldenMinerRankPlayerInfo")
local type = type

--黄金矿工排行榜数据
local XGoldenMinerRankData = XClass(nil, "XGoldenMinerRankData")

local Default = {
    _Ranking = 0, --自己排名
    _TotalCount = 0, --排行榜总人数
    _RankPlayerInfos = {}, --排行榜列表
}

function XGoldenMinerRankData:Ctor()
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end
    self._MyRankPlayInfo = XGoldenMinerRankPlayerInfo.New()
end

function XGoldenMinerRankData:UpdateData(data)
    local dataDb = XDataCenter.GoldenMinerManager.GetGoldenMinerDataDb()
    self._Ranking = data.Ranking
    self._TotalCount = data.TotalCount
    self._MyRankPlayInfo:UpdateData({
        Id = XPlayer.Id,
        Name = XPlayer.Name,
        HeadPortraitId = XPlayer.CurrHeadPortraitId,
        HeadFrameId = XPlayer.CurrHeadFrameId,
        Score = dataDb:GetTotalMaxScores(),
        CharacterId = dataDb:GetTotalMaxScoresCharacter(),
        Rank = self._Ranking
    })
    self:UpdateRankPlayerInfos(data.RankPlayerInfos)
end

function XGoldenMinerRankData:UpdateRankPlayerInfos(rankPlayerInfos)
    self._RankPlayerInfos = {}
    for i, v in ipairs(rankPlayerInfos) do
        local rankPlayerInfo = XGoldenMinerRankPlayerInfo.New()
        v.Rank = i
        rankPlayerInfo:UpdateData(v)
        self._RankPlayerInfos[i] = rankPlayerInfo
    end
end

function XGoldenMinerRankData:GetRanking()
    return self._Ranking
end

function XGoldenMinerRankData:GetTotalCount()
    return self._TotalCount
end

function XGoldenMinerRankData:GetRankPlayerInfos()
    return self._RankPlayerInfos
end

function XGoldenMinerRankData:GetMyRankPlayInfo()
    return self._MyRankPlayInfo
end

return XGoldenMinerRankData