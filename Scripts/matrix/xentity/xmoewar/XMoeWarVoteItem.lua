local XMoeWarVoteItem = XClass(nil, "XMoeWarVoteItem")

function XMoeWarVoteItem:Ctor(id)
    self.Cfg = XMoeWarConfig.GetVoteItemById(id)
    self:InitDailyLimitData()
end

function XMoeWarVoteItem:InitDailyLimitData()
    self.DailyLimitDic = {}
    self.FailGroupLimitDic = {}
    for i = 1, #self.Cfg.MatchId do
        self.DailyLimitDic[self.Cfg.MatchId[i]] = self.Cfg.DailyLimitCount[i]
        self.FailGroupLimitDic[self.Cfg.MatchId[i]] = self.Cfg.FailGroupDailyLimitCount[i]
    end 
end

function XMoeWarVoteItem:GetVoteItemId()
    return self.Cfg.ItemId
end

function XMoeWarVoteItem:GetVoteFactor()
    return self.Cfg.VoteFactor
end

function XMoeWarVoteItem:GetMultiple()
    return self.Cfg.Multiple
end

function XMoeWarVoteItem:GetCoinFactor()
    return self.Cfg.CoinFactor
end

function XMoeWarVoteItem:IsLimitVote()
    return self.Cfg.IsLimit == 1
end

function XMoeWarVoteItem:GetDailyLimitCountByMatchId(matchId)
    return self.DailyLimitDic[matchId] or 0
end

function XMoeWarVoteItem:GetDailyLimitFailGroupCountByMatchId(matchId)
    return self.FailGroupLimitDic[matchId] or 0
end

function XMoeWarVoteItem:GetGainItemId()
    return self.Cfg.GainItemId
end

function XMoeWarVoteItem:GetGainCount()
    return self.Cfg.GainItemCount
end

function XMoeWarVoteItem:GetLimitText()
    
end

return XMoeWarVoteItem