---@class XMoeWarMatch
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

    self.Players = {}
    self.PairList = {}
    self:LoadMatchCfg(Id)
end

function XMoeWarMatch:LoadMatchCfg(Id)
    self.Id = Id
    self.Cfg = XMoeWarConfig.GetMatch(Id)
end

function XMoeWarMatch:UpdateInfo(data)
    --public class XMoeWarPlayer <==> data.Players
    --{
    --    public int PlayerId;
    --    public int GroupId;
    --    public long Vote;
    --    public long VoteShow;
    --}    
    for i, playerInfo in ipairs(data.Players) do
        self.Players[playerInfo.PlayerId] = playerInfo
    end

    -- 服务端定义的数据结构
    --public class XMoeWarPlayerPair <==> pairInfo
    --{
    --    public int WinnerId;
    --    public int SecondId;
    --    public List<int> Players = new List<int>();
    --    public int WarSituation;
    --}

    self.PairList = {}

    if self:GetSessionId() == XMoeWarConfig.SessionType.GameInAudition then
        for _, playerInfo in ipairs(data.Players) do
            local player = XDataCenter.MoeWarManager.GetPlayer(playerInfo.PlayerId)
            if player then
                player:UpdateMatchVote(self, playerInfo.VoteShow, {})
            end
        end
    end
    for _, pairInfo in ipairs(data.Pairs) do
        if self:GetSessionId() ~= XMoeWarConfig.SessionType.GameInAudition then
            for _, playerId in ipairs(pairInfo.Players) do
                local player = XDataCenter.MoeWarManager.GetPlayer(playerId)
                if player then
                    player:UpdateMatchVote(self, self.Players[playerId].VoteShow, pairInfo)
                end
            end 
        end
        table.sort(pairInfo.Players, function(a, b)
            return a < b
        end)
        tableInsert(self.PairList, pairInfo)
    end
    table.sort(self.PairList,function(a,b)
        local playerA = a.Players[1]
        local playerB = b.Players[1]
        local groupA = XMoeWarConfig.GetPlayerGroup(playerA)
        local groupB = XMoeWarConfig.GetPlayerGroup(playerB)

        return groupA < groupB
    end)

    local groupDic = {}
    for _, pair in pairs(self.PairList) do
        local playerA = pair.Players[1]
        local groupA = XMoeWarConfig.GetPlayerGroup(playerA)
        if not groupDic[groupA] then
            groupDic[groupA] = {}
        end
        table.insert(groupDic[groupA], pair)
    end
    self.PairList = {}
    for _, groupList in pairs(groupDic) do
        table.sort(groupList, function(a, b)
            return a.WarSituation < b.WarSituation
        end)
        for _, p in pairs(groupList) do
            table.insert(self.PairList, p)
        end
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

function XMoeWarMatch:GetPairList(isVotePanel)
    local pairList = {}
    if (self:GetSessionId() == XMoeWarConfig.SessionType.GameInAudition and self:GetType() == XMoeWarConfig.MatchType.Voting) or (self:GetSessionId() == XMoeWarConfig.SessionType.GameInAudition and isVotePanel) then
        local groupDic = {}
        for _, player in pairs(self.Players) do
            local pairInfo = {
                WinnerId = 0,
                SecondId = 0,
                Players = {
                    player.PlayerId
                },
                WarSituation = XMoeWarConfig.WarSituationType.Default
            }
            local group = XMoeWarConfig.GetPlayerGroup(player.PlayerId)
            if not groupDic[group] then
                groupDic[group] = {}
            end
            table.insert(groupDic[group], pairInfo)
        end
        for _, pList in pairs(groupDic) do
            table.sort(pList, function(a, b)
                local playerA = self.Players[a.Players[1]]
                local playerB = self.Players[b.Players[1]]
                if playerA.VoteShow ~= playerB.VoteShow then
                    return playerA.VoteShow > playerB.VoteShow
                end
                return a.Players[1] < b.Players[1]
            end)
            for _, pair in pairs(pList) do
                table.insert(pairList, pair)
            end
        end
    elseif self:GetSessionId() == XMoeWarConfig.SessionType.FailWeekVotingDown then
        for _, pair in pairs(self.PairList) do
            if pair.WarSituation == XMoeWarConfig.WarSituationType.FailGroup then
                table.insert(pairList,pair)
            end
        end
    else
        pairList = self.PairList
    end 
    return pairList
end

function XMoeWarMatch:GetPlayerList()
    return self.Players
end

function XMoeWarMatch:GetDesc()
	return self.Cfg.Des
end

function XMoeWarMatch:GetFinalImg()
    return self.Cfg.FinalImg
end

function XMoeWarMatch:GetPairListByGroupId(groupId,isVotePanel)
    local groupPairList = {}
    local pairList = self:GetPairList(isVotePanel)
    for i = 1,#pairList do
        local id = XMoeWarConfig.GetPlayerGroup(pairList[i].Players[1])
        if groupId == id then
            tableInsert(groupPairList,pairList[i])
        end
    end
    return groupPairList
end

function XMoeWarMatch:GetPlayerListByGroupId(groupId)
    local list = {}
    for index,v in pairs(self.Players) do
        if v.GroupId == groupId then
            tableInsert(list, v)
        end
    end
    table.sort(list, function(a, b)
        if a.VoteShow == b.VoteShow then
            return a.PlayerId < b.PlayerId
        end
        return a.VoteShow > b.VoteShow
    end)
    return list
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

--角色是否淘汰
function XMoeWarMatch:IsPlayerWeedOut(playerId)
    return not self.Players[playerId]
end

function XMoeWarMatch:GetId()
    return self.Id
end

return XMoeWarMatch