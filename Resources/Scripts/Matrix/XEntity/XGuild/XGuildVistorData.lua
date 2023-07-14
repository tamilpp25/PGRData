XGuildVistorData = XClass(nil, "XGuildVistorData")
local Json = require("XCommon/Json")

function XGuildVistorData:Ctor()
    self.MembersDatas = {}
end

function XGuildVistorData:UpdateGuildData(guildData)
    self.GuildId = guildData.GuildId
    self.GuildName = guildData.GuildName
    self.GuildIconId = guildData.GuildIconId
    self.GuildLevel = guildData.GuildLevel
    self.GuildMemberCount = guildData.GuildMemberCount
    self.GuildMemberMaxCount = guildData.GuildMemberMaxCount
    self.GuildContributeIn7Days = guildData.GuildContributeIn7Days
    self.GuildLeaderName = guildData.GuildLeaderName
    self.GuildDeclaration = guildData.GuildDeclaration
    self.GuildTouristCount = guildData.GuildTouristCount
    self.GuildTouristMaxCount = guildData.GuildTouristMaxCount
    self.MaintainState = guildData.MaintainState
    self.EmergenceTime = guildData.EmergenceTime
    self.GiftGuildLevel = guildData.GiftGuildLevel
    self.Option = guildData.Option
    self.GiftGuildGot = guildData.GiftGuildGot
    self.Build = guildData.Build
    self.GiftContribute = guildData.GiftContribute
    self.DataRefreshTime = XTime.GetServerNowTimestamp()
    local decodeRankNames = {}
    if guildData.RankNames ~= "" then
        local decode_custom = Json.decode(guildData.RankNames)
        for _, rankInfo in pairs(decode_custom or {}) do
            decodeRankNames[rankInfo.Id] = rankInfo.Name
        end
    end
    self.DecodeRankNames = decodeRankNames
    local membersDatas = {}
    for _, memberData in pairs(guildData.MembersData or {}) do
        table.insert(membersDatas, memberData)
    end
    self.MembersDatas = membersDatas
end

function XGuildVistorData:UpdateGuildMembers(guildMemberData)
    local memberInfos = {}
    for _, memberInfo in pairs(guildMemberData or {}) do
        local oldMemberInfo = self.MembersDatas[memberInfo.Id]
        if oldMemberInfo then
            oldMemberInfo:UpdateMemberData(memberInfo)
            memberInfos[memberInfo.Id] = oldMemberInfo
        else
            memberInfos[memberInfo.Id] = XGuildMemberData.New(memberInfo)
        end
    end
    self.MembersDatas = memberInfos
end

function XGuildVistorData:GetGuildMembers()
    return self.MembersDatas
end

function XGuildVistorData:ClearGuildMembers()
    self.MembersDatas = {}
end

function XGuildVistorData:IsHaveVistorGuildDetailsById()
    if XTime.GetServerNowTimestamp() - self.DataRefreshTime > XGuildConfig.GuildRequestVistorTime then
        return false
    end

    return true
end