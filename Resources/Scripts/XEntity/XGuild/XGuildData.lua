--从服务器接收的格式
XGuildData = XClass(nil, "XGuildData")

local Json = require("XCommon/Json")

local Default = {
    -- 公会基本信息
    GuildId = 0,
    GuildName = "",
    GuildIconId = 0,
    GuildLevel = 0,
    GuildMemberCount = 0,
    GuildMemberMaxCount = 0,
    GuildTouristCount = 0,
    GuildTouristMaxCount = 0,
    GuildContributeLeft = 0,
    GuildContributeIn7Days = 0,
    GuildRank = {},
    GuildLeaderName = "",
    GuildDeclaration = "",
    GuildInterCom = "",
    RankNames = "",

    GiftContribute = 0,
    GiftGuildLevel = 0,
    GiftLevel = 0,
    GiftLevelGot = {},
    GiftGuildGot = 0,

    Build = 0,
    Option = XGuildConfig.ApplySetting.NeedApply,
    MinLevel = 1,
    MaintainState = 0,
    EmergenceTime = 0,
    TalentPointFromBuild = 0,
    TalentSumLevel = 0,
    AllTalentLevelMax = false,
    GuildLastLevel = -1,
}

function XGuildData:Ctor(guildData)
    for key in pairs(Default) do
        self[key] = Default[key]
    end

    self.MemberData = {}
    self.DecodeRankNames = {}
    self.GuildRankLevel = 0
    self.IsInitData = false
    self:UpdateGuildData(guildData)
end

function XGuildData:IsInit()
    return self.IsInitData
end

function XGuildData:UpdateGuildData(guildData)
    if guildData == nil then
        return
    end
    self.IsInitData = true

    self.GuildId = guildData.GuildId
    self.GuildName = guildData.GuildName
    self.GuildIconId = guildData.GuildIconId
    self.GuildLevel = guildData.GuildLevel
    self.GuildMemberCount = guildData.GuildMemberCount
    self.GuildMemberMaxCount = guildData.GuildMemberMaxCount
    self.GuildTouristCount = guildData.GuildTouristCount
    self.GuildTouristMaxCount = guildData.GuildTouristMaxCount
    self.GuildContributeLeft = guildData.GuildContributeLeft
    self.GuildContributeIn7Days = guildData.GuildContributeIn7Days
    self.GuildLeaderName = guildData.GuildLeaderName
    self.GuildDeclaration = guildData.GuildDeclaration
    self.GuildInterCom = guildData.Notice
    self:UpdateAllRankNames(guildData.RankNames)

    self.GiftContribute = guildData.GiftContribute
    self.GiftGuildLevel = guildData.GiftGuildLevel
    self.GiftLevel = guildData.GiftLevel
    self.GiftLevelGot = {}
    for _, level in pairs(guildData.GiftLevelGot or {}) do
        self.GiftLevelGot[level] = true
    end
    self.GiftGuildGot = guildData.GiftGuildGot

    self.Build = guildData.Build
    self.MaintainState = guildData.MaintainState
    self.EmergenceTime = guildData.EmergenceTime
    if guildData.Option ~= 0 then
        self.Option = guildData.Option
    else
        self.Option = XGuildConfig.ApplySetting.NeedApply
    end
    self.MinLevel = guildData.MinLevel
    self.TalentPointFromBuild = guildData.TalentPointFromBuild
    self.TalentSumLevel = guildData.TalentSumLevel
end

function XGuildData:UpdateAllRankNames(rankNames)
    self.RankNames = rankNames
    -- 清空职位名
    if not self.RankNames then
        self.DecodeRankNames = {}
        return
    end
    if self.RankNames ~= "" then
        local decode_custom = Json.decode(self.RankNames)
        for _, rankInfo in pairs(decode_custom or {}) do
            self.DecodeRankNames[rankInfo.Id] = rankInfo.Name
        end
    end
end

function XGuildData:UpdateGuildMembers(guildMemberData, memberCount)
    local memberInfos = {}
    for _, memberInfo in pairs(guildMemberData or {}) do
        local oldMemberInfo = self.MemberData[memberInfo.Id]
        if oldMemberInfo then
            oldMemberInfo:UpdateMemberData(memberInfo)
            memberInfos[memberInfo.Id] = oldMemberInfo
        else
            memberInfos[memberInfo.Id] = XGuildMemberData.New(memberInfo)
        end
    end
    self.MemberData = memberInfos
    self.GuildMemberCount = memberCount or self.GuildMemberCount
end

function XGuildData:GetGuildMembers()
    return self.MemberData
end

function XGuildData:ClearGuildMembers()
    self.MemberData = {}
end

function XGuildData:RemoveMember(playerId)
    if not playerId then return end
    self.MemberData[playerId] = nil
    self.GuildMemberCount = self.GuildMemberCount - 1
end

-- 是否已经加入公会
function XGuildData:IsJoinGuild()
    return self.GuildId ~= nil and self.GuildId ~= 0
end

-- 获取职位名字、读不到自定义的则去表读取
function XGuildData:GetRankNameByLevel(level)
    if level <= 0 then
        return ""
    end
    local rankTemplate = XGuildConfig.GetGuildPositionById(level)
    local decodeRankName = self.DecodeRankNames[level]
    if decodeRankName == nil or decodeRankName == "" then
        if not rankTemplate then return "" end
        return rankTemplate.Name
    end
    return decodeRankName or ""
end

-- 是否为管理员
function XGuildData:IsGuildAdministor()
    if not self.GuildRankLevel or self.GuildRankLevel == 0 then
        return false
    end

    return self.GuildRankLevel < XGuildConfig.GuildRankLevel.Elder
end

-- 是否为会长
function XGuildData:IsLeader()
    if not self.GuildRankLevel or self.GuildRankLevel == 0 then
        return false
    end
    return self.GuildRankLevel == XGuildConfig.GuildRankLevel.Leader
end

