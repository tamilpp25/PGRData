local XSpringFestivalBoxGift = XClass(nil, "XSpringFestivalBoxGift")

local Default = {
    SenderId = 0,
    WordId = 0,
    FromType = 0,
    IsRecv = false,
    Time = 0,
    Name = "",
    Level = 0,
    HeadPortraitId = 0,
    HeadFrameId = 0,
}

function XSpringFestivalBoxGift:Ctor(data)
    local temp = data or Default

    for k, v in pairs(temp) do
        self[k] = v
    end

    self.DefaultFriendInfo = XFriend.New(0, 0)
end

function XSpringFestivalBoxGift:Update(data)
    for k, v in pairs(data) do
        self[k] = v
    end
end

function XSpringFestivalBoxGift:GetSenderId()
    return self.SenderId or 0
end

function XSpringFestivalBoxGift:GetWordId()
    return self.WordId or 0
end

function XSpringFestivalBoxGift:GetFromType()
    return self.FromType or XSpringFestivalActivityConfigs.WordsGiftFromType.None
end

function XSpringFestivalBoxGift:SetReceive(isReceive)
    self.IsRecv = isReceive
end

function XSpringFestivalBoxGift:IsReceive()
    return self.IsRecv or false
end

function XSpringFestivalBoxGift:GetTime()
    return self.Time
end

function XSpringFestivalBoxGift:GetFormatTime()
    return XUiHelper.GetTime(self.Time, XUiHelper.TimeFormatType.MAIN)
end

function XSpringFestivalBoxGift:GetFriendInfo()
    return XDataCenter.SocialManager.GetFriendInfo(self.SenderId) or self.DefaultFriendInfo
end

function XSpringFestivalBoxGift:GetFriendInfoFromGuild()
    local memberList = XDataCenter.GuildManager.GetMemberList()
    return memberList[self:GetSenderId()]
end

function XSpringFestivalBoxGift:GetSenderName()
    return self.Name
end

function XSpringFestivalBoxGift:IsFriendOnline()
    return true
end

function XSpringFestivalBoxGift:GetFriendLastLoginTime()
    return 0
end

function XSpringFestivalBoxGift:GetFriendLevel()
    return self.Level
end

function XSpringFestivalBoxGift:GetFriendIcon()
    return self.HeadPortraitId
end

function XSpringFestivalBoxGift:GetFriendHeadFrameId()
    return self.HeadFrameId
end

function XSpringFestivalBoxGift:GetFriendRemark()
    return ""
end

return XSpringFestivalBoxGift