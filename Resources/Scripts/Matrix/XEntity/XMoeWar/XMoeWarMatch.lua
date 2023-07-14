local XMoeWarMatch = XClass(nil, "XMoeWarMatch")

local tableInsert = table.insert
local tableSort = table.sort
local stringFormat = string.format
local pairs = pairs
local ipairs = ipairs
local CsXTextManagerGetText = CS.XTextManager.GetText
local VoteEndShiftTime = CS.XGame.ClientConfig:GetInt("MoeWarVoteEndShiftTime")

local Default = {
    -- 赛事基本信息
    LastRefreshTime = 0,
    RefreshTimeStr = nil,
}

function XMoeWarMatch:Ctor(Id)
    for key in pairs(Default) do
        self[key] = Default[key]
    end

    self.PlayerVoteDic = {}
    self.PairList = {}
    self:LoadMatchCfg(Id)
end

function XMoeWarMatch:LoadMatchCfg(Id)
    self.Id = Id
    self.Cfg = XMoeWarConfig.GetMatch(Id)
end

function XMoeWarMatch:UpdateInfo(data)
    for i, playerInfo in ipairs(data.Players) do
        self.PlayerVoteDic[playerInfo.PlayerId] = playerInfo.VoteShow
    end

    -- 服务端定义的数据结构
    --public class XMoeWarPlayerPair <==> pairInfo
    --{
    --    public int WinnerId;
    --    public int SecondId;
    --    public List<int> Players = new List<int>();
    --}

    self.PairList = {}
    for _, pairInfo in ipairs(data.Pairs) do
        for _, playerId in ipairs(pairInfo.Players) do
            local player = XDataCenter.MoeWarManager.GetPlayer(playerId)
            if player then
                player:UpdateMatchVote(self, self.PlayerVoteDic[playerId], pairInfo)
            end
        end
		table.sort(pairInfo.Players,function(a,b) 
				return a < b
			end)
        tableInsert(self.PairList, pairInfo)
    end
end

function XMoeWarMatch:GetName()
    return self.Cfg.MatchName
end

function XMoeWarMatch:GetSubName()
    return self.Cfg.MatchSubName
end

function XMoeWarMatch:GetType()
    return self.Cfg.Type
end

function XMoeWarMatch:GetInTime(isRealTime)
    local nowTime = XTime.GetServerNowTimestamp()
    return nowTime >= self:GetStartTime() and nowTime <= self:GetEndTime(isRealTime)
end

function XMoeWarMatch:GetNotOpen()
    local nowTime = XTime.GetServerNowTimestamp()
    return nowTime <= self:GetStartTime()
end

function XMoeWarMatch:GetIsEnd(isRealTime)
    local nowTime = XTime.GetServerNowTimestamp()
    return nowTime >= self:GetEndTime(isRealTime)
end

function XMoeWarMatch:GetVoteEnd()
    if self.Cfg.Type == XMoeWarConfig.MatchType.Voting then
        return XTime.GetServerNowTimestamp() >= self:GetEndTime()
    end
    local twin = XDataCenter.MoeWarManager.GetVoteMatch(self:GetSessionId())
    return twin:GetIsEnd()
end

function XMoeWarMatch:GetResultOut()
    local match = XDataCenter.MoeWarManager.GetMatch(self:GetSessionId())
    if match:GetType()  == XMoeWarConfig.MatchType.Publicity then
        return true
    end
    return false
end

function XMoeWarMatch:GetDailyLimitCount()
	return CS.XGame.Config:GetInt("MoeWarDailyVoteLimit")
end

function XMoeWarMatch:GetStartTime()
    return XFunctionManager.GetStartTimeByTimeId(self.Cfg.TimeId) or 0
end

-- isRealTime : true则返回配置里定义的时间，否则投票期返回减去统计所需时间
function XMoeWarMatch:GetEndTime(isRealTime)
    if not isRealTime and self.Cfg.Type == XMoeWarConfig.MatchType.Voting then
        local endTime = XFunctionManager.GetEndTimeByTimeId(self.Cfg.TimeId)
        return endTime and endTime - VoteEndShiftTime or 0
    else
        return XFunctionManager.GetEndTimeByTimeId(self.Cfg.TimeId) or 0
    end
end

function XMoeWarMatch:GetSessionId()
    return self.Cfg.SessionId
end

function XMoeWarMatch:GetRefreshVoteTimeInDay()
    return self.Cfg.RefreshVoteHour
end

function XMoeWarMatch:GetCoverImg()
    return self.Cfg.CoverImg
end

function XMoeWarMatch:GetPairList()
    return self.PairList
end

function XMoeWarMatch:GetDesc()
	return self.Cfg.Des
end

function XMoeWarMatch:GetFinalImg()
    return self.Cfg.FinalImg
end

function XMoeWarMatch:GetPairListByGroupId(groupId)
    local groupPairList = {}
    for i = 1,#self.PairList do
        local id = XMoeWarConfig.GetPlayerGroup(self.PairList[i].Players[1])
        if groupId == id then
            tableInsert(groupPairList,self.PairList[i])
        end
    end
    return groupPairList
end

function XMoeWarMatch:GetRefreshVoteText()
    if self.Cfg.Type == XMoeWarConfig.MatchType.Publicity then
        return ""
    end

    if not self.RefreshTimeStr then
        local refreshTimeStrList = {}
        for i, v in ipairs(self.Cfg.RefreshVoteHour) do
            refreshTimeStrList[i] = CsXTextManagerGetText("MoeWarMatchVoteRefreshTimeUnit", v)
        end
        self.RefreshTimeStr = table.concat(refreshTimeStrList, CsXTextManagerGetText("MoeWarMatchVoteRefreshTimeSplit"))
    end

    return CsXTextManagerGetText("MoeWarMatchVoteRefresh", self.RefreshTimeStr)
end

return XMoeWarMatch