local XMoeWarVoteItem = XClass(nil, "XMoeWarVoteItem")

function XMoeWarVoteItem:Ctor(id)
    self.Cfg = XMoeWarConfig.GetVoteItemById(id)
    self:InitDailyLimitData()
end

function XMoeWarVoteItem:InitDailyLimitData()
    self.DailyLimitDic = {}
    for i = 1, #self.Cfg.MatchId do
        self.DailyLimitDic[self.Cfg.MatchId[i]] = self.Cfg.DailyLimitCount[i]
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

function XMoeWarVoteItem:GetLimitText()
    
end

return XMoeWarVoteItem