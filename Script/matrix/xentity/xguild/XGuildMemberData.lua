--从服务器接收的格式
XGuildMemberData = XClass(nil, "XGuildMemberData")

local Default = {
    -- 公会成员基本信息
    Id = nil,
    Name = "",
    HeadPortraitId = 0,
    HeadFrameId = 0,
    Level = 1,
    RankLevel = 0,
    ContributeIn7Days = 0,
    ContributeAct = 0,
    ContributeHistory = 0,
    Popularity = 0,
    LastLoginTime = 0,
    OnlineFlag = 0,
}

local STATE_ONLINE = 1

function XGuildMemberData:Ctor(guildMemberData)
    for key in pairs(Default) do
        self[key] = Default[key]
    end
    self:UpdateMemberData(guildMemberData)
end

function XGuildMemberData:UpdateMemberData(guildMemberData)
    if guildMemberData == nil then
        return
    end
    self.Id = guildMemberData.Id
    self.Name = guildMemberData.Name
    self.HeadPortraitId = guildMemberData.HeadPortraitId
    self.HeadFrameId = guildMemberData.HeadFrameId
    self.Level = guildMemberData.Level
    self.RankLevel = guildMemberData.RankLevel
    self.ContributeIn7Days = guildMemberData.ContributeIn7Days
    self.ContributeAct = guildMemberData.ContributeAct
    self.ContributeHistory = guildMemberData.ContributeHistory
    self.Popularity = guildMemberData.Popularity
    self.LastLoginTime = guildMemberData.LastLoginTime
    self.OnlineFlag = guildMemberData.OnlineFlag
end

function XGuildMemberData:UpdateRankLevel(rankLevel)
    self.RankLevel = rankLevel
end

function XGuildMemberData:IsOnline()
    return self.OnlineFlag == STATE_ONLINE
end

function XGuildMemberData:GetName()
    return self.Name
end


