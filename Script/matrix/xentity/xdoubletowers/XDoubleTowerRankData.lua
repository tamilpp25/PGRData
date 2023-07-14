local XDoubleTowerRankPlayer = require("XEntity/XDoubleTowers/XDoubleTowerRankPlayer")
local type = type

--动作塔防排行榜数据
local XDoubleTowerRankData = XClass(nil, "XDoubleTowerRankData")

local Default = {
    _Ranking = 0, --自己排名
    _MemberCount = 0, --排行榜总人数
}

function XDoubleTowerRankData:Ctor()
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end
    self.RankDic = {}   --key：活动Id，value：排行榜列表
    self._MyRankPlayInfo = XDoubleTowerRankPlayer.New()
end

function XDoubleTowerRankData:UpdateData(data)
    local baseInfo = XDataCenter.DoubleTowersManager.GetBaseInfo()
    self._Ranking = data.Ranking
    self._MemberCount = data.MemberCount
    self._MyRankPlayInfo:UpdateData({
        Id = XPlayer.Id,
        Name = XPlayer.Name,
        Head = XPlayer.CurrHeadPortraitId,
        Frame = XPlayer.CurrHeadFrameId,
        Level = XPlayer.GetLevel(),
        Sign = "",
        WinCount = baseInfo:GetSpecialStageWinCount(),
        Score = baseInfo:GetSpecialStageWinCount(),
        RoleId = 0,
        Rank = self._Ranking
    })
    self:UpdateRankPlayerInfos(data.Rank)
end

function XDoubleTowerRankData:UpdateRankPlayerInfos(rank)
    local activityId = rank.Id
    local rankPlayerInfos = rank.RankPlayer
    local rankPlayerInfosTemp = {}
    for i, v in ipairs(rankPlayerInfos) do
        local rankPlayerInfo = XDoubleTowerRankPlayer.New()
        v.Rank = i
        rankPlayerInfo:UpdateData(v)
        rankPlayerInfosTemp[i] = rankPlayerInfo
    end
    self.RankDic[activityId] = rankPlayerInfosTemp
end

function XDoubleTowerRankData:GetRanking()
    return self._Ranking
end

function XDoubleTowerRankData:GetMemberCount()
    return self._MemberCount
end

function XDoubleTowerRankData:GetRankPlayerInfos()
    local baseInfo = XDataCenter.DoubleTowersManager.GetBaseInfo()
    local activityId = baseInfo:GetActivityId()
    return self.RankDic[activityId] or {}
end

function XDoubleTowerRankData:GetMyRankPlayInfo()
    return self._MyRankPlayInfo
end

return XDoubleTowerRankData